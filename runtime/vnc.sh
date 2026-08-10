# ./runtime/vnc.sh

#!/usr/bin/env bash

start_vnc() {
    local target_user="$1"
    local display_num="${VNC_DISPLAY:-1}"
    local vnc_port="${VNC_PORT:-5900}"
    local resolution="${VNC_RESOLUTION:-1920x1080x24}"

    if pgrep -f "x11vnc.*-rfbport ${vnc_port}" >/dev/null 2>&1; then
        echo "[z1] vnc already active on port ${vnc_port}"
        return 0
    fi

    if ! pgrep -f "Xvfb :${display_num} " >/dev/null 2>&1; then
        Xvfb ":${display_num}" -screen 0 "${resolution}" -nolisten tcp &
        sleep 1

        DISPLAY=":${display_num}" fluxbox >/tmp/fluxbox.log 2>&1 &
        sleep 1
    fi

    if [[ -n "${VNC_PASSWORD:-}" ]]; then
        mkdir -p /etc/x11vnc
        x11vnc -storepasswd "${VNC_PASSWORD}" /etc/x11vnc/passwd >/dev/null 2>&1
        x11vnc -display ":${display_num}" -forever -shared -rfbport "${vnc_port}" -bg -o /tmp/x11vnc.log -rfbauth /etc/x11vnc/passwd
    else
        x11vnc -display ":${display_num}" -forever -shared -rfbport "${vnc_port}" -bg -o /tmp/x11vnc.log -nopw
    fi

    mkdir -p /etc/zsh
    touch /etc/zsh/zshenv
    grep -qxF "DISPLAY=:${display_num}" /etc/zsh/zshenv || echo "DISPLAY=:${display_num}" >> /etc/zsh/zshenv
    grep -qxF "export DISPLAY=:${display_num}" /etc/bash.bashrc 2>/dev/null || echo "export DISPLAY=:${display_num}" >> /etc/bash.bashrc

    export DISPLAY=":${display_num}"
    echo "[z1] vnc listening on 0.0.0.0:${vnc_port}"
}
