#!/usr/bin/env bash
# Author: z1rov

source /z1/install/func.sh
mkdir -p /anvil /opt/tools

function _web_apt_tools() {
    _apt dirb
    _apt prips
    _apt locales
    _apt swaks
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen >/dev/null 2>&1 || true
    _apt php-cli
    _apt default-jre-headless
    _apt libwww-perl
    _apt python3-pycurl
    _apt cmake
    _apt build-essential
    _apt libatk1.0-0
    _apt libgtk-3-0
    _apt libxcomposite1
    _apt libxdamage1
    _apt libxrandr2
    _apt libgbm1
    _apt libxkbcommon0
    _apt libasound2
    _apt libatspi2.0-0
    _apt libxss1
    export PATH="${PATH}:/root/.local/bin"
    pipx ensurepath >/dev/null 2>&1 || true
}

function _weevely() {
    _apt weevely
}

function _sqlmap() {
    _apt sqlmap
}

function _whatweb() {
    local dest="${Z1_SRC}/whatweb"
    rm -rf "${dest}" 2>/dev/null
    git clone -q --depth 1 https://github.com/urbanadventurer/WhatWeb.git "${dest}" \
        && _ok "git: whatweb → ${dest}" || { _err "git: whatweb"; return 1; }
    source /usr/local/rvm/scripts/rvm
    rvm use "${Z1_RUBY_VERSION}@whatweb" --create >/dev/null 2>&1
    gem install -q addressable json rake >/dev/null 2>&1 \
        && _ok "gem: addressable json rake [gemset:whatweb]" \
        || _err "gem: addressable json rake [gemset:whatweb]"
    rvm use "${Z1_RUBY_VERSION}@default" >/dev/null 2>&1
    chmod +x "${dest}/whatweb"
    cat > "${Z1_BIN}/whatweb" << EOF
#!/usr/bin/env bash
source /usr/local/rvm/scripts/rvm 2>/dev/null
rvm use ${Z1_RUBY_VERSION}@whatweb >/dev/null 2>&1
exec ruby "${dest}/whatweb" "\$@"
EOF
    chmod +x "${Z1_BIN}/whatweb"
    _ok "whatweb: wrapper created at ${Z1_BIN}/whatweb"
    if "${Z1_BIN}/whatweb" --version >/dev/null 2>&1; then
        _ok "whatweb: installed successfully"
    else
        _err "whatweb: verification failed"
        "${Z1_BIN}/whatweb" --version 2>&1 | head -10
    fi
}

function _kiterunner() {
    _git kiterunner https://github.com/assetnote/kiterunner.git
    local dest="${Z1_SRC}/kiterunner"
    if [[ -d "${dest}" ]]; then
        curl -sL https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite.tar.gz \
            -o "${dest}/routes-large.kite.tar.gz"
        curl -sL https://wordlists-cdn.assetnote.io/data/kiterunner/routes-small.kite.tar.gz \
            -o "${dest}/routes-small.kite.tar.gz"
        (cd "${dest}" && make build >/dev/null 2>&1)
        _link kr "${dest}/dist/kr"
    fi
}

function _dirsearch() {
    _git dirsearch https://github.com/maurosoria/dirsearch
    local dest="${Z1_SRC}/dirsearch"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/dirsearch.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/dirsearch.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/dirsearch.py"
        ln -sf "${Z1_BIN}/dirsearch.py" "${Z1_BIN}/dirsearch"
        _ok "git: dirsearch → ${Z1_BIN}/dirsearch"
    fi
}

function _ssrfmap() {
    _git ssrfmap https://github.com/swisskyrepo/SSRFmap
    local dest="${Z1_SRC}/ssrfmap"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/ssrfmap.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/ssrfmap.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/ssrfmap.py"
        ln -sf "${Z1_BIN}/ssrfmap.py" "${Z1_BIN}/ssrfmap"
        _ok "git: ssrfmap → ${Z1_BIN}/ssrfmap"
    fi
}

function _gopherus() {
    _git gopherus https://github.com/tarunkant/Gopherus
    local dest="${Z1_SRC}/gopherus"
    if [[ -d "${dest}" ]]; then
        _pyvenv2 gopherus gopherus.py >/dev/null
        _venv_pip2 "${dest}" argparse requests
        cat > "${Z1_BIN}/gopherus.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python" "${dest}/gopherus.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/gopherus.py"
        ln -sf "${Z1_BIN}/gopherus.py" "${Z1_BIN}/gopherus"
        _ok "git: gopherus → ${Z1_BIN}/gopherus (python2.7)"
    fi
}

