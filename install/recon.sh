#!/usr/bin/env bash
# Author: z1rov

source /z1/install/func.sh
mkdir -p /opt/tools

_nmap()      { _apt nmap; }
_lftp()      { _apt lftp; }
_ftp()       { _apt ftp; }
_masscan()   { _apt masscan; }
_whois()     { _apt whois; }
_dnsutils()  { _apt dnsutils; }
_netcat()    { _apt ncat; }
_jq()        { _apt jq; }
_dirb()      { _apt dirb; }

_subfinder() { _go subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest; }
_httpx()     { _go httpx github.com/projectdiscovery/httpx/cmd/httpx@latest; }
_nuclei()    { _go nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest; }
_dnsx()      { _go dnsx github.com/projectdiscovery/dnsx/cmd/dnsx@latest; }
_naabu()     { _go naabu github.com/projectdiscovery/naabu/v2/cmd/naabu@latest; }
_katana()    { _go katana github.com/projectdiscovery/katana/cmd/katana@latest; }
_tlsx()      { _go tlsx github.com/projectdiscovery/tlsx/cmd/tlsx@latest; }
_alterx()    { _go alterx github.com/projectdiscovery/alterx/cmd/alterx@latest; }
_ffuf()      { _go ffuf github.com/ffuf/ffuf/v2@latest; }
_gobuster()  { _go gobuster github.com/OJ/gobuster/v3@latest; }
_amass()     { _go amass github.com/owasp-amass/amass/v4/...@master; }

_wafw00f()   { _pip wafw00f; }
_arjun()     { _pip arjun; }

function _feroxbuster() {
    local dest_dir="${Z1_SRC}/feroxbuster"
    mkdir -p "${dest_dir}"
    command -v unzip >/dev/null 2>&1 || _apt unzip

    local url
    url=$(_gh_find_asset "epi052/feroxbuster" "n.endswith('amd64.deb')")
    if [[ -n "${url}" ]]; then
        curl -sL -o "${dest_dir}/feroxbuster.deb" "${url}"
        dpkg -i "${dest_dir}/feroxbuster.deb" >/dev/null 2>&1 || apt-get -f install -y >/dev/null 2>&1
        if command -v feroxbuster >/dev/null 2>&1; then
            ln -sf "$(command -v feroxbuster)" "${Z1_BIN}/feroxbuster"
            _ok "deb: feroxbuster → ${Z1_BIN}/feroxbuster"
            return
        fi
    fi

    url=$(_gh_find_asset "epi052/feroxbuster" "'x86_64-linux' in n and 'musl' in n and n.endswith('.zip')")
    [[ -z "${url}" ]] && url=$(_gh_find_asset "epi052/feroxbuster" "'x86_64-linux' in n and n.endswith('.zip')")

    if [[ -n "${url}" ]]; then
        curl -sL -o "${dest_dir}/feroxbuster.zip" "${url}"
        unzip -qo "${dest_dir}/feroxbuster.zip" -d "${dest_dir}"
        rm -f "${dest_dir}/feroxbuster.zip"
        if [[ -f "${dest_dir}/feroxbuster" ]]; then
            chmod +x "${dest_dir}/feroxbuster"
            if "${dest_dir}/feroxbuster" --version >/dev/null 2>&1; then
                ln -sf "${dest_dir}/feroxbuster" "${Z1_BIN}/feroxbuster"
                _ok "bin: feroxbuster → ${Z1_BIN}/feroxbuster"
                return
            fi
        fi
    fi

    _err "feroxbuster: all methods failed"
}

