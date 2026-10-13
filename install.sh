#!/usr/bin/env bash
set -u -o pipefail

REPOSITORY='https://github.com/ilvar/strictbash'

error() {
    printf 'strictbash installer: %s\n' "${1}" >&2 || return 1
}

target_for_host() {
    case "${1}:${2}" in
        Linux:x86_64|Linux:amd64) printf 'x86_64-unknown-linux-musl' ;;
        Linux:aarch64|Linux:arm64) printf 'aarch64-unknown-linux-musl' ;;
        *) printf '' ;;
    esac
}

install_release() {
    local workdir install_dir os arch target latest_url tag binary asset base_url
    workdir="${1}"
    if [[ -z "${STRICTBASH_INSTALL_DIR:-}" && -z "${HOME:-}" ]]; then
        error 'set HOME or STRICTBASH_INSTALL_DIR to choose a destination' || return 1
        return 1
    fi
    install_dir="${STRICTBASH_INSTALL_DIR:-${HOME}/.local/bin}"
    os=$(uname -s) || return 1
    arch=$(uname -m) || return 1
    target=$(target_for_host "${os}" "${arch}") || return 1
    latest_url=$(curl --fail --silent --show-error --location --retry 3 --connect-timeout 10 --max-time 60 \
        --proto '=https' --proto-redir '=https' --output /dev/null --write-out '%{url_effective}' \
        "${REPOSITORY}/releases/latest") || return 1
    tag="${latest_url##*/}"
    if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "unexpected latest release URL: ${latest_url}" || return 1
        return 1
    fi

    if [[ -n "${target}" && "${STRICTBASH_BUILD_FROM_SOURCE:-0}" == 0 ]]; then
        asset="strictbash-${target}"
        base_url="${REPOSITORY}/releases/download/${tag}"
        curl --fail --silent --show-error --location --retry 3 --connect-timeout 10 --max-time 120 \
            --proto '=https' --proto-redir '=https' --output "${workdir}/${asset}" \
            "${base_url}/${asset}" || return 1
        curl --fail --silent --show-error --location --retry 3 --connect-timeout 10 --max-time 60 \
            --proto '=https' --proto-redir '=https' --output "${workdir}/${asset}.sha256" \
            "${base_url}/${asset}.sha256" || return 1
        # The checksum's filename is relative to the isolated download directory.
        if (cd "${workdir}" && sha256sum --check --strict "${asset}.sha256" || exit 1); then
            binary="${workdir}/${asset}"
        else
            error 'checksum verification failed; refusing to install' || return 1
            return 1
        fi
    else
        printf 'Building strictbash %s for %s/%s from source.\n' "${tag}" "${os}" "${arch}"
        if rustup --version >/dev/null 2>&1 && cargo --version >/dev/null 2>&1; then
            rustup toolchain install 1.97.1 --profile minimal || return 1
            cargo +1.97.1 install --git "${REPOSITORY}" --tag "${tag}" --locked \
                --root "${workdir}/build" || return 1
            binary="${workdir}/build/bin/strictbash"
        else
            error 'source builds require rustup, cargo and a native C compiler; install Rust from https://rustup.rs first' || return 1
            return 1
        fi
    fi

    mkdir -p -- "${install_dir}" || return 1
    install -m 0755 -- "${binary}" "${install_dir}/strictbash" || return 1
    printf 'Installed strictbash %s to %s/strictbash\n' "${tag}" "${install_dir}"
    printf 'Ensure %s is on PATH.\n' "${install_dir}"
    if shellcheck --version >/dev/null 2>&1; then
        :
    else
        printf 'ShellCheck is required for linting; install it using your system package manager.\n' >&2 || return 1
    fi
}

main() {
    local workdir result
    if [[ "${#}" -ne 0 ]]; then
        error 'usage: bash install.sh (configure STRICTBASH_INSTALL_DIR or STRICTBASH_BUILD_FROM_SOURCE=1 via environment)' || return 1
        return 1
    fi
    workdir=$(mktemp -d "${TMPDIR:-/tmp}/strictbash-install.XXXXXXXX") || return 1
    if install_release "${workdir}"; then
        result=0
    else
        result=1
    fi
    rm -rf -- "${workdir}" || return 1
    return "${result}"
}

main "${@}" || exit 1