function _nosqlmap() {
    _git nosqlmap https://github.com/codingo/NoSQLMap.git
    local dest="${Z1_SRC}/nosqlmap"
    if [[ -d "${dest}" ]]; then
        _pyvenv2 nosqlmap nosqlmap.py >/dev/null
        if [[ -f "${dest}/setup.py" ]]; then
            sed -i 's/requests==2\.32\.4/requests==2.27.1/' "${dest}/setup.py"
        fi
        (cd "${dest}" && "${dest}/venv/bin/python" setup.py install >/dev/null 2>&1) || true
        rm -rf "${dest}"/venv/lib/python2.7/site-packages/certifi-2023.5.7-py2.7.egg 2>/dev/null
        _venv_pip2 "${dest}" "certifi==2018.10.15"
        cat > "${Z1_BIN}/nosqlmap.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python" "${dest}/nosqlmap.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/nosqlmap.py"
        ln -sf "${Z1_BIN}/nosqlmap.py" "${Z1_BIN}/nosqlmap"
        _ok "git: nosqlmap → ${Z1_BIN}/nosqlmap (python2.7)"
    fi
}

function _xsstrike() {
    _git xsstrike https://github.com/s0md3v/XSStrike.git
    local dest="${Z1_SRC}/xsstrike"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" fuzzywuzzy python-Levenshtein
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/xsstrike.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/xsstrike.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/xsstrike.py"
        ln -sf "${Z1_BIN}/xsstrike.py" "${Z1_BIN}/xsstrike"
        _ok "git: xsstrike → ${Z1_BIN}/xsstrike"
    fi
}

function _bolt() {
    _git bolt https://github.com/s0md3v/Bolt.git
    local dest="${Z1_SRC}/bolt"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" fuzzywuzzy python-Levenshtein
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/bolt" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/bolt.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/bolt"
        _ok "git: bolt → ${Z1_BIN}/bolt"
    fi
}

function _kadimus() {
    _apt libcurl4-openssl-dev
    _apt libpcre3-dev
    _apt libssh-dev
    _git kadimus https://github.com/P0cL4bs/Kadimus
    local dest="${Z1_SRC}/kadimus"
    if [[ -d "${dest}" ]]; then
        (cd "${dest}" && make -j >/dev/null 2>&1)
        _link kadimus "${dest}/kadimus"
    fi
}

function _fuxploider() {
    _git fuxploider https://github.com/almandin/fuxploider.git
    local dest="${Z1_SRC}/fuxploider"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" coloredlogs
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/fuxploider" << EOF
#!/usr/bin/env bash
cd "${dest}"
exec ./venv/bin/python3 fuxploider.py "\$@"
EOF
        chmod +x "${Z1_BIN}/fuxploider"
        _ok "git: fuxploider → ${Z1_BIN}/fuxploider"
    fi
}

function _patator() {
    _apt libmariadb-dev
    _apt libcurl4-openssl-dev
    _apt libssl-dev
    _apt ldap-utils
    _apt libpq-dev
    _apt ike-scan
    _git patator https://github.com/lanjelot/patator.git
    local dest="${Z1_SRC}/patator"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        echo 'setuptools<82' > "${dest}/build-constraints.txt"
        [[ -f "${dest}/requirements.txt" ]] && \
            "${dest}/venv/bin/pip" install -q --no-cache-dir \
                --build-constraint "${dest}/build-constraints.txt" \
                -r "${dest}/requirements.txt" 2>/dev/null
        local patator_script="${dest}/patator.py"
        [[ ! -f "${patator_script}" ]] && \
            patator_script="${dest}/src/patator/patator.py"
        cat > "${Z1_BIN}/patator.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${patator_script}" "\$@"
EOF
        chmod +x "${Z1_BIN}/patator.py"
        ln -sf "${Z1_BIN}/patator.py" "${Z1_BIN}/patator"
        _ok "git: patator → ${Z1_BIN}/patator"
    fi
}

function _joomscan() {
    _git joomscan https://github.com/rezasp/joomscan
    local dest="${Z1_SRC}/joomscan"
    if [[ -d "${dest}" ]]; then
        cat > "${Z1_BIN}/joomscan" << EOF
#!/usr/bin/env bash
exec perl "${dest}/joomscan.pl" "\$@"
EOF
        chmod +x "${Z1_BIN}/joomscan"
        _ok "git: joomscan → ${Z1_BIN}/joomscan"
    fi
}

