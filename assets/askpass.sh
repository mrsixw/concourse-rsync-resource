#!/bin/sh
if [ -z "$SSH_PRIVATE_KEY_PASS" ]; then
    echo "Private key has a passphrase but private_key_passphrase has not been set." >&2
    exit 1
fi
echo "$SSH_PRIVATE_KEY_PASS"
