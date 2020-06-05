#!/usr/bin/env bash

CURRENT_REGION=$1

THUMBPRINT=$(echo | openssl s_client -connect oidc.eks.${CURRENT_REGION}.amazonaws.com:443 2>&1 | openssl x509 -noout -fingerprint | awk -F= '{print $2;}' | sed 's/://g')

THUMBPRINT_JSON="{\"thumbprint\": \"${THUMBPRINT}\"}"

echo ${THUMBPRINT_JSON}