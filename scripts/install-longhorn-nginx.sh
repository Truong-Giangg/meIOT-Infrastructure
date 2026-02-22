#!/usr/bin/env bash
set -euo pipefail

# install-longhorn-nginx.sh
# Installs Longhorn (distributed storage) and Nginx Ingress Controller,
# then creates an Ingress to expose the Longhorn UI
#
# Usage: install-longhorn-nginx.sh [--kubeconfig PATH] [--longhorn-domain DOMAIN] [--nginx-version VERSION]

show_help() {
  cat <<EOF
Usage: $0 [--kubeconfig KUBECONFIG_PATH] [--longhorn-domain DOMAIN] [--nginx-version VERSION]

Installs Longhorn and Nginx Ingress Controller to the Kubernetes cluster.
Creates an Ingress to expose Longhorn UI.

Options:
  --kubeconfig PATH          Path to kubeconfig (default: \$KUBECONFIG or ~/.kube/config)
  --longhorn-domain DOMAIN   Domain for Longhorn UI (default: longhorn.local)
  --nginx-version VERSION    Nginx Ingress Controller chart version (default: 4.8.0)
  -h, --help                 Show this help message

Example:
  $0 --kubeconfig merged-kubeconfig-rke --longhorn-domain longhorn.example.com

EOF
}

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
LONGHORN_DOMAIN="longhorn.meiot.site"
NGINX_VERSION="4.8.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig)
      KUBECONFIG="$2"; shift 2;;
    --longhorn-domain)
      LONGHORN_DOMAIN="$2"; shift 2;;
    --nginx-version)
      NGINX_VERSION="$2"; shift 2;;
    -h|--help)
      show_help; exit 0;;
    *)
      echo "Unknown arg: $1"; show_help; exit 1;;
  esac
done

export KUBECONFIG

if [[ ! -f "$KUBECONFIG" ]]; then
  echo "Error: kubeconfig not found at $KUBECONFIG"
  exit 1
fi

echo "Using kubeconfig: $KUBECONFIG"
kubectl cluster-info

# Add Helm repos
echo "Adding Helm repositories..."
helm repo add longhorn https://charts.longhorn.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create longhorn namespace
echo "Creating longhorn namespace..."
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -

# Install Longhorn
echo "Installing Longhorn..."
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set persistence.defaultClassReplicaCount=2 \
  --set csi.attacherReplicaCount=2 \
  --set csi.provisionerReplicaCount=2 \
  --set csi.resizerReplicaCount=2 \
  --set csi.snapshotterReplicaCount=2 \
  --wait \
  --timeout 10m

# Create ingress-nginx namespace
echo "Creating ingress-nginx namespace..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# Install Nginx Ingress Controller
echo "Installing Nginx Ingress Controller (v${NGINX_VERSION})..."
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.metrics.enabled=true \
  --set controller.podAnnotations."prometheus\.io/scrape"=true \
  --set controller.podAnnotations."prometheus\.io/port"=10254 \
  --version="${NGINX_VERSION}" \
  --wait \
  --timeout 5m

echo "Waiting for Nginx Ingress to be ready..."
kubectl rollout status deployment/nginx-ingress-ingress-nginx-controller \
  -n ingress-nginx --timeout=2m || true

# Create Ingress for Longhorn UI
echo "Creating Ingress for Longhorn UI (domain: ${LONGHORN_DOMAIN})..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
    - host: ${LONGHORN_DOMAIN}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: longhorn-frontend
                port:
                  number: 80
EOF

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Longhorn UI URL: http://${LONGHORN_DOMAIN}"
echo ""
echo "To access the UI, add this to your /etc/hosts:"
echo "  <nginx-ingress-external-ip> ${LONGHORN_DOMAIN}"
echo ""
echo "Get the Nginx LoadBalancer IP:"
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o wide
echo ""
echo "Verify Longhorn pods:"
kubectl get pod -n longhorn-system
echo ""
echo "Verify Nginx Ingress pods:"
kubectl get pod -n ingress-nginx
echo ""
