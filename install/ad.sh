#!/usr/bin/env bash
# Author: z1rov

source /z1/install/func.sh
mkdir -p /opt/tools

function _ad_base() {
    _apt krb5-user
    _apt krb5-config
    _apt libkrb5-dev
    _apt ldap-utils
    _apt smbclient
    _apt samba-common-bin
    _apt samba
    _apt nbtscan
    _apt onesixtyone
    _apt samdump2
    _apt freerdp3-x11
    _apt hydra
    _apt hashcat
    _apt ncat
    _apt proxychains4
    _apt ruby
    _apt ruby-dev
    _apt pipx
    _apt libpcap-dev
    _apt libmagic1
    _apt python3-ldap3
    _apt jq
    _apt lsof
    _apt unzip
    _apt python3-venv
    _apt python3-pip
    _apt gcc-mingw-w64-x86-64
}

function _bloodhound_ce() {
    local BHD_DIR="${Z1_SRC}/bhce-src"
    if [[ -d "${BHD_DIR}" ]]; then
        _info "skip: bloodhound-ce.py (already exists)"
    else
        git clone -q --depth 1 --branch bloodhound-ce https://github.com/dirkjanm/BloodHound.py "${BHD_DIR}" >/dev/null 2>&1 || { _err "bloodhound-ce.py: git clone failed"; return 1; }
        python3 -m venv --system-site-packages "${BHD_DIR}/venv" >/dev/null 2>&1
        "${BHD_DIR}/venv/bin/pip3" install -q --no-cache-dir "${BHD_DIR}" >/dev/null 2>&1 || { _err "bloodhound-ce.py: pip install failed"; return 1; }
    fi
    cat > "${Z1_BIN}/bloodhound-ce.py" << WRAPPER
#!/usr/bin/env bash
exec "${BHD_DIR}/venv/bin/bloodhound-ce-python" "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/bloodhound-ce.py"
    _ok "bloodhound-ce.py → ${Z1_BIN}/bloodhound-ce.py"
}

function _evil_winrm() {
    gem install evil-winrm >/dev/null 2>&1 && _ok "gem: evil-winrm" || _err "gem: evil-winrm"
}