function _wpscan() {
    source /usr/local/rvm/scripts/rvm 2>/dev/null || true
    rvm use "${Z1_RUBY_VERSION}@wpscan" --create >/dev/null 2>&1
    _apt ruby-dev
    _apt libxml2-dev
    _apt libxslt1-dev
    _apt build-essential
    _apt libcurl4-openssl-dev
    _apt libssl-dev
    _apt zlib1g-dev
    gem install -q bundler >/dev/null 2>&1
    gem install -q wpscan >/dev/null 2>&1 \
        && _ok "gem: wpscan [gemset:wpscan]" \
        || {
            _err "gem: wpscan [gemset:wpscan]"
            git clone -q --depth 1 https://github.com/wpscanteam/wpscan.git /tmp/wpscan-src >/dev/null 2>&1
            (
                cd /tmp/wpscan-src
                bundle install >/dev/null 2>&1
                gem build wpscan.gemspec >/dev/null 2>&1
                gem install wpscan-*.gem >/dev/null 2>&1
            )
            rm -rf /tmp/wpscan-src
        }
    rvm use "${Z1_RUBY_VERSION}@default" >/dev/null 2>&1
    cat > "${Z1_BIN}/wpscan" << EOF
#!/usr/bin/env bash
source /usr/local/rvm/scripts/rvm 2>/dev/null
rvm use ${Z1_RUBY_VERSION}@wpscan >/dev/null 2>&1
exec wpscan "\$@"
EOF
    chmod +x "${Z1_BIN}/wpscan"
    if "${Z1_BIN}/wpscan" --help >/dev/null 2>&1; then
        _ok "wpscan: installed successfully → ${Z1_BIN}/wpscan"
    else
        _err "wpscan: verification failed"
    fi
}

function _droopescan() {
    if command -v pipx >/dev/null 2>&1; then
        pipx install --system-site-packages git+https://github.com/droope/droopescan.git >/dev/null 2>&1 \
            && _ok "pipx: droopescan" || _err "pipx: droopescan"
    else
        _err "pipx: not available"
    fi
    pip3 install -q --no-cache-dir --break-system-packages git+https://github.com/droope/droopescan.git >/dev/null 2>&1 \
        && _ok "pip: droopescan" || {
            _err "pip: droopescan"
            return 1
        }
    if command -v droopescan >/dev/null 2>&1; then
        _ok "droopescan: installed successfully"
    else
        local droopescan_bin
        droopescan_bin=$(find /usr/local/bin /root/.local/bin /usr/bin -name "droopescan" 2>/dev/null | head -1)
        if [[ -n "${droopescan_bin}" ]]; then
            ln -sf "${droopescan_bin}" "${Z1_BIN}/droopescan"
            _ok "droopescan: symlink created → ${Z1_BIN}/droopescan"
        else
            _err "droopescan: binary not found"
            return 1
        fi
    fi
    if droopescan --help >/dev/null 2>&1 || "${Z1_BIN}/droopescan" --help >/dev/null 2>&1; then
        _ok "droopescan: verification OK"
    else
        _err "droopescan: verification failed"
        return 1
    fi
}

