#!/usr/bin/python3
"""Mealie container entrypoint — loads Docker secrets and starts the app."""

import os
import sys

SECRET_SUPPORTED_VARS = [
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "POSTGRES_SERVER",
    "POSTGRES_PORT",
    "POSTGRES_DB",
    "POSTGRES_URL_OVERRIDE",
    "SMTP_HOST",
    "SMTP_PORT",
    "SMTP_USER",
    "SMTP_PASSWORD",
    "LDAP_SERVER_URL",
    "LDAP_QUERY_PASSWORD",
    "OIDC_CONFIGURATION_URL",
    "OIDC_CLIENT_ID",
    "OIDC_CLIENT_SECRET",
    "OPENAI_BASE_URL",
    "OPENAI_API_KEY",
]


def load_secrets():
    for var in SECRET_SUPPORTED_VARS:
        file_var = f"{var}_FILE"
        file_path = os.environ.get(file_var)
        if file_path:
            try:
                with open(file_path) as f:
                    os.environ[var] = f.read().strip()
            except OSError as e:
                print(f"Warning: could not read {file_var}={file_path}: {e}", file=sys.stderr)


if __name__ == "__main__":
    load_secrets()
    from mealie.main import main
    main()
