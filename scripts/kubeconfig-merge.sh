#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 kubeconfig1 [kubeconfig2 ...]"
  exit 1
fi

TMP=$(mktemp)
KUBECONFIG=$(IFS=":"; echo "$*")
export KUBECONFIG
kubectl config view --flatten > "$TMP"
mv "$TMP" merged.kubeconfig
echo "Merged kubeconfigs into merged.kubeconfig"