function _john() {
    local JOHN_DIR="${Z1_SRC}/john"
    local RUN_DIR="${JOHN_DIR}/run"
    if [[ -d "${JOHN_DIR}" ]]; then
        _info "skip: john (already exists)"
    else
        _apt build-essential
        _apt libssl-dev
        _apt zlib1g-dev
        _apt libbz2-dev
        _apt libpcap-dev
        _apt libgmp-dev
        _apt pkg-config
        _apt git
        git clone -q --depth 1 https://github.com/openwall/john "${JOHN_DIR}" >/dev/null 2>&1 || { _err "git: john"; return 1; }
        ( cd "${JOHN_DIR}/src" || { _err "cd: john/src"; return 1; }
          ./configure --disable-native-tests >/dev/null 2>&1 || { _err "john: configure failed"; exit 1; }
          make -sj"$(nproc)" >/dev/null 2>&1 || { _err "john: build failed"; exit 1; }
        ) || return 1
    fi
    cat > "${Z1_BIN}/john" << WRAPPER
#!/usr/bin/env bash
_owd="\$PWD"
cd "${RUN_DIR}" || exit 1
args=()
for a in "\$@"; do
    case "\$a" in
        -*) args+=("\$a") ;;
        /*) args+=("\$a") ;;
        *)  args+=("\${_owd}/\$a") ;;
    esac
done
./john "\${args[@]}"
WRAPPER
    chmod +x "${Z1_BIN}/john"
    local f base
    for f in "${RUN_DIR}"/*2john* "${RUN_DIR}/unshadow" "${RUN_DIR}/unafs" "${RUN_DIR}/unique"; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ "$f" == *.py ]]; then
            cat > "${Z1_BIN}/${base%.py}" << WRAPPER
#!/usr/bin/env bash
_owd="\$PWD"
cd "${RUN_DIR}" || exit 1
args=()
for a in "\$@"; do
    case "\$a" in
        -*) args+=("\$a") ;;
        /*) args+=("\$a") ;;
        *)  args+=("\${_owd}/\$a") ;;
    esac
done
python3 "$f" "\${args[@]}"
WRAPPER
            chmod +x "${Z1_BIN}/${base%.py}"
        elif [[ -x "$f" ]]; then
            cat > "${Z1_BIN}/$base" << WRAPPER
#!/usr/bin/env bash
_owd="\$PWD"
cd "${RUN_DIR}" || exit 1
args=()
for a in "\$@"; do
    case "\$a" in
        -*) args+=("\$a") ;;
        /*) args+=("\$a") ;;
        *)  args+=("\${_owd}/\$a") ;;
    esac
done
"$f" "\${args[@]}"
WRAPPER
            chmod +x "${Z1_BIN}/$base"
        fi
    done
    if "${Z1_BIN}/john" --help >/dev/null 2>&1; then
        _ok "john: installed jumbo (latest from source) → ${Z1_BIN}/john"
    else
        _err "john: build finished but binary not found in ${Z1_BIN}"
    fi
}

function _impacket()        { _pip impacket; }

function _certipy() {
    local CERTIPY_DIR="${Z1_SRC}/certipy-ad"
    local PY_VER="3.13.2"
    mkdir -p "${CERTIPY_DIR}"
    _set_python_env
    local py_bin
    py_bin="$(pyenv root)/versions/${PY_VER}/bin/python3"
    if [[ ! -x "${py_bin}" ]]; then
        _apt build-essential
        _apt libssl-dev
        _apt zlib1g-dev
        _apt libbz2-dev
        _apt libreadline-dev
        _apt libsqlite3-dev
        _apt libncurses5-dev
        _apt libncursesw5-dev
        _apt libffi-dev
        _apt liblzma-dev
        if ! command -v pyenv >/dev/null 2>&1; then
            curl -o /tmp/pyenv.run https://pyenv.run
            bash /tmp/pyenv.run >/dev/null 2>&1
            rm -f /tmp/pyenv.run
            _set_python_env
        fi
        pyenv install -s "${PY_VER}" >/dev/null 2>&1 \
            && _ok "pyenv: python${PY_VER}" || { _err "pyenv: python${PY_VER}"; return 1; }
    fi
    py_bin="$(pyenv root)/versions/${PY_VER}/bin/python3"
    if [[ ! -x "${py_bin}" ]]; then
        _err "certipy-ad: python ${PY_VER} not available after install attempt"
        return 1
    fi
    "${py_bin}" -m venv "${CERTIPY_DIR}/venv" >/dev/null 2>&1
    "${CERTIPY_DIR}/venv/bin/pip" install -q --no-cache-dir --upgrade pip >/dev/null 2>&1
    "${CERTIPY_DIR}/venv/bin/pip" install -q --no-cache-dir --upgrade certipy-ad >/dev/null 2>&1 \
        && _ok "pip: certipy-ad [venv py${PY_VER}]" || { _err "pip: certipy-ad [venv py${PY_VER}]"; return 1; }
    rm -f "${Z1_BIN}/certipy" "${Z1_BIN}/certipy-ad"
    cat > "${Z1_BIN}/certipy" << WRAPPER
#!/usr/bin/env bash
exec "${CERTIPY_DIR}/venv/bin/certipy" "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/certipy"
    ln -sf "${Z1_BIN}/certipy" "${Z1_BIN}/certipy-ad"
    if "${Z1_BIN}/certipy" -v >/dev/null 2>&1; then
        _ok "certipy → ${Z1_BIN}/certipy"
    else
        _err "certipy: wrapper created but tool failed to run"
    fi
}
function _bloodyad()        { _pip bloodyAD; }
function _ldapdomaindump()  { _pip ldapdomaindump; }
function _ldeep()           { _pip ldeep; }
function _mitm6()           { _pip mitm6; }
function _adidnsdump()      { _pip adidnsdump; }
function _coercer()         { _pip coercer; }
function _donpapi()         { _pip donpapi; }
function _smbmap()          { _pip smbmap; }
function _pypykatz()        { _pip pypykatz; }
function _goldencopy()      { _pip goldencopy; }
function _gpp_decrypt()     { _pip gpp-decrypt; }

function _aclpwn() {
    _info "skip: aclpwn (abandoned, py2-only wheel on PyPI, not installable on python3)"
}

function _sprayhound() {
    _pip sprayhound || _info "note: sprayhound may have broken/frozen deps on current pip/python"
}

function _roadrecon() {
    _pip roadrecon || _info "note: roadrecon may have broken/frozen deps on current pip/python"
}

function _manspider() {
    _git manspider https://github.com/blacklanternsecurity/MANSPIDER
    pip3 install -q --no-cache-dir --break-system-packages "${Z1_SRC}/manspider" >/dev/null 2>&1 && _ok "pip: manspider" || _err "pip: manspider"
}

function _enum4linux_ng() {
    _git enum4linux-ng https://github.com/cddmp/enum4linux-ng
    pip3 install -q --no-cache-dir --break-system-packages "${Z1_SRC}/enum4linux-ng" >/dev/null 2>&1 && _ok "pip: enum4linux-ng" || _err "pip: enum4linux-ng"
    _link enum4linux-ng "${Z1_SRC}/enum4linux-ng/enum4linux-ng.py"
}

function _pcredz() {
    local PCREDZ_DIR="${Z1_SRC}/PCredz"
    _apt libpcap-dev
    if [[ -d "${PCREDZ_DIR}" ]]; then
        _info "skip: PCredz (already exists)"
    else
        git clone -q --depth 1 https://github.com/lgandx/PCredz "${PCREDZ_DIR}" >/dev/null 2>&1 || { _err "git: PCredz"; return 1; }
        python3 -m venv --system-site-packages "${PCREDZ_DIR}/venv" >/dev/null 2>&1
        "${PCREDZ_DIR}/venv/bin/pip3" install -q --no-cache-dir Cython >/dev/null 2>&1 && _ok "pip: Cython [PCredz venv]" || _err "pip: Cython [PCredz venv]"
        "${PCREDZ_DIR}/venv/bin/pip3" install -q --no-cache-dir pcapy-ng >/dev/null 2>&1 && _ok "pip: pcapy-ng [PCredz venv]" || _err "pip: pcapy-ng [PCredz venv]"
    fi
    cat > "${Z1_BIN}/Pcredz" << WRAPPER
#!/usr/bin/env bash
cd "${PCREDZ_DIR}" && exec ./venv/bin/python3 ./Pcredz "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/Pcredz"
    if "${Z1_BIN}/Pcredz" -h >/dev/null 2>&1; then
        _ok "Pcredz → ${Z1_BIN}/Pcredz"
    else
        _err "Pcredz: wrapper created but tool failed to run (check venv deps)"
    fi
}

function _enum4linux() {
    _git enum4linux https://github.com/CiscoCXSecurity/enum4linux
    _link enum4linux "${Z1_SRC}/enum4linux/enum4linux.pl"
}

function _powerview_py() {
    pip3 install -q --no-cache-dir --break-system-packages git+https://github.com/aniqfakhrul/powerview.py >/dev/null 2>&1 && _ok "pip: powerview.py" || _err "pip: powerview.py"
}

function _pywerview() {
    _git pywerview https://github.com/the-useless-one/pywerview
    pip3 install -q --no-cache-dir --break-system-packages "${Z1_SRC}/pywerview" >/dev/null 2>&1 && _ok "git+pip: pywerview" || _err "pip: pywerview"
}

function _responder() {
    local RESP_DIR="${Z1_SRC}/Responder"
    _apt gcc-mingw-w64-x86-64
    if [[ -d "${RESP_DIR}" ]]; then
        _info "skip: Responder (already exists)"
    else
        git clone -q --depth 1 https://github.com/lgandx/Responder "${RESP_DIR}" >/dev/null 2>&1 || { _err "git: Responder"; return 1; }
        python3 -m venv --system-site-packages "${RESP_DIR}/venv" >/dev/null 2>&1
        "${RESP_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${RESP_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: Responder requirements [venv]" || _err "pip: Responder requirements [venv]"
        "${RESP_DIR}/venv/bin/pip3" install -q --no-cache-dir pycryptodomex six >/dev/null 2>&1 && _ok "pip: pycryptodomex six [Responder venv]" || _err "pip: pycryptodomex six [Responder venv]"
        sed -i 's/ Random/ 1122334455667788/g' "${RESP_DIR}/Responder.conf"
        sed -i "s/files\/AccessDenied.html/\/${RESP_DIR//\//\\/}\/files\/AccessDenied.html/g" "${RESP_DIR}/Responder.conf"
        sed -i "s/files\/BindShell.exe/\/${RESP_DIR//\//\\/}\/files\/BindShell.exe/g" "${RESP_DIR}/Responder.conf"
        sed -i "s/certs\/responder.crt/\/${RESP_DIR//\//\\/}\/certs\/responder.crt/g" "${RESP_DIR}/Responder.conf"
        sed -i "s/certs\/responder.key/\/${RESP_DIR//\//\\/}\/certs\/responder.key/g" "${RESP_DIR}/Responder.conf"
        x86_64-w64-mingw32-gcc "${RESP_DIR}/tools/MultiRelay/bin/Runas.c" -o "${RESP_DIR}/tools/MultiRelay/bin/Runas.exe" -municode -lwtsapi32 -luserenv >/dev/null 2>&1 && _ok "mingw: Runas.exe" || _err "mingw: Runas.exe"
        x86_64-w64-mingw32-gcc "${RESP_DIR}/tools/MultiRelay/bin/Syssvc.c" -o "${RESP_DIR}/tools/MultiRelay/bin/Syssvc.exe" -municode >/dev/null 2>&1 && _ok "mingw: Syssvc.exe" || _err "mingw: Syssvc.exe"
        "${RESP_DIR}/certs/gen-self-signed-cert.sh" >/dev/null 2>&1 && _ok "Responder: self-signed cert" || _err "Responder: self-signed cert"
    fi
    cat > "${Z1_BIN}/Responder.py" << WRAPPER
#!/usr/bin/env bash
cd "${RESP_DIR}" && exec ./venv/bin/python3 ./Responder.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/Responder.py"
    _ok "Responder.py → ${Z1_BIN}/Responder.py"
}

function _petitpotam() {
    local PP_DIR="${Z1_SRC}/PetitPotam"
    if [[ -d "${PP_DIR}" ]]; then
        _info "skip: PetitPotam (already exists)"
    else
        git clone -q --depth 1 https://github.com/topotam/PetitPotam "${PP_DIR}" >/dev/null 2>&1 || { _err "git: PetitPotam"; return 1; }
        python3 -m venv --system-site-packages "${PP_DIR}/venv" >/dev/null 2>&1
        "${PP_DIR}/venv/bin/pip3" install -q --no-cache-dir impacket >/dev/null 2>&1 && _ok "pip: impacket [PetitPotam venv]" || _err "pip: impacket [PetitPotam venv]"
    fi
    cat > "${Z1_BIN}/PetitPotam.py" << WRAPPER
#!/usr/bin/env bash
cd "${PP_DIR}" && exec ./venv/bin/python3 ./PetitPotam.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/PetitPotam.py"
    _ok "PetitPotam.py → ${Z1_BIN}/PetitPotam.py"
}

function _dfscoerce() {
    _git DFSCoerce https://github.com/Wh04m1001/DFSCoerce
    _link dfscoerce.py "${Z1_SRC}/DFSCoerce/dfscoerce.py"
}

function _shadowcoerce() {
    _git ShadowCoerce https://github.com/ShutdownRepo/ShadowCoerce
    _link shadowcoerce.py "${Z1_SRC}/ShadowCoerce/shadowcoerce.py"
}

function _zerologon() {
    _git zerologon-scan https://github.com/SecuraBV/CVE-2020-1472
    _link zerologon-scan.py "${Z1_SRC}/zerologon-scan/zerologon_tester.py"
}

function _noPac() {
    local NOPAC_DIR="${Z1_SRC}/noPac"
    if [[ -d "${NOPAC_DIR}" ]]; then
        _info "skip: noPac (already exists)"
    else
        git clone -q --depth 1 https://github.com/Ridter/noPac "${NOPAC_DIR}" >/dev/null 2>&1 || { _err "git: noPac"; return 1; }
        python3 -m venv --system-site-packages "${NOPAC_DIR}/venv" >/dev/null 2>&1
        "${NOPAC_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${NOPAC_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: noPac requirements [venv]" || _err "pip: noPac requirements [venv]"
    fi
    cat > "${Z1_BIN}/noPac.py" << WRAPPER
#!/usr/bin/env bash
cd "${NOPAC_DIR}" && exec ./venv/bin/python3 ./noPac.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/noPac.py"
    cat > "${Z1_BIN}/noPac-scanner.py" << WRAPPER
#!/usr/bin/env bash
cd "${NOPAC_DIR}" && exec ./venv/bin/python3 ./scanner.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/noPac-scanner.py"
    _ok "noPac.py → ${Z1_BIN}/noPac.py"
    _ok "noPac-scanner.py → ${Z1_BIN}/noPac-scanner.py"
}

function _windapsearch() {
    local WDS_DIR="${Z1_SRC}/windapsearch"
    _apt libldap2-dev
    _apt libsasl2-dev
    if [[ -L "${Z1_BIN}/windapsearch.py" ]]; then
        rm -f "${Z1_BIN}/windapsearch.py"
    fi
    if [[ -f "${WDS_DIR}/windapsearch.py" ]] && ! head -1 "${WDS_DIR}/windapsearch.py" | grep -q '^#!/usr/bin/env python'; then
        _info "windapsearch: repo source corrupted by previous run, re-cloning"
        rm -rf "${WDS_DIR}"
    fi
    if [[ -d "${WDS_DIR}" ]]; then
        _info "skip: windapsearch (already exists)"
    else
        git clone -q --depth 1 https://github.com/ropnop/windapsearch "${WDS_DIR}" >/dev/null 2>&1 || { _err "git: windapsearch"; return 1; }
        python3 -m venv --system-site-packages "${WDS_DIR}/venv" >/dev/null 2>&1
        if [[ -f "${WDS_DIR}/requirements.txt" ]]; then
            "${WDS_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${WDS_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: windapsearch requirements.txt [venv]" || _err "pip: windapsearch requirements.txt [venv]"
        else
            "${WDS_DIR}/venv/bin/pip3" install -q --no-cache-dir python-ldap >/dev/null 2>&1 && _ok "pip: python-ldap [venv]" || _err "pip: python-ldap [venv]"
        fi
    fi
    rm -f "${Z1_BIN}/windapsearch.py"
    cat > "${Z1_BIN}/windapsearch.py" << WRAPPER
#!/usr/bin/env bash
cd "${WDS_DIR}" && exec ./venv/bin/python3 ./windapsearch.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/windapsearch.py"
    if "${Z1_BIN}/windapsearch.py" -h >/tmp/windapsearch_check.log 2>&1; then
        _ok "windapsearch.py → ${Z1_BIN}/windapsearch.py"
    else
        _err "windapsearch.py: wrapper created but tool failed to run"
        _info "output:"
        sed 's/^/         /' /tmp/windapsearch_check.log
    fi
    rm -f /tmp/windapsearch_check.log
}

function _targetedkerberoast() {
    _git targetedKerberoast https://github.com/ShutdownRepo/targetedKerberoast
    _link targetedKerberoast.py "${Z1_SRC}/targetedKerberoast/targetedKerberoast.py"
}

function _krbrelayx() {
    local KRB_DIR="${Z1_SRC}/krbrelayx"
    if [[ -d "${KRB_DIR}" ]]; then
        _info "skip: krbrelayx (already exists)"
    else
        git clone -q --depth 1 https://github.com/dirkjanm/krbrelayx "${KRB_DIR}" >/dev/null 2>&1 || { _err "git: krbrelayx"; return 1; }
        python3 -m venv --system-site-packages "${KRB_DIR}/venv" >/dev/null 2>&1
        "${KRB_DIR}/venv/bin/pip3" install -q --no-cache-dir dnspython ldap3 impacket dsinternals >/dev/null 2>&1 && _ok "pip: krbrelayx deps [venv]" || _err "pip: krbrelayx deps [venv]"
    fi
    local script
    for script in krbrelayx dnstool printerbug addspn; do
        cat > "${Z1_BIN}/${script}.py" << WRAPPER
#!/usr/bin/env bash
cd "${KRB_DIR}" && exec ./venv/bin/python3 ./${script}.py "\$@"
WRAPPER
        chmod +x "${Z1_BIN}/${script}.py"
        _ok "${script}.py → ${Z1_BIN}/${script}.py"
    done
}

function _pkinittools() {
    local PKT_DIR="${Z1_SRC}/PKINITtools"
    if [[ -d "${PKT_DIR}" ]]; then
        _info "skip: PKINITtools repo (already exists)"
    else
        git clone -q --depth 1 https://github.com/dirkjanm/PKINITtools "${PKT_DIR}" >/dev/null 2>&1 || { _err "git: PKINITtools"; return 1; }
    fi
    if [[ ! -d "${PKT_DIR}/venv" ]]; then
        python3 -m venv --system-site-packages "${PKT_DIR}/venv" >/dev/null 2>&1
    fi
    "${PKT_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${PKT_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: PKINITtools requirements [venv]" || _err "pip: PKINITtools requirements [venv]"
    "${PKT_DIR}/venv/bin/pip3" install -q --no-cache-dir --force-reinstall --no-deps "git+https://github.com/wbond/oscrypto.git" >/dev/null 2>&1 && _ok "pip: oscrypto (fix libcrypto, from git) [venv]" || _err "pip: oscrypto (fix libcrypto, from git) [venv]"
    rm -f "${Z1_BIN}/gettgtpkinit.py" "${Z1_BIN}/getnthash.py"
    cat > "${Z1_BIN}/gettgtpkinit.py" << WRAPPER
#!/usr/bin/env bash
cd "${PKT_DIR}" && exec ./venv/bin/python3 ./gettgtpkinit.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/gettgtpkinit.py"
    cat > "${Z1_BIN}/getnthash.py" << WRAPPER
#!/usr/bin/env bash
cd "${PKT_DIR}" && exec ./venv/bin/python3 ./getnthash.py "\$@"
WRAPPER
    chmod +x "${Z1_BIN}/getnthash.py"
    _ok "gettgtpkinit.py → ${Z1_BIN}/gettgtpkinit.py"
    _ok "getnthash.py → ${Z1_BIN}/getnthash.py"
    local test_log="/tmp/pkinittools_check.log"
    if "${Z1_BIN}/gettgtpkinit.py" -h >"${test_log}" 2>&1; then
        _ok "self-test: gettgtpkinit.py -h → OK (oscrypto import works)"
    else
        if grep -q "LibraryNotFoundError" "${test_log}"; then
            _err "self-test: gettgtpkinit.py still broken (oscrypto/libcrypto)"
        else
            _err "self-test: gettgtpkinit.py failed for another reason"
        fi
        _info "output:"
        sed 's/^/         /' "${test_log}"
    fi
    rm -f "${test_log}"
}

function _pywhisker() {
    _git pywhisker https://github.com/ShutdownRepo/pywhisker
    pip3 install -q --no-cache-dir --break-system-packages "${Z1_SRC}/pywhisker" >/dev/null 2>&1 && _ok "pip: pywhisker" || _err "pip: pywhisker"
    if [[ -f /usr/local/bin/pywhisker ]]; then
        _link pywhisker /usr/local/bin/pywhisker
    else
        cat > "${Z1_BIN}/pywhisker" << WRAPPER
#!/usr/bin/env bash
exec python3 -m pywhisker.pywhisker "\$@"
WRAPPER
        chmod +x "${Z1_BIN}/pywhisker"
        _ok "bin: pywhisker → ${Z1_BIN}/pywhisker (module wrapper)"
    fi
}

function _gmsadumper() {
    _git gMSADumper https://github.com/micahvandeusen/gMSADumper
    _link gMSADumper.py "${Z1_SRC}/gMSADumper/gMSADumper.py"
}

function _kerbrute()      { _go kerbrute      github.com/ropnop/kerbrute@latest; }
function _gosecretsdump() { _go gosecretsdump github.com/C-Sto/gosecretsdump@latest; }
function _godap()         { _go godap          github.com/Macmod/godap@latest; }

function _ad() {
    _ad_base
    _bloodhound_ce
    _evil_winrm
    _john
    _impacket
    _certipy
    _bloodyad
    _ldapdomaindump
    _ldeep
    _mitm6
    _adidnsdump
    _aclpwn
    _manspider
    _coercer
    _donpapi
    _sprayhound
    _smbmap
    _pypykatz
    _goldencopy
    _enum4linux_ng
    _gpp_decrypt
    _pcredz
    _roadrecon
    _powerview_py
    _pywerview
    _responder
    _petitpotam
    _dfscoerce
    _shadowcoerce
    _zerologon
    _noPac
    _windapsearch
    _targetedkerberoast
    _krbrelayx
    _pkinittools
    _pywhisker
    _gmsadumper
    _enum4linux
    _kerbrute
    _gosecretsdump
    _godap
}
