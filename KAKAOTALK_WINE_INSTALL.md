# KakaoTalk on Wine 설치 재현 절차

이 문서는 Codex, Claude 같은 에이전트가 Ubuntu 계열 PC에서 카카오톡 Windows 버전을 Wine으로 재설치할 때 그대로 따라 할 수 있도록 작성한 실행 절차다.

## 1. 검증된 기준 상태

- 검증 OS: Ubuntu 24.04.4 LTS, `amd64`, foreign architecture `i386`
- 검증된 KakaoTalk 버전: `26.4.0.5128`
- 시스템 Wine: `wine-9.0 (Ubuntu 9.0~repack-4build3)`
- 실제 실행 Wine: `wine-11.9` Kron4ek user-local runner
- Windows 호환성: Windows 10
- Windows 7 호환 모드는 기본값으로 쓰지 않는다.

이번 DLL 오류는 Ubuntu 기본 Wine 9.0에서 재현되었고, 홈 디렉터리에 고정 설치한 Wine 11.9 runner로 해결했다. 따라서 다른 PC에서도 시스템 Wine에 의존하지 말고 아래 runner를 직접 호출한다.

## 2. 고정 경로와 파일

에이전트는 모든 명령을 `$HOME` 기준으로 실행한다. `/home/<user>` 같은 특정 사용자 경로를 하드코딩하지 않는다.

```bash
export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-x64"
export KAKAOTALK_CACHE="$HOME/.cache/kakaotalk-installer"
export WINE_RUNNERS_DIR="$HOME/.local/share/wine-runners"
export WINE_RUNNER="$WINE_RUNNERS_DIR/wine-11.9-amd64-wow64"
export WINE_TARBALL="$KAKAOTALK_CACHE/wine-11.9-amd64-wow64.tar.xz"
export KAKAOTALK_SETUP="$KAKAOTALK_CACHE/KakaoTalk_Setup.exe"

export WINE_TARBALL_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.9/wine-11.9-amd64-wow64.tar.xz"
export WINE_TARBALL_SHA256="92e1c1a829752ae20b0f4a2d00f8c234f9ad7b0dec3c533797d9f9f9e71cbed2"
export KAKAOTALK_SETUP_URL="https://app-pc.kakaocdn.net/talk/win32/KakaoTalk_Setup.exe"
```

참고 링크:

- KakaoTalk 공식 서비스 페이지: <https://www.kakaocorp.com/page/service/service/kakaotalk?lang=en>
- KakaoTalk Windows installer CDN: <https://app-pc.kakaocdn.net/talk/win32/KakaoTalk_Setup.exe>
- Kron4ek Wine Builds 11.9: <https://github.com/Kron4ek/Wine-Builds/releases/tag/11.9>

## 3. 설치 절차

### 3.1 사전 패키지 설치

`sudo`가 필요한 단계다. 에이전트는 사용자 승인 없이 비밀번호를 요구하지 않는다.

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y wine winetricks curl tar xz-utils ca-certificates cabextract p7zip-full unzip fonts-noto-cjk
```

설치 후 확인:

```bash
dpkg --print-architecture
dpkg --print-foreign-architectures
which wine winetricks curl tar sha256sum
```

기대값:

- 기본 architecture: `amd64`
- foreign architecture에 `i386` 포함
- `wine`, `winetricks`, `curl`, `tar`, `sha256sum` 명령 존재

### 3.2 기존 설치 백업

기존 prefix나 런처가 있으면 삭제하지 말고 먼저 백업한다.

```bash
set -Eeuo pipefail

export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-x64"
export BACKUP_DIR="$HOME/kakaotalk-wine-backups/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

if [ -d "$KAKAOTALK_PREFIX" ]; then
  cp -a "$KAKAOTALK_PREFIX" "$BACKUP_DIR/"
fi

if [ -f "$HOME/.local/bin/kakaotalk-wine" ]; then
  cp -a "$HOME/.local/bin/kakaotalk-wine" "$BACKUP_DIR/"
fi

if [ -f "$HOME/.local/share/applications/kakaotalk-wine.desktop" ]; then
  cp -a "$HOME/.local/share/applications/kakaotalk-wine.desktop" "$BACKUP_DIR/"
fi

du -sh "$BACKUP_DIR"
```

깨끗한 재설치가 필요하면 백업 후 prefix를 이동한다. `rm -rf`는 쓰지 않는다.

```bash
if [ -d "$KAKAOTALK_PREFIX" ]; then
  mv "$KAKAOTALK_PREFIX" "$BACKUP_DIR/.wine-kakaotalk-x64.moved"