function _drupwn() {
    local dest="${Z1_SRC}/drupwn"
    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 https://github.com/immunIT/drupwn "${dest}" >/dev/null 2>&1 \
            && _ok "git: drupwn → ${dest}" || { _err "git: drupwn"; return 1; }
    else
        _info "skip: drupwn (already exists)"
    fi
    if [[ -d "${dest}/venv" ]]; then
        rm -rf "${dest}/venv"
    fi
    /usr/bin/python3 -m venv "${dest}/venv" >/dev/null 2>&1 \
        && _ok "venv: drupwn" || { _err "venv: drupwn"; return 1; }
    "${dest}/venv/bin/pip" install -q --no-cache-dir --upgrade pip >/dev/null 2>&1
    "${dest}/venv/bin/pip" install -q --no-cache-dir setuptools wheel >/dev/null 2>&1 \
        && _ok "pip: setuptools/wheel" || _err "pip: setuptools/wheel"
    local site_packages
    site_packages=$("${dest}/venv/bin/python3" -c "import site; print(site.getsitepackages()[0])")
    if [[ ! -d "${site_packages}/pkg_resources" ]]; then
        "${dest}/venv/bin/pip" install -q --no-cache-dir --force-reinstall setuptools >/dev/null 2>&1
        _info "pkg_resources forced reinstall"
    fi
    while IFS= read -r -d '' init_file; do
        cp "${init_file}" "${init_file}.bak"
        cat > "${init_file}" << 'EOF'
# Patched for Python 3.13: implicit namespace package (PEP 420),
# pkg_resources.declare_namespace() not required
EOF
        _ok "patch: ${init_file#${dest}/}"
    done < <(grep -rlZ "declare_namespace" "${dest}" --include="__init__.py" 2>/dev/null)
    local script="${dest}/drupwn"
    if [[ -f "${script}" ]]; then
        sed -i 's|#!/usr/bin/env python|#!/usr/bin/env python3|' "${script}"
        _ok "patch: drupwn shebang"
    fi
    cat > "${dest}/requirements-fixed.txt" << 'EOF'
requests>=2.25.0
beautifulsoup4>=4.9.0
lxml>=4.6.0
colorama>=0.4.0
EOF
    "${dest}/venv/bin/pip" install -q --no-cache-dir -r "${dest}/requirements-fixed.txt" 2>/dev/null \
        && _ok "pip: requirements fixed" || _err "pip: requirements fixed"
    (cd "${dest}" && "${dest}/venv/bin/pip" install -q --no-cache-dir -e . 2>/dev/null) \
        && _ok "pip: drupwn (editable)" || _err "pip: drupwn (editable)"
    cat > "${Z1_BIN}/drupwn" << EOF
#!/usr/bin/env bash
export PYTHONPATH="${site_packages}:\$PYTHONPATH"
exec "${dest}/venv/bin/python3" "${dest}/drupwn" "\$@"
EOF
    chmod +x "${Z1_BIN}/drupwn"
    if "${Z1_BIN}/drupwn" --help >/dev/null 2>&1; then
        _ok "drupwn: installed successfully"
        _info "usage: drupwn --target http://target.com --mode enum"
        _info "       drupwn --target http://target.com --mode exploit"
    else
        _err "drupwn: verification failed"
        "${Z1_BIN}/drupwn" --help 2>&1 | head -10
    fi
}

function _cmsmap() {
    local dest="${Z1_SRC}/cmsmap"
    if [[ -d "${dest}" ]]; then
        rm -rf "${dest}"
    fi
    _run_logged "git: cmsmap" git clone -q --depth 1 https://github.com/Dionach/CMSmap.git "${dest}" \
        || return 1
    local _p _stale
    IFS=':' read -ra _path_dirs <<< "${PATH}"
    for _p in "${_path_dirs[@]}"; do
        _stale="${_p}/cmsmap"
        if [[ -f "${_stale}" || -L "${_stale}" ]]; then
            rm -f "${_stale}"
        fi
    done
    pipx uninstall cmsmap >/dev/null 2>&1
    rm -rf /root/.local/share/pipx/venvs/cmsmap
    /usr/bin/python3 -m venv "${dest}/venv" \
        && _ok "venv: cmsmap" || { _err "venv: cmsmap"; return 1; }
    _run_logged "pip: upgrade pip/setuptools/wheel" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel \
        || return 1
    if [[ -f "${dest}/requirements.txt" ]]; then
        _run_logged "pip: requirements.txt" \
            "${dest}/venv/bin/pip" install --no-cache-dir -r "${dest}/requirements.txt"
    fi
    _run_logged "pip: cmsmap" \
        "${dest}/venv/bin/pip" install --no-cache-dir "${dest}" \
        || return 1
    local venv_py="${dest}/venv/bin/python3"
    if "${venv_py}" -c "from cmsmap.main import main" 2>/dev/null; then
        cat > "${Z1_BIN}/cmsmap" << EOF
#!/usr/bin/env bash
exec "${venv_py}" -c "import sys; from cmsmap.main import main; sys.exit(main())" "\$@"
EOF
        chmod +x "${Z1_BIN}/cmsmap"
        _ok "cmsmap: wrapper created at ${Z1_BIN}/cmsmap"
    else
        _err "cmsmap: module 'cmsmap.main' not importable in venv"
        "${venv_py}" -c "from cmsmap.main import main" 2>&1 | sed 's/^/    /'
        return 1
    fi
    local conf
    conf=$(compgen -G "${dest}/venv/lib/python3*/site-packages/cmsmap/cmsmap.conf" | head -n1)
    if [[ -n "${conf}" && -f "${conf}" ]]; then
        sed -i 's/wordlist =  wordlist\/rockyou.txt/wordlist =  \/usr\/share\/wordlists\/rockyou.txt/' "${conf}"
        sed -i 's/edbpath = \/usr\/share\/exploitdb/edbpath = \/opt\/tools\/exploitdb/' "${conf}"
        sed -i 's/edbtype = apt/edbtype = git/' "${conf}"
        _ok "patch: cmsmap.conf (${conf})"
    else
        _err "cmsmap.conf not found, could not patch"
        find "${dest}" -iname "cmsmap.conf" 2>&1
    fi
    if "${Z1_BIN}/cmsmap" --help >/dev/null 2>&1; then
        _ok "cmsmap: installed successfully"
    else
        _err "cmsmap: verification failed"
        "${Z1_BIN}/cmsmap" --help 2>&1 | head -10
    fi
}

