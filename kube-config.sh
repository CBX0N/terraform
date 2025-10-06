#!/bin/bash

cluster=""
domain=""

# Parse the -c option
while getopts "c:" opt; do
  case $opt in
    c) cluster="$OPTARG" ;;
    \?) echo "Usage: $0 -c <dev|prod>" >&2; exit 1 ;;
  esac
done

# Validate input
if [ -z "$cluster" ]; then
  echo "Error: cluster not specified"
  echo "Usage: $0 -c <dev|prod>"
  exit 1
fi

# Map cluster to domain
case "$cluster" in
  dev) domain="cluster.dev.cbxon.co.uk" ;;
  prod) domain="cluster.cbxon.co.uk" ;;
  *) 
    echo "Error: invalid cluster '$cluster'. Choose 'dev' or 'prod'."
    exit 1
    ;;
esac

echo "Fetching kubeconfig from $domain..."

# SSH into the cluster, replace 127.0.0.1 with domain, save to ~/.kube/config
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cbxon@"$domain" "sudo cat /etc/rancher/k3s/k3s.yaml" | \
sed "s/127.0.0.1/$domain/g" > ~/.kube/config

echo "Kubeconfig updated at ~/.kube/config"
