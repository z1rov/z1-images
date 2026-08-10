#!/usr/bin/env bash

start_vnc() {
    local target_user="$1"
    local display_num="${VNC_DISPLAY:-1}"
    local vnc_port="${VNC_PORT:-5900}"
    local resolution="${VNC_RESOLUTION:-1920x1080x24}"

    if pgrep -f "x11vnc.*-rfbport ${vnc_port}" >/dev/null 2>&1 \
        && pgrep -f "Xvfb :${display_num} " >/dev/null 2>&1 \
        && pgrep -f "fluxbox" >/dev/null 2>&1; then
        echo "[z1] vnc already active on port ${vnc_port}"
        return 0
    fi

    stop_vnc >/dev/null 2>&1

    rm -f "/tmp/.X${display_num}-lock" "/tmp/.X11-unix/X${display_num}" 2>/dev/null

    setsid nohup Xvfb ":${display_num}" -screen 0 "${resolution}" -nolisten tcp >/tmp/xvfb.log 2>&1 </dev/null &
    disown

    local i=0
    while [[ ! -e "/tmp/.X11-unix/X${display_num}" && $i -lt 20 ]]; do
        sleep 0.3
        i=$((i+1))
    done

    if [[ ! -e "/tmp/.X11-unix/X${display_num}" ]]; then
        echo "[z1] vnc failed: Xvfb did not start (see /tmp/xvfb.log)"
        return 1
    fi

    setsid nohup env DISPLAY=":${display_num}" fluxbox >/tmp/fluxbox.log 2>&1 </dev/null &
    disown
    sleep 1

    if [[ -n "${VNC_PASSWORD:-}" ]]; then
        mkdir -p /etc/x11vnc
        x11vnc -storepasswd "${VNC_PASSWORD}" /etc/x11vnc/passwd >/dev/null 2>&1
        setsid nohup x11vnc -display ":${display_num}" -forever -shared -rfbport "${vnc_port}" -o /tmp/x11vnc.log -rfbauth /etc/x11vnc/passwd -noxdamage </dev/null >/tmp/x11vnc-stdout.log 2>&1 &
        disown
    else
        setsid nohup x11vnc -display ":${display_num}" -forever -shared -rfbport "${vnc_port}" -o /tmp/x11vnc.log -nopw -noxdamage </dev/null >/tmp/x11vnc-stdout.log 2>&1 &
        disown
    fi

    sleep 1

    if ! pgrep -f "x11vnc.*-rfbport ${vnc_port}" >/dev/null 2>&1; then
        echo "[z1] vnc failed: x11vnc did not start (see /tmp/x11vnc.log)"
        return 1
    fi

    mkdir -p /etc/zsh
    touch /etc/zsh/zshenv
    grep -qxF "export DISPLAY=:${display_num}" /etc/zsh/zshenv || echo "export DISPLAY=:${display_num}" >> /etc/zsh/zshenv
    grep -qxF "export DISPLAY=:${display_num}" /etc/bash.bashrc 2>/dev/null || echo "export DISPLAY=:${display_num}" >> /etc/bash.bashrc

    if [[ -n "${target_user}" ]]; then
        local target_home
        target_home=$(getent passwd "${target_user}" | cut -d: -f6)
        if [[ -n "${target_home}" ]]; then
            touch "${target_home}/.zshrc" "${target_home}/.bashrc" 2>/dev/null
            grep -qxF "export DISPLAY=:${display_num}" "${target_home}/.zshrc" 2>/dev/null || echo "export DISPLAY=:${display_num}" >> "${target_home}/.zshrc"
            grep -qxF "export DISPLAY=:${display_num}" "${target_home}/.bashrc" 2>/dev/null || echo "export DISPLAY=:${display_num}" >> "${target_home}/.bashrc"
        fi
    fi

    echo "[z1] vnc listening on 0.0.0.0:${vnc_port}"
}

stop_vnc() {
    local vnc_port="${VNC_PORT:-5900}"
    local display_num="${VNC_DISPLAY:-1}"

    pkill -f "x11vnc.*-rfbport ${vnc_port}" 2>/dev/null
    pkill -f "fluxbox" 2>/dev/null
    pkill -f "Xvfb :${display_num} " 2>/dev/null

    sleep 0.5
    rm -f "/tmp/.X${display_num}-lock" "/tmp/.X11-unix/X${display_num}" 2>/dev/null

    echo "[z1] vnc stopped"
}

status_vnc() {
    local vnc_port="${VNC_PORT:-5900}"
    local display_num="${VNC_DISPLAY:-1}"

    local xvfb_up=0 flux_up=0 x11vnc_up=0
    pgrep -f "Xvfb :${display_num} " >/dev/null 2>&1 && xvfb_up=1
    pgrep -f "fluxbox" >/dev/null 2>&1 && flux_up=1
    pgrep -f "x11vnc.*-rfbport ${vnc_port}" >/dev/null 2>&1 && x11vnc_up=1

    if [[ ${xvfb_up} -eq 1 && ${flux_up} -eq 1 && ${x11vnc_up} -eq 1 ]]; then
        echo "[z1] vnc status: running (display :${display_num}, port ${vnc_port})"
    elif [[ ${xvfb_up} -eq 0 && ${flux_up} -eq 0 && ${x11vnc_up} -eq 0 ]]; then
        echo "[z1] vnc status: stopped"
    else
        echo "[z1] vnc status: degraded (Xvfb=${xvfb_up} fluxbox=${flux_up} x11vnc=${x11vnc_up})"
    fi
}
