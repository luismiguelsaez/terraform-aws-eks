#!/usr/bin/env bash

echo | openssl s_client -connect oidc.eks.${$1}.amazonaws.com:443 2>&1 | openssl x509 -noout -fingerprint | awk -F= '{print $2;}' | sed 's/://g'