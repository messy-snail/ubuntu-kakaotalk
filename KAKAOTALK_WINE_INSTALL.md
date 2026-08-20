# KakaoTalk on Wine 설치 가이드

이 문서는 Ubuntu 24.04에서 [`install.sh`](./install.sh)가 수행하는 절차와 운영 방법을
설명한다. 사람이 직접 실행하거나 Codex·Claude 같은 에이전트가 그대로 사용할 수 있다.

> **절대 설치하지 말 것:** `winetricks gdiplus riched20 vcrun2019`
>
> 이 verb들이 설치하는 native Microsoft DLL은 파일이 prefix에 남는 한
> `WINEDLLOVERRIDES`만으로 안전하게 배제할 수 없다. 새 prefix와 `cjkfonts`만 사용한
> 구성이 채팅 렌더링 오류를 해결한 검증 경로다.

## 1. 검증 기준

| 항목 | 값 |
|---|---|
| OS | Ubuntu 24.04.4 LTS, amd64 + i386 |
| Wine | WineHQ staging 11.15, `/opt/wine-staging/bin/wine` |
| Windows 모드 | Windows 10, win64 prefix |
| winetricks | `cjkfonts`만 |
| Gecko | 2.47.4 x86, x86_64 |
| Mono | 11.2.0 x86 |
| KakaoTalk | 26.7.1.5263 |
| 기본 prefix | `~/.wine-kakaotalk-clean` |

WineHQ staging은 rolling 패키지이므로 11.15보다 새 버전도 사용한다. KakaoTalk CDN도 최신
installer로 바뀔 수 있다. 위 버전은 강제 pin이 아니라 성공한 기준점이다.

## 2. 시스템 준비

`install.sh`는 시스템 상태를 검사하지만 `sudo`나 apt 설정을 자동 실행하지 않는다. 필요한
경우 아래 명령을 사용자가 직접 실행한다.

```bash
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
```

확인:

```bash
dpkg --print-foreign-architectures
/opt/wine-staging/bin/wine --version
```

첫 명령에 `i386`, 두 번째 명령에 `wine-11.15 (Staging)` 또는 이후 staging 버전이 나와야
한다.

## 3. 설치

```bash
./install.sh
```

대상 prefix의 KakaoTalk이 실행 중이면 먼저 정상 종료하는 것을 권장한다. 스크립트가 prefix를
강제 종료하거나 삭제하지는 않지만 글꼴 변경은 다음 앱 시작부터 확실히 반영된다.

스크립트는 다음 순서로 동작한다.

1. i386, WineHQ staging, 도구와 Nanum 글꼴 검사
2. 기존 prefix의 금지 verb와 native `mfc140u.dll` 검사
3. Wine Gecko/Mono 다운로드와 SHA-256 검증
4. win64 prefix 생성과 Windows 10 설정
5. `winetricks -q cjkfonts`
6. Nanum 글꼴 복사, `FontSubstitutes`, `Fonts\Replacements`, `FontLink` 설정
7. KakaoTalk 공식 CDN installer `/S` 실행
8. 재시도 런처, 256px ICO, 앱·프로토콜 desktop entry 생성
9. Wine·prefix·글꼴·KakaoTalk·런처 자체 점검

이미 정상인 prefix에는 글꼴과 런처 설정을 멱등하게 다시 적용한다. 금지 DLL이 들어간
prefix는 자동으로 수리하지 않고 중단한다. 이 경우 기존 데이터를 삭제하지 말고 새 경로를
사용한다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-new" ./install.sh
```

격리 검증에서 호스트 desktop entry를 바꾸지 않으려면 다음 옵션을 사용한다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-verify" \
KAKAOTALK_INSTALL_DESKTOP=0 \
./install.sh
```

지원 환경변수:

| 이름 | 기본값 | 용도 |
|---|---|---|
| `KAKAOTALK_PREFIX` | `$HOME/.wine-kakaotalk-clean` | 설치·실행 Wine prefix |
| `KAKAOTALK_CACHE` | `$HOME/.cache/kakaotalk-installer` | KakaoTalk installer 캐시 |
| `KAKAOTALK_INSTALL_DESKTOP` | `1` | `0`이면 아이콘과 desktop entry 생략 |

기존 installer 캐시를 보존하면서 새 파일을 받고 싶다면 먼저 이름을 바꾼다.

```bash
mv "$HOME/.cache/kakaotalk-installer/KakaoTalk_Setup.exe" \
  "$HOME/.cache/kakaotalk-installer/KakaoTalk_Setup.exe.old"
./install.sh
```

## 4. 실행과 필수 앱 설정

```bash
~/.local/bin/kakaotalk-wine
```

다른 prefix를 실행할 때는 설치 때와 같은 값을 넘긴다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-verify" ~/.local/bin/kakaotalk-wine
```

`wineserver -k` 직후 KakaoTalk이 `c0000409`로 시작 즉시 종료될 수 있다. 런처는 15초 안에
비정상 종료된 경우에만 최대 세 번 재시도한다. 정상 종료나 15초 이상 실행한 뒤의 오류는
자동 재시작하지 않는다.

로그인 후 다음 설정은 수동으로 적용해야 한다.

```text
Settings → Display → Font → 나눔고딕
```

정확한 탭은 `Display`다. 이 설정을 하지 않으면 채팅 본문이 정상이어도 입력창의 한글이
깨질 수 있다.

## 5. 자체 확인

```bash
/opt/wine-staging/bin/wine --version
grep -m1 '"ProductName"="Microsoft Windows 10"' \
  "$HOME/.wine-kakaotalk-clean/system.reg"
grep -E '^(cjkfonts|gdiplus|riched20|vcrun2019)$' \
  "$HOME/.wine-kakaotalk-clean/winetricks.log"
test -f "$HOME/.wine-kakaotalk-clean/drive_c/windows/Fonts/NanumBarunGothic.ttf"
test -f "$HOME/.wine-kakaotalk-clean/drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe"
```

winetricks 출력에는 `cjkfonts`만 있어야 한다. 최종 성공 기준은 다음과 같다.

- 로그인 창과 채팅방 본문 표시
- `Display → Font → 나눔고딕` 적용 후 입력창 한글 정상
- 25분 이상 사용 중 `Encountered an improper argument.` 오류창 없음
- Super 검색의 KakaoTalk 항목이 `~/.local/bin/kakaotalk-wine`을 실행
- Wine 프로세스가 `/opt/wine-staging`을 사용

## 6. 사용자 데이터 보호

스크립트는 prefix를 삭제하거나 초기화하지 않는다. 다음 두 진단용 prefix도 자동으로
건드리지 않는다.

- `~/.wine-kakaotalk-clean`: 정상 동작과 로그인 상태가 확인된 prefix
- `~/.wine-kakaotalk-x64`: 금지 DLL 문제 재현용 prefix

문제 prefix를 정리하려면 먼저 백업하고 별도 사용자 승인을 받아야 한다.

## 7. Docker와 회귀 검증

- 실사용 Docker: [`docker/README.md`](./docker/README.md)
- 깨끗한 설치 회귀 검증: [`test/README.md`](./test/README.md)
- 원인 분석과 장애 대응: [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md)
