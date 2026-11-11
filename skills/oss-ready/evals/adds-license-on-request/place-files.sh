#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
bash repo-setup.sh && rm repo-setup.sh
