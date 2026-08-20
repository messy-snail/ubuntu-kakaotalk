#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export KAKAOTALK_PREFIX="${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}"
export KAKAOTALK_CACHE="${KAKAOTALK_CACHE:-$HOME/.cache/kakaotalk-installer}"
export KAKAOTALK_INSTALL_DESKTOP="${KAKAOTALK_INSTALL_DESKTOP:-1}"

readonly KAKAOTALK_TOOLKIT_VERSION="0.0.0"

readonly WINE_BIN="/opt/wine-staging/bin/wine"
readonly WINEBOOT_BIN="/opt/wine-staging/bin/wineboot"
readonly WINECFG_BIN="/opt/wine-staging/bin/winecfg"
readonly WINESERVER_BIN="/opt/wine-staging/bin/wineserver"
readonly KAKAOTALK_SETUP_URL="https://app-pc.kakaocdn.net/talk/win32/KakaoTalk_Setup.exe"
readonly KAKAOTALK_SETUP="$KAKAOTALK_CACHE/KakaoTalk_Setup.exe"
readonly WINE_CACHE="$HOME/.cache/wine"

readonly GECKO_X86_NAME="wine-gecko-2.47.4-x86.msi"
readonly GECKO_X86_URL="https://dl.winehq.org/wine/wine-gecko/2.47.4/$GECKO_X86_NAME"
readonly GECKO_X86_SHA256="26cecc47706b091908f7f814bddb074c61beb8063318e9efc5a7f789857793d6"
readonly GECKO_X64_NAME="wine-gecko-2.47.4-x86_64.msi"
readonly GECKO_X64_URL="https://dl.winehq.org/wine/wine-gecko/2.47.4/$GECKO_X64_NAME"
readonly GECKO_X64_SHA256="e590b7d988a32d6aa4cf1d8aa3aa3d33766fdd4cf4c89c2dcc2095ecb28d066f"
readonly MONO_NAME="wine-mono-11.2.0-x86.msi"
readonly MONO_URL="https://dl.winehq.org/wine/wine-mono/11.2.0/$MONO_NAME"
readonly MONO_SHA256="b4525679e7da30d4658ceb85739cbc55c771791054abbb4b3152fe96ded0b897"

export WINEPREFIX="$KAKAOTALK_PREFIX"
export WINEARCH=win64
export WINE="$WINE_BIN"
export WINESERVER="$WINESERVER_BIN"
export WINEDEBUG="${WINEDEBUG:--all}"
export PATH="/opt/wine-staging/bin:$PATH"

