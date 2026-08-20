#!/usr/bin/env bash
# Author: z1rov

source /z1/install/func.sh
mkdir -p /opt/tools

function _ncat() {
    _apt ncat
}

function _sshuttle() {
    _apt sshuttle
}

function _chisel() {
    _apt unzip

    local version
    version=$(_gh_version "jpillora/chisel")
    [[ -z "${version}" ]] && return 1

    local base="https://github.com/jpillora/chisel/releases/download/v${version}"
    local tmp; tmp=$(mktemp -d)

    curl -sL -o "${tmp}/chisel_linux.gz" "${base}/chisel_${version}_linux_amd64.gz"
    gunzip -f "${tmp}/chisel_linux.gz" 2>/dev/null

    if [[ -f "${tmp}/chisel_linux" ]]; then
        chmod +x "${tmp}/chisel_linux"
        cp "${tmp}/chisel_linux" "${Z1_BIN}/chisel"
    fi

    rm -rf "${tmp}"
}

function _ligolo() {
    _apt unzip

    local version
    version=$(_gh_version "nicocha30/ligolo-ng")
    [[ -z "${version}" ]] && return 1

    local base="https://github.com/nicocha30/ligolo-ng/releases/download/v${version}"
    local tmp; tmp=$(mktemp -d)

    curl -sL -o "${tmp}/agent_linux.tar.gz" "${base}/ligolo-ng_agent_${version}_linux_amd64.tar.gz"
    if tar -tzf "${tmp}/agent_linux.tar.gz" >/dev/null 2>&1; then
        tar -xzf "${tmp}/agent_linux.tar.gz" -C "${tmp}" 2>/dev/null
        local agent_bin
        agent_bin=$(find "${tmp}" -maxdepth 3 -type f -name "agent" 2>/dev/null | head -1)
        if [[ -n "${agent_bin}" ]]; then
            chmod +x "${agent_bin}"
            cp "${agent_bin}" "${Z1_BIN}/ligolo-agent"
        fi
    fi
    rm -rf "${tmp:?}"/*

    curl -sL -o "${tmp}/proxy_linux.tar.gz" "${base}/ligolo-ng_proxy_${version}_linux_amd64.tar.gz"
    if tar -tzf "${tmp}/proxy_linux.tar.gz" >/dev/null 2>&1; then
        tar -xzf "${tmp}/proxy_linux.tar.gz" -C "${tmp}" 2>/dev/null
        local proxy_bin
        proxy_bin=$(find "${tmp}" -maxdepth 3 -type f -name "proxy" 2>/dev/null | head -1)
        if [[ -n "${proxy_bin}" ]]; then
            chmod +x "${proxy_bin}"
            cp "${proxy_bin}" "${Z1_BIN}/ligolo-proxy"
        fi
    fi
    rm -rf "${tmp}"
}

function _villain() {
    local dest="${Z1_SRC}/Villain"
    _git Villain https://github.com/t3l3machus/Villain

    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/requirements.txt" 2>/dev/null || true
    fi

    if [[ -f "${dest}/Villain.py" ]]; then
        printf '#!/usr/bin/env bash\nexec python3 "%s/Villain.py" "$@"\n' \
            "${dest}" > "${Z1_BIN}/villain"
        chmod +x "${Z1_BIN}/villain"
    fi
}

function _sliver() {
    local dest_dir="${Z1_SRC}/sliver"
    mkdir -p "${dest_dir}"
    local arch="amd64"
    [[ $(uname -m) == "aarch64" ]] && arch="arm64"

    local url_server url_client
    url_server=$(_gh_find_asset "BishopFox/sliver" \
        "'sliver-server' in n and 'linux' in n and '${arch}' in n")
    url_client=$(_gh_find_asset "BishopFox/sliver" \
        "'sliver-client' in n and 'linux' in n and '${arch}' in n")

    if [[ -n "${url_server}" ]]; then
        curl -sL -o "${dest_dir}/sliver-server" "${url_server}"
        chmod +x "${dest_dir}/sliver-server"
        ln -sf "${dest_dir}/sliver-server" "${Z1_BIN}/sliver-server"
    fi

    if [[ -n "${url_client}" ]]; then
        curl -sL -o "${dest_dir}/sliver-client" "${url_client}"
        chmod +x "${dest_dir}/sliver-client"
        ln -sf "${dest_dir}/sliver-client" "${Z1_BIN}/sliver-client"
    fi
}

function _metasploit() {
    local dest="${Z1_SRC}/metasploit-framework"

    for pkg in libpcap-dev libpq-dev zlib1g-dev libsqlite3-dev postgresql; do
        _apt "${pkg}"
    done

    _git metasploit-framework https://github.com/rapid7/metasploit-framework.git

    cd "${dest}" || return 1
    git config user.name "z1"
    git config user.email "z1@localhost"

    if ! command -v rvm >/dev/null 2>&1; then
        curl -sSL https://rvm.io/mpapis.asc | gpg --import - 2>/dev/null || true
        curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - 2>/dev/null || true
        curl -sSL https://get.rvm.io | bash -s stable >/dev/null 2>&1
    fi
    [[ -s /etc/profile.d/rvm.sh ]] && source /etc/profile.d/rvm.sh
    [[ -s ~/.rvm/scripts/rvm   ]] && source ~/.rvm/scripts/rvm

    rvm install 3.3.8 --quiet 2>/dev/null || true
    rvm use 3.3.8@metasploit-framework --create --quiet 2>/dev/null || true

    gem install bundler --quiet --no-document 2>/dev/null || true
    bundle install --quiet 2>/dev/null || true
    gem install rex rex-text --quiet --no-document 2>/dev/null || true
    gem install timeout --version 0.4.1 --quiet --no-document 2>/dev/null || true

    chmod -R o+rx "${dest}/"
    chmod 444 "${dest}/.git/index" 2>/dev/null || true
    cp -r /root/.bundle /var/lib/postgresql/ 2>/dev/null || true
    chown -R postgres:postgres /var/lib/postgresql/.bundle 2>/dev/null || true

    sudo -u postgres bash -c "
        source /etc/profile.d/rvm.sh 2>/dev/null || source ~/.rvm/scripts/rvm 2>/dev/null || true
        git config --global --add safe.directory ${dest}
        rvm use 3.3.8@metasploit-framework --quiet 2>/dev/null || true
        bundle exec ${dest}/msfdb init 2>/dev/null || true
    " 2>/dev/null || true

    cp -r /var/lib/postgresql/.msf4 /root 2>/dev/null || true

    curl -sL \
        https://raw.githubusercontent.com/peass-ng/PEASS-ng/master/metasploit/peass.rb \
        -o "${dest}/modules/post/multi/gather/peass.rb" 2>/dev/null || true

    for tool in msfconsole msfvenom msfdb msfrpc msfrpcd msfupdate; do
        if [[ -f "${dest}/${tool}" ]]; then
            cat > "${Z1_BIN}/${tool}" << WRAPPER
#!/usr/bin/env bash
[[ -s /etc/profile.d/rvm.sh ]] && source /etc/profile.d/rvm.sh
[[ -s ~/.rvm/scripts/rvm   ]] && source ~/.rvm/scripts/rvm
rvm use 3.3.8@metasploit-framework --quiet 2>/dev/null || true
cd "${dest}"
exec "${dest}/${tool}" "\$@"
WRAPPER
            chmod +x "${Z1_BIN}/${tool}"
        fi
    done

    cd /
}

function _proxify() {
    _go proxify github.com/projectdiscovery/proxify/cmd/proxify@latest
}

function _goproxy() {
    _go goproxy github.com/snail007/goproxy@latest
}

function _netexec() {
    local NXC_DIR="${Z1_SRC}/NetExec"
    _rust || return 1
    [[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env"

    if [[ ! -d "${NXC_DIR}" ]]; then
        git clone -q --depth 1 https://github.com/Pennyw0rth/NetExec "${NXC_DIR}" >/dev/null 2>&1 || return 1
    fi

    pipx ensurepath >/dev/null 2>&1
    export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
    pipx install --system-site-packages --force "${NXC_DIR}" || return 1

    pip3 uninstall -y oscrypto --break-system-packages >/dev/null 2>&1 || true
    pipx runpip netexec install --force-reinstall --no-deps \
        "git+https://github.com/wbond/oscrypto.git" >/dev/null 2>&1

    local pipx_bin="${HOME}/.local/bin/nxc"
    if [[ -f "${pipx_bin}" ]]; then
        ln -sf "${pipx_bin}" "${Z1_BIN}/nxc"
    fi
}

function _penelope() {
    _ensure_pipx || return 1
    pipx install --system-site-packages penelope-shell-handler >/dev/null 2>&1
}

function _inf() {
    _ncat
    _penelope
    _sshuttle
    _chisel
    _ligolo

    _villain
    _sliver
    _metasploit

    _proxify
    _goproxy
    _netexec
}