fi
```

### 3.3 Wine 11.9 runner 설치

```bash
set -Eeuo pipefail

export KAKAOTALK_CACHE="$HOME/.cache/kakaotalk-installer"
export WINE_RUNNERS_DIR="$HOME/.local/share/wine-runners"
export WINE_RUNNER="$WINE_RUNNERS_DIR/wine-11.9-amd64-wow64"
export WINE_TARBALL="$KAKAOTALK_CACHE/wine-11.9-amd64-wow64.tar.xz"
export WINE_TARBALL_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.9/wine-11.9-amd64-wow64.tar.xz"
export WINE_TARBALL_SHA256="92e1c1a829752ae20b0f4a2d00f8c234f9ad7b0dec3c533797d9f9f9e71cbed2"

mkdir -p "$KAKAOTALK_CACHE" "$WINE_RUNNERS_DIR"

curl -L --fail --output "$WINE_TARBALL" "$WINE_TARBALL_URL"
echo "$WINE_TARBALL_SHA256  $WINE_TARBALL" | sha256sum -c -
tar -C "$WINE_RUNNERS_DIR" -xf "$WINE_TARBALL"

"$WINE_RUNNER/bin/wine" --version
```

기대값:

```text
wine-11.9
```

### 3.4 Wine prefix 초기화와 의존성 설치

`winetricks`가 시스템 Wine으로 빠지지 않도록 `WINE`과 `WINESERVER`를 함께 고정한다.

```bash
set -Eeuo pipefail

export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-x64"
export WINE_RUNNER="$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64"
export WINEPREFIX="$KAKAOTALK_PREFIX"
export WINE="$WINE_RUNNER/bin/wine"
export WINESERVER="$WINE_RUNNER/bin/wineserver"
export WINEARCH=win64

"$WINE_RUNNER/bin/wineboot" -u
"$WINE_RUNNER/bin/winecfg" -v win10

winetricks -q cjkfonts gdiplus riched20 vcrun2019

# 중요: winetricks(특히 vcrun2019)는 설치 도중 prefix의 Windows 버전을
# win7(=6.1 / build 7601)로 되돌리고 그대로 둔다. KakaoTalk 26.x는
# Windows 7/8/8.1을 거부하므로(공식 지원 종료, 2024-04 / 3.8.0까지),
# winetricks 다음에 반드시 win10으로 다시 고정한다. 이 한 줄이 빠지면
# 3.5 설치 단계에서 "Unable to install this version of KakaoTalk on your PC"
# 오류 창이 뜨고 설치가 중단된다.
"$WINE_RUNNER/bin/winecfg" -v win10
"$WINE_RUNNER/bin/wineboot" -u

# Windows 버전이 실제로 win10인지 검증한다.
# 정상: ProductName="Microsoft Windows 10", CurrentVersion 6.3 / CurrentBuild 19045
# 비정상(win7): CurrentVersion 6.1, CurrentBuild 7601, CSDVersion="Service Pack 1"
grep -m1 '"ProductName"="Microsoft Windows 10"' "$WINEPREFIX/system.reg" \
  && echo "winver OK: win10" \
  || { echo "winver FAIL: win10 아님 -> winecfg -v win10 재실행 필요"; exit 1; }
```

`vcrun2019` 설치 중 `ucrtbase.dll`이 이미 있다는 경고가 나올 수 있다. 명령이 0으로 끝나면 계속 진행한다.

> 검증 메모(2026-06-15 재현): `winecfg -v win10`을 winetricks **전에만** 실행하면
> winetricks가 prefix를 win7로 되돌려 3.5에서 설치가 거부된다. 위처럼 winetricks
> **뒤에** win10을 다시 고정한 후에야 설치가 성공했다.

### 3.5 KakaoTalk 설치

기본은 Kakao CDN의 Windows installer를 다운로드해 설치한다.

```bash
set -Eeuo pipefail

export KAKAOTALK_CACHE="$HOME/.cache/kakaotalk-installer"
export KAKAOTALK_SETUP="$KAKAOTALK_CACHE/KakaoTalk_Setup.exe"
export KAKAOTALK_SETUP_URL="https://app-pc.kakaocdn.net/talk/win32/KakaoTalk_Setup.exe"
export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-x64"
export WINE_RUNNER="$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64"
export WINEPREFIX="$KAKAOTALK_PREFIX"
export WINE="$WINE_RUNNER/bin/wine"
export WINESERVER="$WINE_RUNNER/bin/wineserver"
export WINEARCH=win64

