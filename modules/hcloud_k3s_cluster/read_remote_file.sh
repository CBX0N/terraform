#!/bin/bash

# Read JSON input from Terraform
read -r JSON

# Parse JSON input
HOST=$(jq -r '.host' <<< "$JSON")
USERNAME=$(jq -r '.username' <<< "$JSON")
FILEPATH=$(jq -r '.filepath' <<< "$JSON")
PORT=$(jq -r '.port' <<< "$JSON")
KEYPATH=$(jq -r '.keypath' <<< "$JSON")

while true; do
    if ssh -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -i "$KEYPATH" \
           -p "$PORT" \
           "$USERNAME@$HOST" "[ -f \"$FILEPATH\" ]" >/dev/null 2>&1; then
        # Grab file content
        FILECONTENT=$(ssh -o StrictHostKeyChecking=no \
                        -o UserKnownHostsFile=/dev/null \
                        -i "$KEYPATH" \
                        -p "$PORT" \
                        "$USERNAME@$HOST" "sudo cat \"$FILEPATH\"")
        break
    else
        sleep 5
    fi
done

# Extract only the values (after ": ")
CERTIFICATE_AUTHORITY_DATA=$(echo "$FILECONTENT" | grep "certificate-authority-data" | awk -F ': ' '{print $2}' | base64 --decode)
CLIENT_CERTIFICATE_DATA=$(echo "$FILECONTENT" | grep "client-certificate-data" | awk -F ': ' '{print $2}' | base64 --decode)
CLIENT_KEY_DATA=$(echo "$FILECONTENT" | grep "client-key-data" | awk -F ': ' '{print $2}' | base64 --decode)
SERVER=$(echo "$FILECONTENT" | grep "server" | awk -F ': ' '{print $2}')

# Output JSON for Terraform
jq -n \
  --arg filecontent "$FILECONTENT" \
  --arg certificate_authority_data "$CERTIFICATE_AUTHORITY_DATA" \
  --arg client_certificate_data "$CLIENT_CERTIFICATE_DATA" \
  --arg client_key_data "$CLIENT_KEY_DATA" \
  --arg server "$SERVER" \
  '{
    filecontent: $filecontent,
    "certificate-authority-data": $certificate_authority_data,
    "client-certificate-data": $client_certificate_data,
    "client-key-data": $client_key_data,
    "server": $server
  }'