function _moodlescan() {
    _git moodlescan https://github.com/inc0d3/moodlescan.git
    local dest="${Z1_SRC}/moodlescan"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        (cd "${dest}" && ./venv/bin/python3 moodlescan.py -a >/dev/null 2>&1) || true
        cat > "${Z1_BIN}/moodlescan.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/moodlescan.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/moodlescan.py"
        ln -sf "${Z1_BIN}/moodlescan.py" "${Z1_BIN}/moodlescan"
        _ok "git: moodlescan → ${Z1_BIN}/moodlescan"
    fi
}

function _testssl() {
    _apt bsdmainutils
    _git testssl https://github.com/drwetter/testssl.sh.git
    _link testssl.sh "${Z1_SRC}/testssl/testssl.sh"
    ln -sf "${Z1_BIN}/testssl.sh" "${Z1_BIN}/testssl"
    _ok "bin: testssl alias → ${Z1_BIN}/testssl"
}

function _sslscan() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone -q --depth 1 https://github.com/rbsec/sslscan.git "${tmp_dir}" >/dev/null 2>&1 \
        && _ok "git: sslscan (tmp)" || { _err "git: sslscan"; return; }
    (cd "${tmp_dir}" && make static >/dev/null 2>&1)
    if [[ -f "${tmp_dir}/sslscan" ]]; then
        mv "${tmp_dir}/sslscan" "${Z1_BIN}/sslscan"
        chmod +x "${Z1_BIN}/sslscan"
        _ok "bin: sslscan → ${Z1_BIN}/sslscan"
    else
        _err "sslscan: make static failed"
    fi
    rm -rf "${tmp_dir}"
}

function _cloudfail() {
    local dest="${Z1_SRC}/CloudFail"
    if [[ -d "${dest}" ]]; then
        rm -rf "${dest}"
    fi
    _run_logged "git: CloudFail" git clone -q --depth 1 https://github.com/m0rtem/CloudFail "${dest}" \
        || return 1
    /usr/bin/python3 -m venv "${dest}/venv" \
        && _ok "venv: cloudfail" || { _err "venv: cloudfail"; return 1; }
    _run_logged "pip: upgrade pip" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade pip
    _run_logged "pip: requirements.txt" \
        "${dest}/venv/bin/pip" install --no-cache-dir -r "${dest}/requirements.txt" \
        || return 1
    _run_logged "pip: upgrade urllib3/certifi/chardet" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade urllib3 certifi chardet idna
    cat > "${Z1_BIN}/cloudfail" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/cloudfail.py" "\$@"
EOF
    chmod +x "${Z1_BIN}/cloudfail"
    _ok "cloudfail: wrapper created at ${Z1_BIN}/cloudfail"
    if "${Z1_BIN}/cloudfail" --help >/dev/null 2>&1; then
        _ok "cloudfail: installed successfully"
    else
        _err "cloudfail: verification failed"
        "${Z1_BIN}/cloudfail" --help 2>&1 | head -10
    fi
}

