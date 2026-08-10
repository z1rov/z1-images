#!/usr/bin/env bash
# Author: z1rov
source /z1/install/func.sh
mkdir -p /opt/tools

_linpeas() {
    _forja linpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" linpeas.sh
}

_linux_exploit_suggester() {
    _forja linux-exploit-suggester "https://raw.githubusercontent.com/The-Z-Labs/linux-exploit-suggester/master/linux-exploit-suggester.sh" "linux-exploit-suggester.sh"
}

_linenum() {
    _forja linenum "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" LinEnum.sh
}

_pspy() {
    local forja_dir="${Z1_FORJA}/pspy"
    mkdir -p "${forja_dir}"
    local base_url="https://github.com/DominicBreuker/pspy/releases/latest/download"
    curl -sfL -o "${forja_dir}/pspy64" "${base_url}/pspy64" && chmod +x "${forja_dir}/pspy64" || _err "forja: pspy64"
    curl -sfL -o "${forja_dir}/pspy32" "${base_url}/pspy32" && chmod +x "${forja_dir}/pspy32" || _err "forja: pspy32"
    _ok "forja: pspy"
}

_lse() {
    _forja lse "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" lse.sh
}

_winpeas() {
    _forja winpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe" winPEASx64.exe
    _forja winpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe" winPEASx86.exe
    _forja winpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASany.exe" winPEASany.exe
}

_privesc_check() {
    _forja privesc-check "https://github.com/itm4n/PrivescCheck/releases/latest/download/PrivescCheck.ps1" "PrivescCheck.ps1"
}

_powerup() {
    _forja powersploit "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" PowerUp.ps1
}

_watson() {
    _forja watson "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Watson.exe" "Watson.exe"
}

_sharpbypassuac() {
    _forja sharpbypassuac "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpBypassUAC.exe" "SharpBypassUAC.exe"
}

_rubeus() {
    _forja rubeus "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Rubeus.exe" "Rubeus.exe"
}

_seatbelt() {
    _forja seatbelt "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Seatbelt.exe" "Seatbelt.exe"
}

_sharpup() {
    _forja sharpup "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpUp.exe" "SharpUp.exe"
}

_sharpsqlpwn() {
    _forja sharpsqlpwn "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpSQLPwn.exe" "SharpSQLPwn.exe"
}

_sharpview() {
    _forja sharpview "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpView.exe" "SharpView.exe"
}

