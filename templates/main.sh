#!/usr/bin/env bash
set -u -o pipefail

main() {
    printf 'Hello from __NAME__.\n'
}

main "${@}" || exit 1