function _rustscan() {
    local dest_dir="${Z1_SRC}/rustscan"
    mkdir -p "${dest_dir}"

    local url
    url=$(_gh_find_asset "RustScan/RustScan" "n.endswith('amd64.deb') or ('amd64' in n and n.endswith('.deb'))")
    if [[ -n "${url}" ]]; then
        curl -sL -o "${dest_dir}/rustscan.deb" "${url}"
        dpkg -i "${dest_dir}/rustscan.deb" >/dev/null 2>&1 || apt-get -f install -y >/dev/null 2>&1
        if command -v rustscan >/dev/null 2>&1; then
            ln -sf "$(command -v rustscan)" "${Z1_BIN}/rustscan"
            _ok "deb: rustscan → ${Z1_BIN}/rustscan"
            return
        fi
    fi

    url=$(_gh_find_asset "RustScan/RustScan" "('x86_64' in n or 'amd64' in n) and 'linux' in n.lower() and not n.endswith('.deb')")
    if [[ -n "${url}" ]]; then
        local fname
        fname=$(basename "${url}")
        curl -sL -o "${dest_dir}/${fname}" "${url}"
        [[ "${fname}" == *.tar.gz ]] && tar -xzf "${dest_dir}/${fname}" -C "${dest_dir}" 2>/dev/null
        [[ "${fname}" == *.zip ]] && unzip -qo "${dest_dir}/${fname}" -d "${dest_dir}" 2>/dev/null
        local bin_path
        bin_path=$(find "${dest_dir}" -type f -name "rustscan" 2>/dev/null | head -1)
        [[ -z "${bin_path}" ]] && bin_path="${dest_dir}/${fname}"
        if [[ -f "${bin_path}" ]]; then
            chmod +x "${bin_path}"
            if "${bin_path}" --version >/dev/null 2>&1; then
                ln -sf "${bin_path}" "${Z1_BIN}/rustscan"
                _ok "bin: rustscan → ${Z1_BIN}/rustscan"
                return
            fi
        fi
    fi

    url=$(_gh_find_asset "RustScan/RustScan" "'rustscan' in n.lower() and not n.endswith('.deb') and not n.endswith('.sha256')")
    if [[ -n "${url}" ]]; then
        local fname
        fname=$(basename "${url}")
        curl -sL -o "${dest_dir}/${fname}" "${url}"
        [[ "${fname}" == *.tar.gz ]] && tar -xzf "${dest_dir}/${fname}" -C "${dest_dir}" 2>/dev/null
        [[ "${fname}" == *.zip ]] && unzip -qo "${dest_dir}/${fname}" -d "${dest_dir}" 2>/dev/null
        local bin_path
        bin_path=$(find "${dest_dir}" -type f ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.sha256" ! -name "*.deb" 2>/dev/null | head -1)
        if [[ -n "${bin_path}" ]]; then
            chmod +x "${bin_path}"
            if "${bin_path}" --version >/dev/null 2>&1; then
                ln -sf "${bin_path}" "${Z1_BIN}/rustscan"
                _ok "bin: rustscan → ${Z1_BIN}/rustscan"
                return
            fi
        fi
    fi

    _err "rustscan: all methods failed"
}

function _nikto() {
    local dest="${Z1_SRC}/nikto"
    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 "https://github.com/sullo/nikto" "${dest}" || { _err "git: nikto (clone failed)"; return; }
    fi
    command -v perl >/dev/null 2>&1 || _apt perl
    command -v cpanm >/dev/null 2>&1 || _apt cpanminus
    cpanm --notest --quiet JSON XML::Writer 2>/dev/null || true
    if [[ -f "${dest}/program/nikto.pl" ]]; then
        chmod +x "${dest}/program/nikto.pl"
        printf '#!/usr/bin/env bash\nexport LC_ALL=C LANG=C\nexec perl "%s/program/nikto.pl" "$@"\n' "${dest}" > "${Z1_BIN}/nikto"
        chmod +x "${Z1_BIN}/nikto"
        _ok "git: nikto → ${Z1_BIN}/nikto"
    else
        _err "git: nikto (nikto.pl not found)"
    fi
}

function _eyewitness() {
    local dest="${Z1_SRC}/EyeWitness"
    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 "https://github.com/RedSiege/EyeWitness" "${dest}" || { _err "git: EyeWitness (clone failed)"; return; }
    fi
    if [[ -f "${dest}/Python/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages -r "${dest}/Python/requirements.txt" 2>/dev/null || true
    fi
    for pkg in netaddr selenium fuzzywuzzy python-Levenshtein; do
        python3 -c "import ${pkg//-/_}" 2>/dev/null || python3 -m pip install -q --no-cache-dir --break-system-packages "${pkg}" 2>/dev/null || true
    done
    if [[ -f "${dest}/Python/EyeWitness.py" ]]; then
        printf '#!/usr/bin/env bash\nexec python3 "%s/Python/EyeWitness.py" "$@"\n' "${dest}" > "${Z1_BIN}/eyewitness"
        chmod +x "${Z1_BIN}/eyewitness"
        _ok "git: EyeWitness → ${Z1_BIN}/eyewitness"
    else
        _err "git: EyeWitness (EyeWitness.py not found)"
    fi
}

function _searchsploit() {
    local dest="${Z1_SRC}/exploitdb"

    if [[ -d "${dest}" ]]; then
        _info "skip: exploitdb (already exists)"
    else
        git clone -q --depth 1 https://gitlab.com/exploit-database/exploitdb.git "${dest}" >/dev/null 2>&1 \
            && _ok "git: exploitdb → ${dest}" || { _err "git: exploitdb"; return 1; }
    fi

    if [[ -f "${dest}/searchsploit" ]]; then
        chmod +x "${dest}/searchsploit"
        ln -sf "${dest}/searchsploit" "${Z1_BIN}/searchsploit"
        if [[ -f "${dest}/.searchsploit_rc" ]]; then
            cp "${dest}/.searchsploit_rc" "${HOME}/.searchsploit_rc"
        fi
        _ok "git: searchsploit → ${Z1_BIN}/searchsploit"
    else
        _err "git: searchsploit (binary not found after cloning)"
    fi
}

function _recon() {
    _nmap
    _masscan
    _whois
    _dnsutils
    _netcat
    _jq
    _dirb
    _ftp
    _subfinder
    _httpx
    _nuclei
    _dnsx
    _naabu
    _katana
    _tlsx
    _alterx
    _ffuf
    _gobuster
    _amass
    _lftp
    _wafw00f
    _arjun
    _feroxbuster
    _rustscan
    _nikto
    _eyewitness
    _searchsploit
}