log() {
    printf '\n==> %s\n' "$*"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

print_system_dependency_instructions() {
    cat >&2 <<'EOF'

Ubuntu 24.04에서 아래 명령을 직접 실행한 뒤 install.sh를 다시 실행하세요.
이 스크립트는 sudo 권한이나 시스템 패키지 상태를 자동으로 변경하지 않습니다.

  sudo apt update
  sudo apt install -y ca-certificates curl
  sudo dpkg --add-architecture i386
  sudo mkdir -pm755 /etc/apt/keyrings
  sudo curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
    -o /etc/apt/keyrings/winehq-archive.key
  sudo curl -fsSL \
    https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
    -o /etc/apt/sources.list.d/winehq-noble.sources
  sudo apt update
  sudo apt install --install-recommends winehq-staging
  sudo apt install -y winetricks curl ca-certificates fonts-nanum \
    fonts-nanum-extra fonts-noto-cjk python3 desktop-file-utils
EOF
}

check_system_dependencies() {
    local missing=()
    local command_name

    if [ "$(dpkg --print-architecture 2>/dev/null || true)" != "amd64" ]; then
        missing+=("amd64 Ubuntu 환경")
    fi
    if [ ! -f /etc/os-release ] \
        || ! grep -Eq '^(VERSION_CODENAME|UBUNTU_CODENAME)=noble$' /etc/os-release; then
        missing+=("Ubuntu 24.04 (noble)")
    fi
    if ! dpkg --print-foreign-architectures 2>/dev/null | grep -qx i386; then
        missing+=("i386 architecture")
    fi
    if [ ! -x "$WINE_BIN" ]; then
        missing+=("WineHQ staging")
    fi
    for command_name in curl sha256sum timeout winetricks python3; do
        command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
    done
    if [ ! -f /usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf ]; then
        missing+=("fonts-nanum")
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        printf '필수 시스템 의존성이 없습니다: %s\n' "${missing[*]}" >&2
        print_system_dependency_instructions
        exit 2
    fi
}

validate_configuration() {
    case "$KAKAOTALK_PREFIX" in
        /*) ;;
        *) die "KAKAOTALK_PREFIX는 절대 경로여야 합니다: $KAKAOTALK_PREFIX" ;;
    esac
    case "$KAKAOTALK_PREFIX" in
        /|"$HOME") die "안전하지 않은 KAKAOTALK_PREFIX입니다: $KAKAOTALK_PREFIX" ;;
    esac
    case "$KAKAOTALK_CACHE" in
        /*) ;;
        *) die "KAKAOTALK_CACHE는 절대 경로여야 합니다: $KAKAOTALK_CACHE" ;;
    esac
    case "$KAKAOTALK_CACHE" in
        /|"$HOME") die "안전하지 않은 KAKAOTALK_CACHE입니다: $KAKAOTALK_CACHE" ;;
    esac
    case "$KAKAOTALK_INSTALL_DESKTOP" in
        0|1) ;;
        *) die "KAKAOTALK_INSTALL_DESKTOP은 0 또는 1이어야 합니다." ;;
    esac
}

download_verified() {
    local name="$1"
    local url="$2"
    local expected_sha256="$3"
    local destination="$WINE_CACHE/$name"
    local partial="$destination.part.$$"

    if [ -f "$destination" ]; then
        if printf '%s  %s\n' "$expected_sha256" "$destination" | sha256sum -c - >/dev/null; then
            printf '    cache hit: %s\n' "$name"
            return
        fi
        mv "$destination" "$destination.invalid.$(date +%Y%m%d-%H%M%S)"
        printf '    기존 파일의 checksum이 달라 보존 후 다시 받습니다: %s\n' "$name"
    fi

    curl -L --fail --retry 3 --output "$partial" "$url"
    printf '%s  %s\n' "$expected_sha256" "$partial" | sha256sum -c - >/dev/null \
        || die "$name checksum 검증 실패: $partial"
    mv "$partial" "$destination"
}

prefetch_wine_runtimes() {
    log "Wine Gecko/Mono 프리페치"
    mkdir -p "$WINE_CACHE"
    download_verified "$GECKO_X86_NAME" "$GECKO_X86_URL" "$GECKO_X86_SHA256"
    download_verified "$GECKO_X64_NAME" "$GECKO_X64_URL" "$GECKO_X64_SHA256"
    download_verified "$MONO_NAME" "$MONO_URL" "$MONO_SHA256"
}

check_forbidden_prefix() {
    local log_file="$WINEPREFIX/winetricks.log"
    local forbidden_re='^(gdiplus|riched20|vcrun2019)$'
    local dll

    [ -f "$WINEPREFIX/system.reg" ] || return 0

    if [ -f "$log_file" ] && grep -Eq "$forbidden_re" "$log_file"; then
        die "$WINEPREFIX에 금지된 winetricks DLL verb가 설치되어 있습니다. 이 prefix를 수정하지 말고 KAKAOTALK_PREFIX를 새 경로로 지정하세요."
    fi

    for dll in \
        "$WINEPREFIX/drive_c/windows/system32/mfc140u.dll" \
        "$WINEPREFIX/drive_c/windows/syswow64/mfc140u.dll"; do
        if [ -f "$dll" ]; then
            die "$WINEPREFIX에서 native mfc140u.dll을 발견했습니다. 새 prefix를 사용하세요: $dll"
        fi
    done
}

initialize_prefix() {
    local is_new_prefix=0

    log "Wine prefix 생성 및 Windows 10 설정"
    [ -f "$WINEPREFIX/system.reg" ] || is_new_prefix=1
    mkdir -p "$WINEPREFIX"
    if [ "$is_new_prefix" -eq 1 ]; then
        "$WINEBOOT_BIN" -u
    fi
    "$WINECFG_BIN" -v win10
    "$WINESERVER_BIN" -w

    log "한글 글꼴 설치 (cjkfonts만 사용)"
    if [ -f "$WINEPREFIX/winetricks.log" ] \
        && grep -qx cjkfonts "$WINEPREFIX/winetricks.log"; then
        echo "    cjkfonts already installed, skipping"
    else
        winetricks -q cjkfonts
    fi
    "$WINECFG_BIN" -v win10
    "$WINESERVER_BIN" -w
}

add_font_link() {
    local font_name="$1"
    "$WINE_BIN" reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontLink\SystemLink' \
        /v "$font_name" /t REG_MULTI_SZ /d 'NanumBarunGothic.ttf,NanumBarunGothic' /f >/dev/null
}

configure_fonts() {
    local windows_fonts="$WINEPREFIX/drive_c/windows/Fonts"
    local replacements='HKCU\Software\Wine\Fonts\Replacements'
    local substitutes='HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes'
    local fonts='HKLM\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    local name

    log "Nanum 글꼴 복사 및 Wine 글꼴 매핑"
    mkdir -p "$windows_fonts"
    install -m 0644 /usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf "$windows_fonts/"
    install -m 0644 /usr/share/fonts/truetype/nanum/NanumGothic.ttf "$windows_fonts/"
    install -m 0644 /usr/share/fonts/truetype/nanum/NanumMyeongjo.ttf "$windows_fonts/"

    "$WINE_BIN" reg add "$fonts" /v 'NanumBarunGothic (TrueType)' /d 'NanumBarunGothic.ttf' /f >/dev/null
    "$WINE_BIN" reg add "$fonts" /v 'NanumGothic (TrueType)' /d 'NanumGothic.ttf' /f >/dev/null
    "$WINE_BIN" reg add "$fonts" /v 'NanumMyeongjo (TrueType)' /d 'NanumMyeongjo.ttf' /f >/dev/null

    for name in 'MS Shell Dlg' 'MS Shell Dlg 2'; do
        "$WINE_BIN" reg add "$substitutes" /v "$name" /d 'NanumBarunGothic' /f >/dev/null
    done
    for name in 'Segoe UI' 'Malgun Gothic' '맑은 고딕'; do
        "$WINE_BIN" reg add "$replacements" /v "$name" /d 'NanumBarunGothic' /f >/dev/null
    done
    "$WINE_BIN" reg add "$replacements" /v '나눔고딕' /d 'NanumGothic' /f >/dev/null

    for name in 'Arial' 'Courier New' 'Lucida Sans Unicode' 'Microsoft Sans Serif' \
        'MS Shell Dlg' 'MS Shell Dlg 2' 'Segoe UI' 'Tahoma' 'Times New Roman'; do
        add_font_link "$name"
    done
    timeout 10 "$WINESERVER_BIN" -w 2>/dev/null || true
}

find_kakaotalk_exe() {
    local candidate
    for candidate in \
        "$WINEPREFIX/drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe" \
        "$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe"; do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

install_kakaotalk() {
    local kakao_exe

    log "KakaoTalk 설치 프로그램 준비"
    mkdir -p "$KAKAOTALK_CACHE"
    if [ ! -f "$KAKAOTALK_SETUP" ]; then
        curl -L --fail --retry 3 --output "$KAKAOTALK_SETUP.part" "$KAKAOTALK_SETUP_URL"
        mv "$KAKAOTALK_SETUP.part" "$KAKAOTALK_SETUP"
    fi
    [ -s "$KAKAOTALK_SETUP" ] || die "KakaoTalk installer가 비어 있습니다: $KAKAOTALK_SETUP"
    [ "$(LC_ALL=C dd if="$KAKAOTALK_SETUP" bs=2 count=1 status=none)" = "MZ" ] \
        || die "KakaoTalk installer가 Windows PE 파일이 아닙니다: $KAKAOTALK_SETUP"
    printf '    installer SHA256: '
    sha256sum "$KAKAOTALK_SETUP" | awk '{print $1}'

    if kakao_exe="$(find_kakaotalk_exe)"; then
        printf '    이미 설치됨: %s\n' "$kakao_exe"
        return
    fi

    log "KakaoTalk 무인 설치"
    WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winemenubuilder.exe=d" \
        "$WINE_BIN" "$KAKAOTALK_SETUP" /S
    "$WINESERVER_BIN" -w
    find_kakaotalk_exe >/dev/null || die "KakaoTalk.exe가 설치되지 않았습니다. DISPLAY와 installer 유효성을 확인하세요."
}

install_launcher() {
    local launcher_dir="$HOME/.local/bin"
    local launcher="$launcher_dir/kakaotalk-wine"

    log "호스트 런처 생성"
    mkdir -p "$launcher_dir"
    cat > "$launcher" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

export KAKAOTALK_PREFIX="${KAKAOTALK_PREFIX:-${WINEPREFIX:-$HOME/.wine-kakaotalk-clean}}"
export WINEPREFIX="$KAKAOTALK_PREFIX"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all}"

readonly WINE_BIN="/opt/wine-staging/bin/wine"
readonly WINESERVER_BIN="/opt/wine-staging/bin/wineserver"

if [ -r /usr/share/glvnd/egl_vendor.d/10_nvidia.json ]; then
    export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
fi

KAKAOTALK_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe"
if [ ! -f "$KAKAOTALK_EXE" ]; then
    KAKAOTALK_EXE="$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe"
fi
[ -f "$KAKAOTALK_EXE" ] || {
    printf 'KakaoTalk.exe를 찾을 수 없습니다: %s\n' "$WINEPREFIX" >&2
    exit 1
}

for attempt in 1 2 3; do
    started_at="$(date +%s)"
    if "$WINE_BIN" "$KAKAOTALK_EXE" "$@"; then
        exit 0
    else
        status=$?
    fi
    elapsed=$(( $(date +%s) - started_at ))
    if [ "$attempt" -ge 3 ] || [ "$elapsed" -ge 15 ]; then
        exit "$status"
    fi
    printf 'KakaoTalk이 시작 직후 종료되었습니다(%d초, status=%d). 재시도 %d/3\n' \
        "$elapsed" "$status" "$((attempt + 1))" >&2
    timeout 5 "$WINESERVER_BIN" -w 2>/dev/null || true
    sleep 2
done
EOF
    chmod +x "$launcher"
}

install_desktop_entries() {
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local applications="$data_home/applications"
    local icon="$data_home/icons/kakaotalk-wine.ico"
    local launcher="$HOME/.local/bin/kakaotalk-wine"
    local kakao_exe

    [ "$KAKAOTALK_INSTALL_DESKTOP" = "1" ] || return 0
    kakao_exe="$(find_kakaotalk_exe)"

    log "아이콘 및 데스크톱 엔트리 설치"
    mkdir -p "$applications" "$(dirname "$icon")"
    python3 "$SCRIPT_DIR/tools/extract-exe-icon.py" "$kakao_exe" "$icon"

    cat > "$applications/kakaotalk-wine.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=KakaoTalk
Comment=KakaoTalk for Windows via WineHQ staging
Exec=$launcher
Icon=$icon
Terminal=false
Categories=Network;Chat;
StartupNotify=true
StartupWMClass=kakaotalk.exe
EOF

    cat > "$applications/kakaotalk-wine-protocol.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=KakaoTalk (Wine protocol handler)
Exec=$launcher %u
Icon=$icon
Terminal=false
NoDisplay=true
MimeType=x-scheme-handler/kakaoopen;x-scheme-handler/kakaotalk;
StartupNotify=true
EOF

    if command -v xdg-mime >/dev/null 2>&1; then
        xdg-mime default kakaotalk-wine-protocol.desktop x-scheme-handler/kakaoopen || true
        xdg-mime default kakaotalk-wine-protocol.desktop x-scheme-handler/kakaotalk || true
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$applications" >/dev/null 2>&1 || true
    fi
}

# self_check는 "조건 && [OK] 출력 || { [FAIL] 출력; 카운트 }" 패턴을 의도적으로 쓴다.
# echo가 실패하는 경우는 없으므로 SC2015의 A && B || C 경고는 여기서 오탐이다.
# shellcheck disable=SC2015
self_check() {
    local failures=0
    local kakao_exe=""
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

    log "설치 자체 점검"
    "$WINE_BIN" --version || failures=$((failures + 1))

    grep -q '"ProductName"="Microsoft Windows 10"' "$WINEPREFIX/system.reg" \
        && echo "    [OK] Windows 10 prefix" \
        || { echo "    [FAIL] Windows 10 prefix"; failures=$((failures + 1)); }

    if [ -f "$WINEPREFIX/winetricks.log" ] \
        && grep -Eq '^(gdiplus|riched20|vcrun2019)$' "$WINEPREFIX/winetricks.log"; then
        echo "    [FAIL] 금지된 winetricks DLL verb"
        failures=$((failures + 1))
    else
        echo "    [OK] 금지된 winetricks DLL verb 없음"
    fi

    grep -qx cjkfonts "$WINEPREFIX/winetricks.log" \
        && echo "    [OK] cjkfonts" \
        || { echo "    [FAIL] cjkfonts"; failures=$((failures + 1)); }

    [ -f "$WINEPREFIX/drive_c/windows/Fonts/NanumBarunGothic.ttf" ] \
        && echo "    [OK] NanumBarunGothic" \
        || { echo "    [FAIL] NanumBarunGothic"; failures=$((failures + 1)); }
    grep -q '"MS Shell Dlg"="NanumBarunGothic"' "$WINEPREFIX/system.reg" \
        && echo "    [OK] 글꼴 레지스트리" \
        || { echo "    [FAIL] 글꼴 레지스트리"; failures=$((failures + 1)); }

    if kakao_exe="$(find_kakaotalk_exe)"; then
        echo "    [OK] $kakao_exe"
    else
        echo "    [FAIL] KakaoTalk.exe"
        failures=$((failures + 1))
    fi

    [ -x "$HOME/.local/bin/kakaotalk-wine" ] \
        && grep -Fq 'WINE_BIN="/opt/wine-staging/bin/wine"' "$HOME/.local/bin/kakaotalk-wine" \
        && echo "    [OK] WineHQ staging 호스트 런처" \
        || { echo "    [FAIL] 호스트 런처"; failures=$((failures + 1)); }

    if [ "$KAKAOTALK_INSTALL_DESKTOP" = "1" ]; then
        [ -f "$data_home/applications/kakaotalk-wine.desktop" ] \
            && [ -f "$data_home/applications/kakaotalk-wine-protocol.desktop" ] \
            && [ -f "$data_home/icons/kakaotalk-wine.ico" ] \
            && grep -Fq "Exec=$HOME/.local/bin/kakaotalk-wine" \
                "$data_home/applications/kakaotalk-wine.desktop" \
            && echo "    [OK] 데스크톱 통합" \
            || { echo "    [FAIL] 데스크톱 통합"; failures=$((failures + 1)); }
    fi

    [ "$failures" -eq 0 ] || die "자체 점검에서 $failures개 항목이 실패했습니다."
}

main() {
    log "ubuntu-kakaotalk v$KAKAOTALK_TOOLKIT_VERSION"
    validate_configuration
    check_system_dependencies
    check_forbidden_prefix
    prefetch_wine_runtimes
    initialize_prefix
    configure_fonts
    install_kakaotalk
    install_launcher
    install_desktop_entries
    self_check

    cat <<EOF

설치 완료.

실행:
  KAKAOTALK_PREFIX="$KAKAOTALK_PREFIX" "$HOME/.local/bin/kakaotalk-wine"

카카오톡에서 반드시 Settings → Display → Font → 나눔고딕을 선택하세요.
이 앱 설정까지 해야 채팅 입력창의 한글이 정상 표시됩니다.
EOF
}

main "$@"