_sharpshooter() {
    local dest="${Z1_FORJA}/sharpshooter"
    mkdir -p "${Z1_FORJA}"
    if [[ -d "${dest}" ]]; then
        _info "SharpShooter repo already exists, removing before re-cloning"
        rm -rf "${dest}"
    fi
    local log rc
    log=$(git clone --depth 1 https://github.com/mdsecactivebreach/SharpShooter "${dest}" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "git: SharpShooter → ${dest}"
    else
        _err "git: SharpShooter (rc=${rc})"
        return 1
    fi
    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages -r "${dest}/requirements.txt" 2>/dev/null || true
    fi
    if [[ -f "${dest}/SharpShooter.py" ]]; then
        printf '#!/usr/bin/env bash\ncd "%s" && exec python3 SharpShooter.py "$@"\n' "${dest}" > "${Z1_BIN}/sharpshooter"
        chmod +x "${Z1_BIN}/sharpshooter"
        _ok "git: SharpShooter → ${Z1_BIN}/sharpshooter (wrapper python3)"
    else
        _err "git: SharpShooter (SharpShooter.py not found)"
    fi
}

_sharpapplocker() {
    _forja sharpapplocker "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpAppLocker.exe" "SharpAppLocker.exe"
}

_krbrelayup() {
    _forja krbrelayup "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/KrbRelayUp.exe" "KrbRelayUp.exe"
}

_certify() {
    _forja certify "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Certify.exe" "Certify.exe"
}

_forgecert() {
    _forja forgecert "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/ForgeCert.exe" "ForgeCert.exe"
}

_whisker() {
    _forja whisker "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Whisker.exe" "Whisker.exe"
}

_passthecert() {
    _forja passthecert "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/PassTheCert.exe" "PassTheCert.exe"
}

_standin() {
    _forja standin "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/StandIn.exe" "StandIn.exe"
}

_adcspwn() {
    local forja_dir="${Z1_FORJA}/adcspwn"
    mkdir -p "${forja_dir}"
    curl -sfL -o "${forja_dir}/ADCSPwn.exe" "https://github.com/bats3c/ADCSPwn/releases/download/v1.0/ADCSPwn.exe" && _ok "forja: ADCSPwn" || _err "forja: ADCSPwn"
}

_runascs() {
    _forja runascs "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/RunasCs.exe" "RunasCs.exe"
}

_adsearch() {
    _forja adsearch "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/ADSearch.exe" "ADSearch.exe"
}

_sharpdpapi() {
    _forja sharpdpapi "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpDPAPI.exe" "SharpDPAPI.exe"
}

_adrecon() {
    local forja_dir="${Z1_FORJA}/adrecon"
    mkdir -p "${forja_dir}"
    curl -sfL -o "${forja_dir}/ADRecon.ps1" "https://raw.githubusercontent.com/adrecon/ADRecon/master/ADRecon.ps1" && _ok "forja: ADRecon" || _err "forja: ADRecon"
}

_lazagne() {
    local forja_dir="${Z1_FORJA}/lazagne"
    mkdir -p "${forja_dir}"
    curl -sfL -o "${forja_dir}/lazagne.exe" "https://github.com/AlessandroZ/LaZagne/releases/latest/download/lazagne.exe" && _ok "forja: LaZagne (Windows)" || _err "forja: LaZagne (Windows)"
}

_safetykatz() {
    _forja safetykatz "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SafetyKatz.exe" "SafetyKatz.exe"
}

_sqlrecon() {
    local forja_dir="${Z1_FORJA}/sqlrecon"
    mkdir -p "${forja_dir}"
    curl -sfL -o "${forja_dir}/SQLRecon.exe" "https://github.com/skahwah/SQLRecon/releases/latest/download/SQLRecon.exe" && _ok "forja: SQLRecon" || _err "forja: SQLRecon"
}

_powerupsql() {
    local forja_dir="${Z1_FORJA}/powerupsql"
    mkdir -p "${forja_dir}"
    curl -sfL -o "${forja_dir}/PowerUpSQL.ps1" "https://raw.githubusercontent.com/NetSPI/PowerUpSQL/master/PowerUpSQL.ps1" && _ok "forja: PowerUpSQL" || _err "forja: PowerUpSQL"
}

_mimikatz() {
    local url
    url=$(curl -s https://api.github.com/repos/gentilkiwi/mimikatz/releases/latest | grep "browser_download_url.*\.zip\"" | grep -o 'https://[^"]*' | head -1)
    if [[ -z "${url}" ]]; then
        _err "mimikatz: no release found"
        return
    fi
    local dest_dir="${Z1_FORJA}/mimikatz"
    mkdir -p "${dest_dir}"
    curl -sfL -o "${dest_dir}/mimikatz.zip" "${url}" && unzip -oq "${dest_dir}/mimikatz.zip" -d "${dest_dir}" && rm -f "${dest_dir}/mimikatz.zip" && _ok "forja: mimikatz" || _err "forja: mimikatz"
}

_ghostpack() {
    local base="https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64"
    local tool
    for tool in Rubeus Seatbelt SharpUp SharpView; do
        _forja ghostpack "${base}/${tool}.exe" "${tool}.exe"
    done
}

_sharphound() {
    local dest_dir="${Z1_FORJA}/sharphound"
    mkdir -p "${dest_dir}"

    local version
    version=$(_gh_version "SpecterOps/SharpHound")
    if [[ -z "${version}" ]]; then
        _err "forja: sharphound (could not resolve latest version)"
        return
    fi

    local url="https://github.com/SpecterOps/SharpHound/releases/download/v${version}/SharpHound_v${version}_windows_x86.zip"
    local zip="${dest_dir}/sharphound.zip"

    curl -sfL -o "${zip}" "${url}"
    if [[ ! -s "${zip}" ]] || ! unzip -tq "${zip}" >/dev/null 2>&1; then
        _err "forja: sharphound (download failed or invalid zip, url=${url})"
        rm -f "${zip}"
        return
    fi

    unzip -oq "${zip}" -d "${dest_dir}" && rm -f "${zip}" && _ok "forja: sharphound (v${version})" || _err "forja: sharphound (unzip failed)"
}

_ncwin() {
    _forja netcat-win "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" nc64.exe
    _forja netcat-win "https://github.com/int0x33/nc.exe/raw/master/nc.exe" nc.exe
}

_sharpwmi() {
    _forja sharpwmi "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpWMI.exe" "SharpWMI.exe"
}

_sharpcom() {
    _forja sharpcom "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpCOM.exe" "SharpCOM.exe"
}

_sharpmove() {
    _forja sharpmove "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpMove.exe" "SharpMove.exe"
}

_sharpnamedpipepth() {
    _forja sharpnamedpipepth "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpNamedPipePTH.exe" "SharpNamedPipePTH.exe"
}

_inveigh() {
    _forja inveigh "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Inveigh.exe" "Inveigh.exe"
}

_sharpsccm() {
    _forja sharpsccm "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpSCCM.exe" "SharpSCCM.exe"
}

_plink() {
    _forja plink "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" "plink.exe"
}

_putty() {
    _forja putty "https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe" "putty.exe"
}

_invoke_obfuscation() {
    _forja invoke-obfuscation "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psd1" "Invoke-Obfuscation.psd1"
    _forja invoke-obfuscation "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psm1" "Invoke-Obfuscation.psm1"
}

_chisel_win() {
    local forja_dir="${Z1_FORJA}/chisel"
    mkdir -p "${forja_dir}"
    _apt unzip
    local version
    version=$(_gh_version "jpillora/chisel")
    if [[ -z "${version}" ]]; then
        _err "chisel (windows): could not get release version"
        return
    fi
    local base="https://github.com/jpillora/chisel/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)
    curl -sfL -o "${tmp}/chisel_windows.zip" "${base}/chisel_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/win"
    unzip -q "${tmp}/chisel_windows.zip" -d "${tmp}/win" 2>/dev/null
    local win_bin
    win_bin=$(find "${tmp}/win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${win_bin}" ]]; then
        cp "${win_bin}" "${forja_dir}/chisel_windows_amd64.exe"
        _ok "forja: chisel (windows/amd64) → ${forja_dir}/chisel_windows_amd64.exe"
    else
        _err "forja: chisel (windows/amd64) — exe not found in zip"
    fi
    rm -rf "${tmp}"
}

_ligolo_win() {
    local forja_dir="${Z1_FORJA}/ligolo"
    mkdir -p "${forja_dir}"
    _apt unzip
    local version
    version=$(_gh_version "nicocha30/ligolo-ng")
    if [[ -z "${version}" ]]; then
        _err "ligolo-ng (windows): could not get release version"
        return
    fi
    local base="https://github.com/nicocha30/ligolo-ng/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)
    curl -sfL -o "${tmp}/agent_windows.zip" "${base}/ligolo-ng_agent_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/agent_win"
    unzip -q "${tmp}/agent_windows.zip" -d "${tmp}/agent_win" 2>/dev/null
    local agent_win
    agent_win=$(find "${tmp}/agent_win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${agent_win}" ]]; then
        cp "${agent_win}" "${forja_dir}/ligolo-agent_windows_amd64.exe"
        _ok "forja: ligolo-agent (windows/amd64) → ${forja_dir}/ligolo-agent_windows_amd64.exe"
    else
        _err "forja: ligolo-agent (windows/amd64) — exe not found in zip"
    fi
    rm -rf "${tmp:?}"/*
    curl -sfL -o "${tmp}/proxy_windows.zip" "${base}/ligolo-ng_proxy_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/proxy_win"
    unzip -q "${tmp}/proxy_windows.zip" -d "${tmp}/proxy_win" 2>/dev/null
    local proxy_win
    proxy_win=$(find "${tmp}/proxy_win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${proxy_win}" ]]; then
        cp "${proxy_win}" "${forja_dir}/ligolo-proxy_windows_amd64.exe"
        _ok "forja: ligolo-proxy (windows/amd64) → ${forja_dir}/ligolo-proxy_windows_amd64.exe"
    else
        _err "forja: ligolo-proxy (windows/amd64) — exe not found in zip"
    fi
    rm -rf "${tmp}"
}

_deploy() {
    _linpeas
    _linenum
    _pspy
    _lse
    _linux_exploit_suggester
    _winpeas
    _powerup
    _watson
    _sharpbypassuac
    _privesc_check
    _mimikatz
    _ghostpack
    _rubeus
    _seatbelt
    _sharpup
    _sharpsqlpwn
    _sharpview
    _sharpshooter
    _sharpapplocker
    _krbrelayup
    _certify
    _forgecert
    _whisker
    _passthecert
    _standin
    _adcspwn
    _runascs
    _adrecon
    _adsearch
    _sharpdpapi
    _lazagne
    _safetykatz
    _sqlrecon
    _powerupsql
    _sharphound
    _ncwin
    _sharpwmi
    _sharpcom
    _sharpmove
    _sharpnamedpipepth
    _inveigh
    _sharpsccm
    _chisel_win
    _ligolo_win
    _plink
    _putty
    _invoke_obfuscation
}