function _oneforall() {
    local dest="${Z1_SRC}/OneForAll"
    if [[ -d "${dest}" ]]; then
        rm -rf "${dest}"
    fi
    _run_logged "git: OneForAll" git clone -q --depth 1 https://github.com/shmilylty/OneForAll.git "${dest}" \
        || return 1
    /usr/bin/python3 -m venv "${dest}/venv" \
        && _ok "venv: oneforall" || { _err "venv: oneforall"; return 1; }
    _run_logged "pip: upgrade pip/setuptools/wheel" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel
    _run_logged "pip: requirements.txt" \
        "${dest}/venv/bin/pip" install --no-cache-dir -r "${dest}/requirements.txt" \
        || return 1
    local sitepkg
    sitepkg=$("${dest}/venv/bin/python3" -c "import sysconfig; print(sysconfig.get_path('purelib'))")
    cat > "${sitepkg}/pipes.py" << 'EOF'
"""Compatibility shim: `pipes` module was removed in Python 3.13.
python-fire (OneForAll dependency) still does `import pipes` and uses
`pipes.quote`, which is equivalent to `shlex.quote`."""
from shlex import quote
EOF
    _ok "shim: pipes -> shlex (Python 3.13 compat)"
    cat > "${Z1_BIN}/oneforall" << EOF
#!/usr/bin/env bash
cd "${dest}" && exec "${dest}/venv/bin/python3" "${dest}/oneforall.py" "\$@"
EOF
    chmod +x "${Z1_BIN}/oneforall"
    _ok "oneforall: wrapper created at ${Z1_BIN}/oneforall"
    if "${Z1_BIN}/oneforall" check >/dev/null 2>&1; then
        _ok "oneforall: installed successfully"
    else
        _err "oneforall: verification failed"
        "${Z1_BIN}/oneforall" check 2>&1 | head -10
    fi
}

function _corscanner() {
    _git corscanner https://github.com/chenjj/CORScanner.git
    local dest="${Z1_SRC}/corscanner"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" gevent
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/cors_scan" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/cors_scan.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/cors_scan"
        _ok "git: corscanner → ${Z1_BIN}/cors_scan"
    fi
}

function _hakrawler() {
    _go hakrawler github.com/hakluke/hakrawler@latest
}

function _linkfinder() {
    _git linkfinder https://github.com/GerbenJavado/LinkFinder.git
    local dest="${Z1_SRC}/linkfinder"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" jsbeautifier
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/linkfinder.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/linkfinder.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/linkfinder.py"
        ln -sf "${Z1_BIN}/linkfinder.py" "${Z1_BIN}/linkfinder"
        _ok "git: linkfinder → ${Z1_BIN}/linkfinder"
    fi
}

function _gau() {
    _go gau github.com/lc/gau/v2/cmd/gau@latest
}

function _hakrevdns() {
    _go hakrevdns github.com/hakluke/hakrevdns@latest
}

function _anew() {
    _go anew github.com/tomnomnom/anew@latest
}

function _jsluice() {
    _go jsluice github.com/BishopFox/jsluice/cmd/jsluice@latest
}

function _subzy() {
    _go subzy github.com/PentestPad/subzy@latest
}

function _urldedupe() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone -q --depth 1 https://github.com/ameenmaali/urldedupe.git "${tmp_dir}" >/dev/null 2>&1 \
        && _ok "git: urldedupe (tmp)" || { _err "git: urldedupe"; return; }
    (cd "${tmp_dir}" && cmake CMakeLists.txt >/dev/null 2>&1 && make >/dev/null 2>&1)
    if [[ -f "${tmp_dir}/urldedupe" ]]; then
        mv "${tmp_dir}/urldedupe" "${Z1_BIN}/urldedupe"
        chmod +x "${Z1_BIN}/urldedupe"
        _ok "bin: urldedupe → ${Z1_BIN}/urldedupe"
    else
        _err "urldedupe: make failed"
    fi
    rm -rf "${tmp_dir}"
}

function _wuzz() {
    _go wuzz github.com/asciimoo/wuzz@latest
}

function _curlie() {
    local arch="amd64"
    [[ $(uname -m) == "aarch64" ]] && arch="arm64"
    local url
    url=$(curl -s "https://api.github.com/repos/rs/curlie/releases/latest" \
        | grep "browser_download_url.*curlie.*linux.*${arch}.*tar.gz" \
        | grep -o 'https://[^"]*' | head -1)
    curl -sL -o /tmp/curlie.tar.gz "${url}"
    tar -xzf /tmp/curlie.tar.gz -C /tmp curlie >/dev/null 2>&1
    rm -f /tmp/curlie.tar.gz
    if [[ -f /tmp/curlie ]]; then
        mv /tmp/curlie "${Z1_BIN}/curlie"
        chmod +x "${Z1_BIN}/curlie"
        _ok "bin: curlie → ${Z1_BIN}/curlie"
    else
        _err "bin: curlie"
    fi
}

