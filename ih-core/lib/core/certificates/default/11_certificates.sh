#!/bin/bash

# This script adds environment variables needed for
# our DLP certificates to be respected

export NODE_EXTRA_CA_CERTS="$HOME/.ih/certs/ga_root_ca.pem"
