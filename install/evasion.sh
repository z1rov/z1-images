#!/usr/bin/env bash
# Author: z1rov
# Evasion, obfuscation and payload-generation tools

source /z1/install/func.sh
mkdir -p /opt/tools

# ---------------------------------------------------------------------------
# donut — position-independent shellcode generator (TheWover/donut, C)
# ---------------------------------------------------------------------------
function _donut() {
    local dest="${Z1_FORJA}/donut"
    mkdir -p "${dest}"

    # Try pre-built Linux binary from GitHub releases first
    local url
    url=$(_gh_find_asset "TheWover/donut" \
        "('linux' in n.lower()) and not n.endswith('.md') and not n.endswith('.txt') and not n.endswith('.c')")

    if [[ -n "${url}" ]]; then
        local fname; fname=$(basename "${url}")
        local tmp; tmp=$(mktemp -d)
        curl -sfL -o "${tmp}/${fname}" "${url}"

        local bin_file=""
        if [[ "${fname}" == *.zip ]]; then
            unzip -oq "${tmp}/${fname}" -d "${tmp}/out" 2>/dev/null
            bin_file=$(find "${tmp}/out" -type f -name "donut*" ! -name "*.c" ! -name "*.h" 2>/dev/null | head -1)
        elif [[ "${fname}" == *.tar.gz ]]; then
            mkdir -p "${tmp}/out"
            tar -xzf "${tmp}/${fname}" -C "${tmp}/out" 2>/dev/null
            bin_file=$(find "${tmp}/out" -type f -name "donut*" 2>/dev/null | head -1)
        else
            bin_file="${tmp}/${fname}"
        fi

        if [[ -n "${bin_file}" && -f "${bin_file}" ]]; then
            chmod +x "${bin_file}"
            cp "${bin_file}" "${dest}/donut"
            ln -sf "${dest}/donut" "${Z1_BIN}/donut"
            rm -rf "${tmp}"
            _ok "bin: donut → ${Z1_BIN}/donut (pre-built)"
            return
        fi
        rm -rf "${tmp}"
    fi

    # Build from source (CMake)
    _apt cmake
    _apt build-essential
    local src="${Z1_SRC}/donut-src"
    git clone -q --depth 1 https://github.com/TheWover/donut "${src}" >/dev/null 2>&1 \
        || { _err "git: donut"; return 1; }
    (
        cd "${src}"
        cmake . -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 \
            && make -j"$(nproc)" >/dev/null 2>&1
    ) || { _err "make: donut (build failed)"; return 1; }

    local built; built=$(find "${src}" -maxdepth 3 -type f -name "donut" ! -name "*.c" ! -name "*.h" 2>/dev/null | head -1)
    if [[ -n "${built}" ]]; then
        cp "${built}" "${dest}/donut"
        chmod +x "${dest}/donut"
        ln -sf "${dest}/donut" "${Z1_BIN}/donut"
        _ok "bin: donut → ${Z1_BIN}/donut (built from source)"
    else
        _err "donut: binary not found after build"
    fi
}

# ---------------------------------------------------------------------------
# garble — obfuscating Go builder (mvdan.cc/garble)
# ---------------------------------------------------------------------------
function _garble() {
    _go garble mvdan.cc/garble@latest
}

# ---------------------------------------------------------------------------
# Freeze — EDR/AV bypass loader generator (optiv/Freeze, Go)
# ---------------------------------------------------------------------------
function _freeze() {
    _apt gcc-mingw-w64-x86-64
    _apt osslsigncode 2>/dev/null || true

    local src="${Z1_SRC}/Freeze"
    git clone -q --depth 1 https://github.com/optiv/Freeze "${src}" >/dev/null 2>&1 \
        && _ok "git: Freeze → ${src}" || { _err "git: Freeze"; return 1; }

    (cd "${src}" && go build -trimpath -o "${Z1_BIN}/Freeze" . >/dev/null 2>&1) \
        && _ok "go: Freeze → ${Z1_BIN}/Freeze" \
        || _err "go: Freeze (build failed — check mingw/osslsigncode)"
}

# ---------------------------------------------------------------------------
# ScareCrow — shellcode loader with EDR unhooking (optiv/ScareCrow, Go)
# ---------------------------------------------------------------------------
function _scarecrow() {
    _apt gcc-mingw-w64-x86-64
    _apt osslsigncode 2>/dev/null || true

    local src="${Z1_SRC}/ScareCrow"
    git clone -q --depth 1 https://github.com/optiv/ScareCrow "${src}" >/dev/null 2>&1 \
        && _ok "git: ScareCrow → ${src}" || { _err "git: ScareCrow"; return 1; }

    (cd "${src}" && go build -trimpath -o "${Z1_BIN}/ScareCrow" . >/dev/null 2>&1) \
        && _ok "go: ScareCrow → ${Z1_BIN}/ScareCrow" \
        || _err "go: ScareCrow (build failed)"
}

# ---------------------------------------------------------------------------
# msfvenom helper alias — already part of msf, just ensure wrapper exists
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# nim — compiler needed for NimExec / nimbo-C2 style loaders
# ---------------------------------------------------------------------------
function _nim() {
    _apt nim 2>/dev/null || {
        curl -sL https://nim-lang.org/choosenim/init.sh -o /tmp/choosenim.sh
        CHOOSENIM_CHOOSE_VERSION=stable bash /tmp/choosenim.sh -y >/dev/null 2>&1 && _ok "nim: choosenim" || _err "nim: install"
        rm -f /tmp/choosenim.sh
        export PATH="${HOME}/.nimble/bin:${PATH}"
    }
}

function _evasion() {
    _donut
    _garble
    _freeze
    _scarecrow
}