function _jwt_tool() {
    _git jwt_tool https://github.com/ticarpi/jwt_tool
    local dest="${Z1_SRC}/jwt_tool"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" ratelimit
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        "${dest}/venv/bin/python3" "${dest}/jwt_tool.py" >/dev/null 2>&1 || :
        if [[ -f /root/.jwt_tool/jwtconf.ini ]]; then
            sed -i 's/^proxy = 127.0.0.1:8080/#proxy = 127.0.0.1:8080/' /root/.jwt_tool/jwtconf.ini
            sed -i "s|^wordlist = jwt-common.txt|wordlist = ${dest}/jwt-common.txt|" /root/.jwt_tool/jwtconf.ini
            sed -i "s|^commonHeaders = common-headers.txt|commonHeaders = ${dest}/common-headers.txt|" /root/.jwt_tool/jwtconf.ini
            sed -i "s|^commonPayloads = common-payloads.txt|commonPayloads = ${dest}/common-payloads.txt|" /root/.jwt_tool/jwtconf.ini
        fi
        cat > "${Z1_BIN}/jwt_tool.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/jwt_tool.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/jwt_tool.py"
        ln -sf "${Z1_BIN}/jwt_tool.py" "${Z1_BIN}/jwt_tool"
        _ok "git: jwt_tool → ${Z1_BIN}/jwt_tool"
    fi
}

