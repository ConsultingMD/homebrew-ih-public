#!/bin/bash

# This script adds environment variables needed for
# our DLP certificates to be respected

# Tell OpenSSL to use our cert bundle.
export SSL_CERT_FILE="$HOME/.ih/certs/mozilla.pem"

# Tell node and npm to use our cert bundle.
export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"

# Tell Python requests library to use our cert bundle.
export REQUESTS_CA_BUNDLE="$SSL_CERT_FILE"

# Tell cURL to use our cert bundle.
export CURL_CA_BUNDLE="$SSL_CERT_FILE"
