#!/usr/bin/env bash
set -Eeuo pipefail

readonly PREFIX_TEMPLATE="/opt/kakaotalk/prefix-template"
readonly SETUP_EXE="/opt/kakaotalk/KakaoTalk_Setup.exe"
readonly LAUNCHER="$HOME/.local/bin/kakaotalk-wine"
readonly WINE_BIN="/opt/wine-staging/bin/wine"
readonly WINESERVER_BIN="/opt/wine-staging/bin/wineserver"

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine-kakaotalk}"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all}"

# 호스트의 NVIDIA GLVND 선택은 컨테이너 Mesa 구성에 맞지 않는다.
unset __EGL_VENDOR_LIBRARY_FILENAMES __GLX_VENDOR_LIBRARY_NAME

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

validate_prefix_path() {
    case "$WINEPREFIX" in
        /*) ;;
        *) die "WINEPREFIX는 절대 경로여야 합니다: $WINEPREFIX" ;;
    esac
    case "$WINEPREFIX" in
        /|"$HOME") die "안전하지 않은 WINEPREFIX입니다: $WINEPREFIX" ;;
    esac
}

initialize_data_prefix() {
    mkdir -p "$WINEPREFIX"
    if [ -f "$WINEPREFIX/system.reg" ]; then
        return
    fi
    if find "$WINEPREFIX" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
        die "$WINEPREFIX가 비어 있지 않지만 Wine prefix가 아닙니다. 데이터를 직접 확인하세요."
    fi
    printf '초기 KakaoTalk prefix를 %s에 복사합니다.\n' "$WINEPREFIX"
    cp -a "$PREFIX_TEMPLATE/." "$WINEPREFIX/"
}

update_kakaotalk() {
    initialize_data_prefix
    printf '기존 사용자 데이터를 유지하며 KakaoTalk 본체를 업데이트합니다.\n'
    WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winemenubuilder.exe=d" \
        "$WINE_BIN" "$SETUP_EXE" /S
    "$WINESERVER_BIN" -w
}

validate_prefix_path

case "${1:-run}" in
    run)
        initialize_data_prefix
        export KAKAOTALK_PREFIX="$WINEPREFIX"
        exec "$LAUNCHER" "${@:2}"
        ;;
    update)
        update_kakaotalk
        ;;
    shell)
        initialize_data_prefix
        exec bash
        ;;
    *)
        die "지원하지 않는 명령: $1 (run|update|shell)"
        ;;
esac