mkdir -p "$KAKAOTALK_CACHE"
curl -L --fail --output "$KAKAOTALK_SETUP" "$KAKAOTALK_SETUP_URL"

"$WINE" "$KAKAOTALK_SETUP" /S
```

현재 성공한 PC에 캐시된 installer 참고값:

```text
KakaoTalk_Setup.exe SHA256: 165e03160d9a1adb9a97f880219db361b9734088d248d3c0cea3f55b1c2117f7
```

Kakao CDN installer는 최신 버전으로 바뀔 수 있다. 위 SHA256은 이 PC의 성공 사례를 기록한 값이며, 다른 시점에 새로 다운로드한 installer에는 강제 적용하지 않는다. 완전히 같은 installer가 필요하면 이 파일을 원본 PC에서 복사한 뒤 SHA256을 확인한다.

`/S` silent install이 실패하거나 설치창이 필요한 경우에는 GUI 설치로 재시도한다.

```bash
"$WINE" "$KAKAOTALK_SETUP"
```

설치 단계 주의사항:

- 설치 프로그램은 GUI를 초기화하므로 **유효한 X 디스플레이**가 필요하다. `DISPLAY`가
  실제 살아 있는 디스플레이를 가리키는지 먼저 확인한다. (`:0`이 아니라 `:1`인 경우도 있다.)

  ```bash
  export DISPLAY="${DISPLAY:-:0}"
  timeout 5 xdpyinfo >/dev/null 2>&1 && echo "DISPLAY=$DISPLAY OK" \
    || echo "DISPLAY 도달 불가 -> 올바른 디스플레이(:0/:1 등)로 export 후 재시도"
  ```

- 설치 중 **"Unable to install this version of KakaoTalk on your PC. Please reinstall
  with the newly downloaded installation file"** 오류 창이 뜨면, 이것은 DLL 문제가 아니라
  **prefix의 Windows 버전이 win10이 아니라서**(주로 win7로 되돌아가 있음) installer가
  스스로 거부하는 것이다. 3.4의 win10 재고정 + 검증을 먼저 수행하고 다시 설치한다.
  (installer 버전 자체는 동일한 `26.4.0.5128`이어도 이 오류가 난다.)

### 3.6 런처 생성

이 런처가 핵심이다. `exec wine ...`처럼 시스템 Wine을 호출하면 DLL 오류가 재발할 수 있다.

```bash
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/kakaotalk-wine" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine-kakaotalk-x64}"
WINE="$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64/bin/wine"
# win64 prefix에 32-bit installer를 깔면 실제 설치 경로는 "Program Files (x86)"다.
# 두 경로를 모두 시도해 실제 존재하는 KakaoTalk.exe를 사용한다.
KT="$WINEPREFIX/drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe"
[ -f "$KT" ] || KT="$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe"
exec "$WINE" "$KT" "$@"
EOF

chmod +x "$HOME/.local/bin/kakaotalk-wine"
```

> 경로 메모: 이 PC의 win32 installer는 win64 prefix에서
> `drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe`에 설치됐다.
> 런처는 `Program Files (x86)`을 먼저 보고 없으면 `Program Files`로 폴백한다.

### 3.7 데스크톱 바로가기 생성

우리는 `.desktop`을 수동 생성하므로 Wine의 자동 아이콘 추출이 일어나지 않는다.
이때 `Icon=`이 설치돼 있지 않은 이름(예: 자동 생성용 `DDB7_KakaoTalk.0`)을 가리키면
런처에 **톱니(기어) 모양 기본 아이콘**이 뜬다. 따라서 먼저 KakaoTalk이 포함한 노란
앱 아이콘을 hicolor 테마에 `kakaotalk`이라는 이름으로 설치하고, `.desktop`에서는
`Icon=kakaotalk`을 쓴다.

```bash
KT="$HOME/.wine-kakaotalk-x64/drive_c/Program Files (x86)/Kakao/KakaoTalk"
# 노란색 카카오톡 앱 아이콘 원본 (회색 logout용 .ico가 아니라 이 PNG가 컬러 아이콘)
ICON_SRC="$KT/skin/default/image/2.0/x2.0/setting_img_talkappicon.png"

