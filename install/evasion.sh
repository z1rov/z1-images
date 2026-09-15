#!/usr/bin/env bash
# Author: z1rov
# Evasion, obfuscation and payload-generation tools

source /z1/install/func.sh
mkdir -p /opt/tools

# ---------------------------------------------------------------------------
# donut — position-independent shellcode generator (Kali .deb package)
# ---------------------------------------------------------------------------
function _donut() {
    local dest="${Z1_FORJA}/donut"
    mkdir -p "${dest}"

    local deb_url="http://xsrv.moratelindo.io/kali/pool/main/d/donut-shellcode/donut_1.1-0kali3+b1_amd64.deb"
    local deb_tmp="/tmp/donut_pkg.deb"
    local extract_dir="/tmp/donut_extract"

    # Download the .deb and extract the binary directly with dpkg-deb -x.
    # This avoids any dependency resolution / dpkg -i failures since donut
    # is a plain C binary that runs fine on Debian without extra libs.
    if wget -q --timeout=60 -O "${deb_tmp}" "${deb_url}" 2>/dev/null; then
        rm -rf "${extract_dir}"
        mkdir -p "${extract_dir}"
        if dpkg-deb -x "${deb_tmp}" "${extract_dir}" 2>/dev/null; then
            rm -f "${deb_tmp}"
            local bin_file
            bin_file=$(find "${extract_dir}" -type f -name "donut" 2>/dev/null | head -1)
            if [[ -n "${bin_file}" && -f "${bin_file}" ]]; then
                cp "${bin_file}" "${dest}/donut"
                chmod +x "${dest}/donut"
                ln -sf "${dest}/donut" "${Z1_BIN}/donut"
                rm -rf "${extract_dir}"
                if "${Z1_BIN}/donut" --help >/dev/null 2>&1 || "${Z1_BIN}/donut" -h >/dev/null 2>&1; then
                    _ok "deb: donut → ${Z1_BIN}/donut (kali pkg, extracted)"
                else
                    _err "donut: binary extracted but self-test failed (wrong arch?)"
                fi
                return
            fi
            _err "donut: binary not found inside .deb (unexpected package layout)"
        else
            _err "donut: dpkg-deb -x failed"
        fi
        rm -f "${deb_tmp}"
        rm -rf "${extract_dir}"
    else
        rm -f "${deb_tmp}"
        _err "wget: donut .deb unreachable (${deb_url}), falling back to source build"
    fi

    # Fallback: build from source (CMake)
    _apt cmake
    _apt build-essential
    local src="${Z1_SRC}/donut-src"
    if [[ ! -d "${src}" ]]; then
        git clone -q --depth 1 https://github.com/TheWover/donut "${src}" >/dev/null 2>&1 \
            || { _err "git: donut"; return 1; }
    fi
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
        _err "donut: binary not found after cmake build"
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
