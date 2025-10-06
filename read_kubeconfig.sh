#!/bin/bash
read -r JSON

HOST=$(jq -r '.host' <<< "$JSON")
USERNAME=$(jq -r '.username' <<< "$JSON")
PORT=$(jq -r '.port' <<< "$JSON")
KEYPATH=$(jq -r '.keypath' <<< "$JSON")
CLUSTER_SAN=$(jq -r '.cluster_san' <<< "$JSON")

chmod 600 $KEYPATH
KUBECONFIG=$(ssh -i $KEYPATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $PORT $USERNAME@$HOST "k3s kubectl config view --raw -ojson | sed 's/127.0.0.1/$CLUSTER_SAN/'")
CLIENT_CERTIFICATE=$(echo "$KUBECONFIG" | grep client-certificate-data | awk -F":" '{print $2}' | jq -r | base64 --decode)
CLIENT_KEY=$(echo "$KUBECONFIG" | grep client-key-data | awk -F":" '{print $2}' | jq -r | base64 --decode)
CLUSTER_CA_CERTIFICATE=$(echo "$KUBECONFIG" | grep certificate-authority-data | awk -F":" '{print $2}' | jq -r | base64 --decode)

jq -n \
  --arg kubeconfig "$KUBECONFIG" \
  --arg client_certificate "$CLIENT_CERTIFICATE" \
  --arg client_key "$CLIENT_KEY" \
  --arg cluster_ca_certificate "$CLUSTER_CA_CERTIFICATE" \
  '{
    "kubeconfig": $kubeconfig,
    "client_certificate": $client_certificate,
    "client_key": $client_key,
    "cluster_ca_certificate": $cluster_ca_certificate
  }'