python3 - "$ICON_SRC" "$HOME/.local/share/icons/hicolor" <<'PY'
import sys, os
from PIL import Image
src, base = sys.argv[1], sys.argv[2]
master = Image.open(src).convert("RGBA")
for s in (16, 24, 32, 48, 64, 128, 256):
    d = os.path.join(base, f"{s}x{s}", "apps"); os.makedirs(d, exist_ok=True)
    master.resize((s, s), Image.LANCZOS).save(os.path.join(d, "kakaotalk.png"))
print("installed kakaotalk icon into", base)
PY

gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
```

`.desktop` 파일의 `Exec`는 shell variable을 확장하지 않으므로 생성 시점에 `$HOME`을 실제 경로로 풀어 쓴다.

```bash
mkdir -p "$HOME/.local/share/applications"

cat > "$HOME/.local/share/applications/kakaotalk-wine.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=KakaoTalk (Wine)
Icon=kakaotalk
Exec=$HOME/.local/bin/kakaotalk-wine
Terminal=false
Categories=Network;Chat;
StartupNotify=true
NoDisplay=true
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
```

이 파일은 보조 런처다. Super 검색에는 최종적으로 `KakaoTalk` 하나만 보이게 하기 위해 `NoDisplay=true`를 둔다.

### 3.8 Super 검색 중복 런처 정리

Wine installer가 자동으로 만든 desktop entry가 남아 있으면 Super 검색에 `KakaoTalk`과 `KakaoTalk (Wine)`이 같이 보일 수 있다. 특히 자동 생성 entry가 `wine-stable ... KakaoTalk.lnk`를 호출하면 DLL 오류가 재발한다.

최종 정책:

- `KakaoTalk`: 검색에 보이는 대표 항목
- `KakaoTalk (Wine)`: 보조 항목, `NoDisplay=true`로 숨김
- 두 항목 모두 실행 경로는 `$HOME/.local/bin/kakaotalk-wine`

```bash
mkdir -p "$HOME/.local/share/applications/wine/Programs"

cat > "$HOME/.local/share/applications/wine/Programs/KakaoTalk.desktop" <<EOF
[Desktop Entry]
Name=KakaoTalk
Exec=$HOME/.local/bin/kakaotalk-wine
Type=Application
StartupNotify=true
Path=$HOME/.wine-kakaotalk-x64/dosdevices/c:/Program Files (x86)/Kakao/KakaoTalk
Icon=kakaotalk
StartupWMClass=kakaotalk.exe
Categories=Network;Chat;
EOF

if [ -f "$HOME/.local/share/applications/kakaotalk-wine.desktop" ]; then
  grep -q "^NoDisplay=" "$HOME/.local/share/applications/kakaotalk-wine.desktop" \
    && sed -i "s/^NoDisplay=.*/NoDisplay=true/" "$HOME/.local/share/applications/kakaotalk-wine.desktop" \
    || printf "%s\n" "NoDisplay=true" >> "$HOME/.local/share/applications/kakaotalk-wine.desktop"
fi

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
```

검증:

```bash
grep -RIn --include="*.desktop" -E "Name=KakaoTalk|Name=KakaoTalk \(Wine\)|Exec=.*kakaotalk|Exec=.*wine-stable" "$HOME/.local/share/applications"
```

정상 상태:

- `KakaoTalk.desktop`의 `Exec`는 `$HOME/.local/bin/kakaotalk-wine`
- `kakaotalk-wine.desktop`에는 `NoDisplay=true`
- `wine-stable`을 호출하는 KakaoTalk desktop entry 없음

## 4. 실행과 검증

### 4.1 직접 실행

```bash
"$HOME/.local/bin/kakaotalk-wine" &
```

### 4.2 프로세스 확인

```bash
pgrep -af 'KakaoTalk|wineserver|wine'
```

정상 상태에서는 `KakaoTalk.exe`가 떠 있고, Wine server 경로가 다음 runner 아래로 잡힌다.

```text
$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64
```

### 4.3 런처 확인

```bash
sed -n '1,20p' "$HOME/.local/bin/kakaotalk-wine"
grep -RIn --include="*.desktop" -E "KakaoTalk|wine-stable|Exec=.*wine " "$HOME/.local/share/applications"
```

정상 런처는 다음 Wine을 직접 호출해야 한다.

```text
$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64/bin/wine
```

### 4.4 설치 버전 확인

```bash
grep -n 'LastCheckedVersion' "$HOME/.wine-kakaotalk-x64/user.reg" || true
grep -n 'DisplayName"="KakaoTalk"' "$HOME/.wine-kakaotalk-x64/system.reg" || true
```

이 PC에서 확인한 버전은 `26.4.0.5128`이다.

## 5. 장애 대응

### "Unable to install this version of KakaoTalk on your PC" (설치 거부)

3.5 설치 중 이 오류 창이 뜨고 `KakaoTalk.exe`가 어디에도 안 깔리면, prefix의 Windows
버전이 win10이 아니라 win7로 되돌아간 것이다. winetricks(vcrun2019 등)가 winver를
바꿔 놓는 것이 원인이며, installer 버전(`26.4.0.5128`) 자체와는 무관하다.

```bash
export WINEPREFIX="$HOME/.wine-kakaotalk-x64"
export WINE_RUNNER="$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64"

