cat /dev/urandom | base64 | tr -dc '0-9a-zA-Z' | head -c100
