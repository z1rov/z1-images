#!/usr/bin/env bash

Z1_HOME="/z1"
Z1_USER="${Z1_USER:-z1user}"
Z1_UID="${Z1_UID:-1000}"
Z1_GID="${Z1_GID:-1000}"
Z1_WORKSPACE="${Z1_WORKSPACE:-/workspace}"

if getent group "${Z1_GID}" >/dev/null 2>&1; then
    Z1_GROUP=$(getent group "${Z1_GID}" | cut -d: -f1)
else
    groupadd -g "${Z1_GID}" "${Z1_USER}"
    Z1_GROUP="${Z1_USER}"
fi

if ! id -u "${Z1_USER}" >/dev/null 2>&1; then
    useradd -m -u "${Z1_UID}" -g "${Z1_GROUP}" -s /bin/zsh "${Z1_USER}"
fi

usermod -aG sudo "${Z1_USER}" 2>/dev/null || true
echo "${Z1_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${Z1_USER}"
chmod 0440 "/etc/sudoers.d/${Z1_USER}"

Z1_USER_HOME=$(getent passwd "${Z1_USER}" | cut -d: -f6)

export Z1_WORKSPACE
if [[ -f "${Z1_HOME}/runtime/workspace.sh" ]]; then
    source "${Z1_HOME}/runtime/workspace.sh" || true
fi

if [[ -f "${Z1_HOME}/assets/zshrc-z1" ]]; then
    cp "${Z1_HOME}/assets/zshrc-z1" "${Z1_USER_HOME}/.zshrc"
    chown "${Z1_USER}:${Z1_GROUP}" "${Z1_USER_HOME}/.zshrc"
fi

if [[ -f "${Z1_HOME}/assets/aliases.sh" ]]; then
    cp "${Z1_HOME}/assets/aliases.sh" "${Z1_USER_HOME}/.z1-aliases.sh"
    chown "${Z1_USER}:${Z1_GROUP}" "${Z1_USER_HOME}/.z1-aliases.sh"
    grep -qxF "source \"${Z1_USER_HOME}/.z1-aliases.sh\"" "${Z1_USER_HOME}/.zshrc" 2>/dev/null || \
        echo "source \"${Z1_USER_HOME}/.z1-aliases.sh\"" >> "${Z1_USER_HOME}/.zshrc"

    touch "${Z1_USER_HOME}/.bashrc"
    grep -qxF "source \"${Z1_USER_HOME}/.z1-aliases.sh\"" "${Z1_USER_HOME}/.bashrc" 2>/dev/null || \
        echo "source \"${Z1_USER_HOME}/.z1-aliases.sh\"" >> "${Z1_USER_HOME}/.bashrc"
    chown "${Z1_USER}:${Z1_GROUP}" "${Z1_USER_HOME}/.bashrc"
fi

if [[ "${VNC_MODE:-0}" == "1" ]] && [[ -f "${Z1_HOME}/runtime/vnc.sh" ]]; then
    source "${Z1_HOME}/runtime/vnc.sh"
    start_vnc "${Z1_USER}"
fi

cd "${Z1_WORKSPACE}" 2>/dev/null || cd "${Z1_USER_HOME}"

exec su -s /bin/zsh -l "${Z1_USER}"
