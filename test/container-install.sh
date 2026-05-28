#!/usr/bin/env bash
set -Eeuo pipefail

export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-x64"
export KAKAOTALK_CACHE="$HOME/.cache/kakaotalk-installer"
export WINE_RUNNERS_DIR="$HOME/.local/share/wine-runners"
export WINE_RUNNER="$WINE_RUNNERS_DIR/wine-11.9-amd64-wow64"
export WINE_TARBALL="$KAKAOTALK_CACHE/wine-11.9-amd64-wow64.tar.xz"
export WINE_TARBALL_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.9/wine-11.9-amd64-wow64.tar.xz"
export WINE_TARBALL_SHA256="92e1c1a829752ae20b0f4a2d00f8c234f9ad7b0dec3c533797d9f9f9e71cbed2"
export KAKAOTALK_SETUP="$KAKAOTALK_CACHE/KakaoTalk_Setup.exe"
export KAKAOTALK_SETUP_URL="https://app-pc.kakaocdn.net/talk/win32/KakaoTalk_Setup.exe"

export WINEPREFIX="$KAKAOTALK_PREFIX"
export WINE="$WINE_RUNNER/bin/wine"
export WINESERVER="$WINE_RUNNER/bin/wineserver"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:-fixme-all,err-winediag}"

mkdir -p "$KAKAOTALK_CACHE" "$WINE_RUNNERS_DIR"

WINE_RUNNER_OK="FAIL"
WINE_PREFIX_OK="FAIL"
WINETRICKS_OK="FAIL"
WINETRICKS_MISSING=""
LAUNCHER_OK="FAIL"
KAKAO_INSTALL_OK="FAIL"

echo "==> [3.3] Wine 11.9 runner 설치"
if [ ! -x "$WINE_RUNNER/bin/wine" ]; then
    if [ ! -f "$WINE_TARBALL" ]; then
        curl -L --fail --output "$WINE_TARBALL" "$WINE_TARBALL_URL"
    fi
    echo "$WINE_TARBALL_SHA256  $WINE_TARBALL" | sha256sum -c -
    tar -C "$WINE_RUNNERS_DIR" -xf "$WINE_TARBALL"
fi
"$WINE_RUNNER/bin/wine" --version && WINE_RUNNER_OK="OK"

echo "==> [3.4] Wine prefix 초기화 + winetricks 의존성 설치"
"$WINE_RUNNER/bin/wineboot" -u
"$WINE_RUNNER/bin/winecfg" -v win10
[ -d "$WINEPREFIX/drive_c" ] && WINE_PREFIX_OK="OK"

winetricks -q cjkfonts gdiplus riched20 vcrun2019 || true
"$WINE_RUNNER/bin/wineboot" -u

WT_LOG="$WINEPREFIX/winetricks.log"
if [ -f "$WT_LOG" ]; then
    INSTALLED="$(cat "$WT_LOG")"
else
    INSTALLED="$(winetricks list-installed 2>&1 || true)"
fi
for verb in cjkfonts gdiplus riched20 vcrun2019; do
    echo "$INSTALLED" | grep -qw "$verb" || WINETRICKS_MISSING="$WINETRICKS_MISSING $verb"
done
[ -z "$WINETRICKS_MISSING" ] && WINETRICKS_OK="OK"

if [ ! -f "$KAKAOTALK_SETUP" ]; then
    echo "==> [3.5] KakaoTalk installer가 캐시에 없음 — 자동 다운로드 시도"
    curl -L --fail --output "$KAKAOTALK_SETUP" "$KAKAOTALK_SETUP_URL" || \
        echo "    WARN: 자동 다운로드 실패 (네트워크 또는 카카오 CDN 변경)"
fi

if [ -f "$KAKAOTALK_SETUP" ]; then
    echo "==> [3.5] KakaoTalk 본체 설치 (silent)"
    echo "    installer SHA256: $(sha256sum "$KAKAOTALK_SETUP" | awk '{print $1}')"
    "$WINE_RUNNER/bin/winecfg" -v win10 || true
    "$WINE" "$KAKAOTALK_SETUP" /S || echo "    WARN: installer 비0 종료 (카카오 서버 정책 거절 가능성)"
    [ -f "$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe" ] && KAKAO_INSTALL_OK="OK"
else
    echo "==> [3.5] KakaoTalk installer 없음 — 본체 설치 건너뜀"
fi

echo "==> [3.6] 런처 생성"
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/kakaotalk-wine" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine-kakaotalk-x64}"
exec "$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64/bin/wine" "$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe" "$@"
EOF
chmod +x "$HOME/.local/bin/kakaotalk-wine"
[ -x "$HOME/.local/bin/kakaotalk-wine" ] && LAUNCHER_OK="OK"

echo ""
echo "=============================================================="
echo "==> 검증 결과 (INSTALL.md 3.1·3.3·3.4·3.5·3.6)"
echo "    Wine 11.9 runner:    $WINE_RUNNER_OK"
echo "    Wine prefix(win10):  $WINE_PREFIX_OK"
if [ "$WINETRICKS_OK" = "OK" ]; then
    echo "    winetricks 4종:      OK"
else
    echo "    winetricks 4종:      FAIL (누락:$WINETRICKS_MISSING)"
fi
echo "    런처 스크립트:        $LAUNCHER_OK"
echo "    KakaoTalk 본체 설치:  $KAKAO_INSTALL_OK"
echo "=============================================================="

if [ "$WINE_RUNNER_OK $WINE_PREFIX_OK $WINETRICKS_OK $LAUNCHER_OK" != "OK OK OK OK" ]; then
    echo "==> 절차 본체 일부 FAIL — INSTALL.md를 점검하세요"
    exit 1
fi

if [ "$KAKAO_INSTALL_OK" = "OK" ]; then
    echo "==> [4.1] KakaoTalk GUI 실행 (호스트 디스플레이에 표시되어야 함)"
    exec "$HOME/.local/bin/kakaotalk-wine"
fi

echo "==> 절차 본체 통과. KakaoTalk 본체는 설치되지 않아 GUI 생략."
exit 0