function _token_exploiter() {
    _ensure_pipx || return 1
    local log rc
    log=$(pipx install --system-site-packages git+https://github.com/psyray/token-exploiter 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: token-exploiter"
    else
        _err "pipx: token-exploiter (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "------------------"
        return 1
    fi
    if command -v token-exploiter >/dev/null 2>&1; then
        _ok "token-exploiter: installed successfully"
    else
        _err "token-exploiter: binary not found in PATH"
        pipx list 2>&1 | grep -A3 -i "token-exploiter" || true
    fi
}

function _ysoserial() {
    local dest="${Z1_SRC}/ysoserial"
    mkdir -p "${dest}"
    curl -sL -o "${dest}/ysoserial.jar" \
        "https://github.com/frohoff/ysoserial/releases/latest/download/ysoserial-all.jar" \
        && _ok "src: ysoserial.jar" || { _err "src: ysoserial.jar"; return; }
    cat > "${Z1_BIN}/ysoserial" << EOF
#!/usr/bin/env bash
exec java -jar "${dest}/ysoserial.jar" "\$@"
EOF
    chmod +x "${Z1_BIN}/ysoserial"
    _ok "bin: ysoserial → ${Z1_BIN}/ysoserial"
}

function _phpggc() {
    _git phpggc https://github.com/ambionics/phpggc.git
    _link phpggc "${Z1_SRC}/phpggc/phpggc"
}

function _symfony-exploits() {
    _git symfony-exploits https://github.com/ambionics/symfony-exploits
    local dest="${Z1_SRC}/symfony-exploits"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" requests
        cat > "${Z1_BIN}/secret_fragment_exploit.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/secret_fragment_exploit.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/secret_fragment_exploit.py"
        _ok "git: symfony-exploits → ${Z1_BIN}/secret_fragment_exploit.py"
    fi
}

function _php_filter_chain_generator() {
    _git php_filter_chain_generator \
        https://github.com/synacktiv/php_filter_chain_generator.git
    _link php_filter_chain_generator.py \
        "${Z1_SRC}/php_filter_chain_generator/php_filter_chain_generator.py"
}

function _kraken() {
    _git kraken https://github.com/kraken-ng/Kraken.git
    local dest="${Z1_SRC}/kraken"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" jsonschema validators
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/kraken" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/kraken.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/kraken"
        _ok "git: kraken → ${Z1_BIN}/kraken"
    fi
}

function _httpmethods() {
    _git httpmethods https://github.com/ShutdownRepo/httpmethods
    local dest="${Z1_SRC}/httpmethods"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/httpmethods" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/httpmethods.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/httpmethods"
        _ok "git: httpmethods → ${Z1_BIN}/httpmethods"
    fi
}

function _h2csmuggler() {
    _git h2csmuggler https://github.com/BishopFox/h2csmuggler
    local dest="${Z1_SRC}/h2csmuggler"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" h2
        cat > "${Z1_BIN}/h2csmuggler.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/h2csmuggler.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/h2csmuggler.py"
        ln -sf "${Z1_BIN}/h2csmuggler.py" "${Z1_BIN}/h2csmuggler"
        _ok "git: h2csmuggler → ${Z1_BIN}/h2csmuggler"
    fi
}

function _smuggler() {
    _git smuggler https://github.com/defparam/smuggler.git
    local dest="${Z1_SRC}/smuggler"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        cat > "${Z1_BIN}/smuggler.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/smuggler.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/smuggler.py"
        ln -sf "${Z1_BIN}/smuggler.py" "${Z1_BIN}/smuggler"
        _ok "git: smuggler → ${Z1_BIN}/smuggler"
    fi
}

function _byp4xx() {
    _go byp4xx github.com/lobuhi/byp4xx@latest
}

function _tomcatwardeployer() {
    _git tomcatwardeployer https://github.com/mgeeky/tomcatWarDeployer.git
    local dest="${Z1_SRC}/tomcatwardeployer"
    if [[ -d "${dest}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        _venv_pip "${dest}" mechanize
        [[ -f "${dest}/requirements.txt" ]] && \
            _venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/tomcatWarDeployer" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/tomcatWarDeployer.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/tomcatWarDeployer"
        _ok "git: tomcatwardeployer → ${Z1_BIN}/tomcatWarDeployer"
    fi
}

function _git-dumper() {
    _ensure_pipx || return 1
    local log rc
    log=$(pipx install --system-site-packages git-dumper 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: git-dumper"
    else
        _err "pipx: git-dumper (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "------------------"
        return 1
    fi
    if command -v git-dumper >/dev/null 2>&1; then
        _ok "git-dumper: installed successfully"
    else
        _err "git-dumper: binary not found in PATH"
        pipx list 2>&1 | grep -A3 -i "git-dumper" || true
    fi
}

function _gittools() {
    _git gittools https://github.com/internetwache/GitTools.git
    local finder="${Z1_SRC}/gittools/Finder"
    local extractor="${Z1_SRC}/gittools/Extractor"
    local dumper="${Z1_SRC}/gittools/Dumper"
    if [[ -d "${finder}" ]]; then
        /usr/bin/python3 -m venv --system-site-packages "${finder}/venv" >/dev/null 2>&1
        [[ -f "${finder}/requirements.txt" ]] && \
            "${finder}/venv/bin/pip" install -q --no-cache-dir \
                -r "${finder}/requirements.txt" 2>/dev/null
        cat > "${Z1_BIN}/gitfinder.py" << EOF
#!/usr/bin/env bash
exec "${finder}/venv/bin/python3" "${finder}/gitfinder.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/gitfinder.py"
        ln -sf "${Z1_BIN}/gitfinder.py" "${Z1_BIN}/gitfinder"
    fi
    [[ -f "${extractor}/extractor.sh" ]] && _link extractor.sh "${extractor}/extractor.sh"
    [[ -f "${dumper}/gitdumper.sh" ]]    && _link gitdumper.sh "${dumper}/gitdumper.sh"
    _ok "git: gittools → ${Z1_BIN}"
}

function _xxeinjector() {
    curl -sL https://raw.githubusercontent.com/enjoiz/XXEinjector/refs/heads/master/XXEinjector.rb \
        -o "${Z1_BIN}/XXEinjector.rb" \
        && chmod +x "${Z1_BIN}/XXEinjector.rb" \
        && _ok "bin: XXEinjector.rb → ${Z1_BIN}/XXEinjector.rb" \
        || _err "bin: XXEinjector"
}

function _bbot() {
    _ensure_pipx || return 1
    local log rc
    log=$(pipx install --system-site-packages bbot 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: bbot"
    else
        _err "pipx: bbot (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "------------------"
        return 1
    fi
    if command -v bbot >/dev/null 2>&1; then
        _ok "bbot: installed successfully"
    else
        _err "bbot: binary not found in PATH"
        pipx list 2>&1 | grep -A3 -i "bbot" || true
    fi
}

function _web() {
    _rvm
    _pyenv
    _set_env

    _web_apt_tools

    _weevely
    _whatweb

    _kiterunner
    _dirsearch

    _ssrfmap
    _gopherus
    _nosqlmap
    _sqlmap

    _xsstrike
    _bolt

    _kadimus
    _fuxploider
    _patator

    _joomscan
    _wpscan
    _droopescan
    _drupwn
    _cmsmap
    _moodlescan

    _testssl
    _sslscan

    _cloudfail
    _oneforall
    _corscanner
    _hakrawler
    _linkfinder
    _gau
    _hakrevdns
    _anew
    _jsluice
    _subzy
    _urldedupe

    _wuzz
    _curlie

    _jwt_tool
    _token_exploiter

    _ysoserial
    _phpggc
    _symfony-exploits
    _php_filter_chain_generator
    _kraken

    _httpmethods
    _h2csmuggler
    _smuggler
    _byp4xx

    _tomcatwardeployer

    _git-dumper
    _gittools

    _xxeinjector

    _bbot
}
