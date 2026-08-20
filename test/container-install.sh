#!/usr/bin/env bash
set -Eeuo pipefail

export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-verify"
export KAKAOTALK_CACHE="$HOME/.cache/kakaotalk-installer"
export KAKAOTALK_INSTALL_DESKTOP=0

readonly INSTALLER="/usr/local/lib/kakaotalk/install.sh"

"$INSTALLER"

echo
echo "=============================================================="
echo "==> 컨테이너 회귀 검증 결과"

failures=0

check() {
    local label="$1"
    shift
    if "$@"; then
        printf '    %-34s OK\n' "$label"
    else
        printf '    %-34s FAIL\n' "$label"
        failures=$((failures + 1))
    fi
}

check "WineHQ staging" test -x /opt/wine-staging/bin/wine
check "Windows 10 prefix" grep -q '"ProductName"="Microsoft Windows 10"' "$KAKAOTALK_PREFIX/system.reg"
check "cjkfonts" grep -qx cjkfonts "$KAKAOTALK_PREFIX/winetricks.log"

if grep -Eq '^(gdiplus|riched20|vcrun2019)$' "$KAKAOTALK_PREFIX/winetricks.log"; then
    printf '    %-34s FAIL\n' "금지된 DLL verb 없음"
    failures=$((failures + 1))
else
    printf '    %-34s OK\n' "금지된 DLL verb 없음"
fi

check "NanumBarunGothic" test -f "$KAKAOTALK_PREFIX/drive_c/windows/Fonts/NanumBarunGothic.ttf"
check "Program Files (x86) 설치 경로" test -f \
    "$KAKAOTALK_PREFIX/drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe"
check "재시도 런처" test -x "$HOME/.local/bin/kakaotalk-wine"

echo "=============================================================="

[ "$failures" -eq 0 ] || {
    echo "==> $failures개 회귀 검사가 실패했습니다." >&2
    exit 1
}

echo "==> 정적 설치 검증 통과. KakaoTalk GUI를 실행합니다."
exec env KAKAOTALK_PREFIX="$KAKAOTALK_PREFIX" "$HOME/.local/bin/kakaotalk-wine"
