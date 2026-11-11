#!/usr/bin/env bash
# Builds a small git repo whose history contains a (fake, AWS-documentation example) key.
set -eu
git init -q && git config user.email dev@example.com && git config user.name dev
printf 'AWS_KEY = "AKIAIOSFODNN7EXAMPLE"\nAPI = "https://billing.acme.internal/v1"\n' > config.py
printf 'print("hello")\n' > main.py
git add . && git commit -qm "initial"
printf 'import os\nAWS_KEY = os.environ["AWS_KEY"]\nAPI = os.environ["API"]\n' > config.py
printf '# acme billing helper\n' > README.md
git add . && git commit -qm "move config to env"
