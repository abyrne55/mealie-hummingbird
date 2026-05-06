#!/usr/bin/python3
"""Mealie container healthcheck — replaces curl-based healthcheck.sh."""

import os
import ssl
import sys
import urllib.request

port = os.environ.get("API_PORT", "9000")

if os.environ.get("TLS_CERTIFICATE_PATH") and os.environ.get("TLS_PRIVATE_KEY_PATH"):
    proto = "https"
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
else:
    proto = "http"
    ctx = None

url = f"{proto}://127.0.0.1:{port}/api/app/about"

try:
    urllib.request.urlopen(url, timeout=5, context=ctx)
except Exception:
    sys.exit(1)
