#!/usr/bin/env bash

Z1_HOME="/z1"
Z1_USER="${Z1_USER:-z1user}"
Z1_UID="${Z1_UID:-1000}"
Z1_GID="${Z1_GID:-1000}"

if getent group "${Z1_GID}" >/dev/null 2>&1; then
    Z1_GROUP=$(getent group "${Z1_GID}" | cut -d: -f1)
    if [[ "${Z1_GROUP}" != "${Z1_USER}" ]]; then
        groupmod -n "${Z1_USER}" "${Z1_GROUP}" 2>/dev/null || true
        Z1_GROUP="${Z1_USER}"
    fi
else
    groupadd -g "${Z1_GID}" "${Z1_USER}"
    Z1_GROUP="${Z1_USER}"
fi

if id -u "${Z1_USER}" >/dev/null 2>&1; then
    :
elif getent passwd "${Z1_UID}" >/dev/null 2>&1; then
    EXISTING_USER=$(getent passwd "${Z1_UID}" | cut -d: -f1)
    usermod -l "${Z1_USER}" -d "/home/${Z1_USER}" -m -g "${Z1_GID}" -s /bin/zsh "${EXISTING_USER}"
else
    useradd -m -u "${Z1_UID}" -g "${Z1_GROUP}" -s /bin/zsh "${Z1_USER}"
fi

usermod -aG sudo "${Z1_USER}" 2>/dev/null || true
echo "${Z1_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${Z1_USER}"
chmod 0440 "/etc/sudoers.d/${Z1_USER}"

Z1_USER_HOME=$(getent passwd "${Z1_USER}" | cut -d: -f6)
mkdir -p "${Z1_USER_HOME}"

if [[ -d "/root/.oh-my-zsh" ]] && [[ ! -d "${Z1_USER_HOME}/.oh-my-zsh" ]]; then
    cp -r "/root/.oh-my-zsh" "${Z1_USER_HOME}/.oh-my-zsh" || true
fi

chown -R "${Z1_USER}:${Z1_GROUP}" "${Z1_USER_HOME}" || true
chmod -R 0777 "${Z1_USER_HOME}" || true

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

chmod -R 0777 "${Z1_USER_HOME}" || true

cd "${Z1_USER_HOME}"

Z1_SHELL="/bin/zsh"
[[ -x "${Z1_SHELL}" ]] || Z1_SHELL="/bin/bash"

exec su -s "${Z1_SHELL}" -l "${Z1_USER}"