# 현재 보고되는 Windows 버전 확인 (6.1/7601=win7, 10.0/19045/Windows 10=win10)
grep -E '"ProductName"|"CurrentVersion"|"CurrentBuild"' "$WINEPREFIX/system.reg" \
  | grep -iv 'visual c++\|wine mono' | head

# win10으로 다시 고정 후 설치 재시도
"$WINE_RUNNER/bin/winecfg" -v win10
"$WINE_RUNNER/bin/wineserver" -w
```

참고로 설치 프로그램은 유효한 X 디스플레이가 없으면 GUI 초기화에 실패해 즉시
종료(exit 2)되기도 한다. `DISPLAY`가 살아 있는 디스플레이를 가리키는지(`:0`/`:1`)
`xdpyinfo`로 확인한다.

### DLL 오류가 다시 발생할 때

가장 먼저 런처나 desktop entry가 시스템 Wine을 호출하는지 확인한다.

```bash
sed -n '1,20p' "$HOME/.local/bin/kakaotalk-wine"
grep -RIn --include="*.desktop" -E "KakaoTalk|wine-stable|Exec=.*wine " "$HOME/.local/share/applications"
```

잘못된 예:

```bash
exec wine "$HOME/.wine-kakaotalk-x64/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe" "$@"
```

올바른 예:

```bash
exec "$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64/bin/wine" "$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe" "$@"
```

### prefix 재정비

카카오톡과 Wine 프로세스를 종료한 뒤 진행한다.

```bash
pkill -f 'KakaoTalk|wineserver|wine' || true

export KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-x64"
export WINE_RUNNER="$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64"
export WINEPREFIX="$KAKAOTALK_PREFIX"
export WINE="$WINE_RUNNER/bin/wine"
export WINESERVER="$WINE_RUNNER/bin/wineserver"
export WINEARCH=win64

"$WINE_RUNNER/bin/wineboot" -u
"$WINE_RUNNER/bin/winecfg" -v win10
winetricks -q cjkfonts gdiplus riched20 vcrun2019
"$WINE_RUNNER/bin/wineboot" -u
```

### Windows 7 호환성

이번 성공 사례에서는 Windows 7 호환 모드가 필요하지 않았다. 기본값은 Windows 10이다. 꼭 비교가 필요할 때만 임시로 바꿔 테스트하고, 테스트 후 Windows 10으로 되돌린다.

```bash
export WINEPREFIX="$HOME/.wine-kakaotalk-x64"
export WINE_RUNNER="$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64"

"$WINE_RUNNER/bin/winecfg" -v win7
"$WINE_RUNNER/bin/winecfg" -v win10
```

## 6. 성공 기준

- `"$WINE_RUNNER/bin/wine" --version` 출력이 `wine-11.9`
- `$HOME/.local/bin/kakaotalk-wine`가 시스템 `wine`이 아니라 Wine 11.9 runner를 직접 호출
- Super 검색에는 `KakaoTalk` 하나만 보임
- `KakaoTalk.desktop`의 `Exec`가 `$HOME/.local/bin/kakaotalk-wine`
- `kakaotalk-wine.desktop`에는 `NoDisplay=true`
- KakaoTalk GUI 실행 가능
- `pgrep -af 'KakaoTalk|wineserver|wine'`에서 runner 경로가 `$HOME/.local/share/wine-runners/wine-11.9-amd64-wow64` 아래로 확인됨
- DLL 오류 창이 재발하지 않음

## 7. 도커로 검증 (선택)

새 PC 없이 이 절차의 회귀를 빠르게 확인하고 싶다면 [`test/`](./test/) 디렉토리에 깨끗한 Ubuntu 24.04 컨테이너에서 절차를 재현하는 도커 환경이 있다. 사용법은 [`test/README.md`](./test/README.md) 참조.

