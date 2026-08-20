<div align="center">

# ubuntu-kakaotalk

**Ubuntu 24.04에서 Windows용 카카오톡을 WineHQ staging으로 실행하는 설치 자동화와 Docker 환경**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Release](https://img.shields.io/github/v/release/messy-snail/ubuntu-kakaotalk?color=blue)](https://github.com/messy-snail/ubuntu-kakaotalk/releases/latest)
[![lint](https://github.com/messy-snail/ubuntu-kakaotalk/actions/workflows/lint.yml/badge.svg)](https://github.com/messy-snail/ubuntu-kakaotalk/actions/workflows/lint.yml)

[![Ubuntu 24.04 LTS](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![WineHQ staging](https://img.shields.io/badge/WineHQ-staging%2011.15%2B-9C27B0)](https://wiki.winehq.org/Ubuntu)
[![KakaoTalk](https://img.shields.io/badge/KakaoTalk-26.7.1.5263-FEE500?logo=kakaotalk&logoColor=3C1E1E)](https://www.kakaocorp.com/)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](./docker/README.md)

한국어 | [English](./README.en.md)

</div>

---

카카오톡은 (주)카카오의 독점 소프트웨어다. 이 저장소는 **설치와 실행을 자동화할 뿐** 카카오톡
바이너리를 재배포하지 않으며 카카오와 아무런 관련이 없다.

> [!WARNING]
> `winetricks gdiplus`, `riched20`, `vcrun2019`를 설치하지 않는다. 이 DLL verb들은 채팅방
> 백지 화면과 `Encountered an improper argument.` 오류를 일으킨다. 이 저장소는 글꼴 전용
> `cjkfonts`만 사용한다.

## 무엇을 해주나

- **깨끗한 prefix 구성** — win64 + Windows 10 모드에 글꼴 전용 `cjkfonts`만 넣는다. 채팅
  렌더링을 깨뜨리는 DLL verb는 처음부터 배제한다.
- **나눔 글꼴 배선** — 호스트의 `fonts-nanum`에서 NanumGothic, NanumBarunGothic,
  NanumMyeongjo를 prefix로 복사한 뒤 서로 다른 두 층위를 각각 설정한다. Wine이 Windows 글꼴
  요청(`MS Shell Dlg`, `Segoe UI`, `맑은 고딕`)을 대신 그릴 때는 NanumBarunGothic을 쓰고,
  카카오톡이 앱에서 고른 `나눔고딕`을 요청할 때는 NanumGothic으로 해석되게 한다. 전자는
  `FontSubstitutes`와 `FontLink\SystemLink`, 후자는 `Fonts\Replacements`가 담당한다.
- **설치 파일 자동 수급** — 카카오톡 설치파일을 공식 CDN에서 직접 받아
  `~/.cache/kakaotalk-installer`에 캐시한다. Wine Gecko/Mono와 `cjkfonts`도 자동으로 받는다.
- **무결성 검증** — Wine Gecko/Mono는 고정된 SHA-256으로 대조하고, 카카오톡 설치파일은 크기와
  PE 헤더(`MZ`)를 확인한 뒤에만 실행한다. 설치파일은 CDN이 계속 갱신하므로 해시를 고정하지 않고
  실제 값을 출력한다.
- **기존 데이터 비파괴** — prefix를 삭제하거나 초기화하지 않는다. 금지 DLL이 이미 들어간
  prefix는 억지로 수리하지 않고 중단한 뒤 새 경로 사용을 안내한다.
- **데스크톱 통합** — 재시도 런처, `.exe`에서 추출한 256px 아이콘, 앱 및
  `kakaoopen://` 프로토콜 desktop entry를 생성한다.
- **자체 점검** — 설치 끝에 Wine 버전, prefix 모드, 금지 verb 부재, 글꼴, 본체, 런처,
  데스크톱 통합을 전부 확인하고 하나라도 실패하면 오류로 끝낸다.
- **Docker 실사용 이미지와 회귀 검증 환경** — 로그인·대화 데이터를 호스트에 영속시키는
  실사용 이미지와, 깨끗한 컨테이너에서 `install.sh` 전체를 다시 돌리는 검증 환경을 함께 제공한다.

## 검증 환경

| 항목 | 값 |
|---|---|
| OS | Ubuntu 24.04.4 LTS (amd64 + i386) |
| Wine | WineHQ staging 11.15, `/opt/wine-staging/bin/wine` |
| Windows 모드 | Windows 10, win64 prefix |
| winetricks | `cjkfonts`만 |
| Gecko / Mono | 2.47.4 (x86, x86_64) / 11.2.0 (x86) |
| KakaoTalk | 26.7.1.5263 |
| 기본 prefix | `~/.wine-kakaotalk-clean` |

위 버전은 강제 pin이 아니라 **성공이 확인된 기준점**이다(검증일 2026-08-20). WineHQ staging은
rolling 패키지이고 KakaoTalk CDN도 최신 installer로 바뀔 수 있으므로 이후 버전도 허용한다.

## 빠른 시작

```bash
git clone https://github.com/messy-snail/ubuntu-kakaotalk.git
cd ubuntu-kakaotalk
./install.sh
```

카카오톡 설치파일, Wine Gecko/Mono, `cjkfonts`는 스크립트가 알아서 받는다. 미리 준비해야
하는 건 apt 패키지뿐이다 — WineHQ staging, winetricks, `fonts-nanum` 계열 등. `sudo`가 필요한
작업이라 스크립트가 대신 실행하지 않고, 빠진 게 있으면 필요한 명령을 출력하고 중단한다. 그
명령을 직접 실행한 뒤 `./install.sh`를 다시 실행하면 된다. 전체 목록과 절차는
[`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md)에 있다.

Docker 경로에는 이 구분이 없다. 이미지 빌드 중에 `install.sh`가 그대로 실행되어 apt 패키지부터
카카오톡 본체까지 전부 이미지 안에서 준비된다.

실행:

```bash
~/.local/bin/kakaotalk-wine
```

데스크톱 환경의 앱 메뉴에서 `KakaoTalk`을 검색해도 같은 런처가 실행된다.

## 필수 앱 설정

> [!IMPORTANT]
> 로그인 후 카카오톡에서 반드시 다음을 선택한다.
>
> ```text
> Settings → Display → Font → 나눔고딕
> ```
>
> `Settings → Chat`이 아니라 `Display` 탭이다. 이 설정 전에는 채팅 본문이 정상이어도
> 입력창의 한글이 깨지거나 입력 직후 Wine이 멈출 수 있다.

## Docker

```bash
./docker/kakaotalk.sh build
./docker/kakaotalk.sh run
```

첫 실행에서 이미지의 prefix 템플릿을 `~/.local/share/kakaotalk-docker`로 복사하고, 이후
실행부터 그 디렉터리를 그대로 사용한다. 로그인 세션과 대화 데이터는 이미지 밖에 남으므로
`build`를 다시 해도 유지된다. 위의 **필수 앱 설정**은 Docker에서도 동일하게 적용해야 한다.

관리 명령(`shell`, `update`, `clean`)과 호스트 연동 방식은
[`docker/README.md`](./docker/README.md)를 참고한다.

## 회귀 검증

```bash
./test/docker-verify.sh build
./test/docker-verify.sh run
```

깨끗한 Ubuntu 24.04 컨테이너에서 루트 `install.sh`를 처음부터 실행해 문서와 자동화가 같은
절차를 유지하는지 확인한다. 호스트 Wine prefix는 마운트하지 않는다. 검사 항목과 제약은
[`test/README.md`](./test/README.md)에 있다.

## 환경변수

| 이름 | 기본값 | 용도 |
|---|---|---|
| `KAKAOTALK_PREFIX` | `$HOME/.wine-kakaotalk-clean` | 설치·실행에 사용할 Wine prefix |
| `KAKAOTALK_CACHE` | `$HOME/.cache/kakaotalk-installer` | KakaoTalk installer 캐시 |
| `KAKAOTALK_INSTALL_DESKTOP` | `1` | `0`이면 아이콘과 desktop entry 생략 |
| `KAKAOTALK_DOCKER_DATA` | `$HOME/.local/share/kakaotalk-docker` | Docker 영속 데이터 경로 |

설치와 실행에 같은 값을 넘기면 prefix를 분리해 쓸 수 있다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-test" ./install.sh
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-test" ~/.local/bin/kakaotalk-wine
```

## 문서

| 문서 | 언제 읽나 |
|---|---|
| [`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md) | 설치 절차 전체, `sudo` 명령, 자체 확인 방법을 손으로 따라갈 때 |
| [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) | 백지 화면, 한글 깨짐, `c0000409`, GPU·오디오·입력기 문제가 났을 때 |
| [`docker/README.md`](./docker/README.md) | Docker로 실사용할 때, 영속 데이터와 호스트 연동을 볼 때 |
| [`test/README.md`](./test/README.md) | 변경 후 깨끗한 환경에서 회귀 검증할 때 |
| [`CHANGELOG.md`](./CHANGELOG.md) | 릴리즈 간 변경점을 확인할 때 |

`TROUBLESHOOTING.md`에는 원인 분석 중 **기각된 가설**(Wine 빌드, GPU, DLL override, WIC,
WebView2 등)도 기록되어 있다. 같은 길을 다시 파기 전에 먼저 확인하면 좋다.

## 에이전트에게 설치 맡기기

Codex나 Claude Code 같은 코딩 에이전트에게 맡길 수 있다. 저장소 루트에서 다음 요청을 쓴다.

```text
README.md와 KAKAOTALK_WINE_INSTALL.md를 읽고 ./install.sh로 설치해줘.
sudo가 필요한 시스템 명령은 먼저 보여주고, 기존 Wine prefix는 삭제하지 마.
끝나면 자체 점검 결과와 Display → Font → 나눔고딕 설정 필요 여부를 알려줘.
```

## 기여

이슈와 PR 환영한다. 버그 리포트에는 다음을 함께 적어주면 훨씬 빠르게 좁힐 수 있다.

```bash
/opt/wine-staging/bin/wine --version
cat "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/winetricks.log"
grep -m1 '"ProductName"=' "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/system.reg"
```

커밋은 [Conventional Commits](https://www.conventionalcommits.org/)를 따르고 버전은
[commitizen](https://commitizen-tools.github.io/commitizen/)으로 관리한다.

```bash
uv run --no-project cz commit          # 커밋 작성
shellcheck -x install.sh docker/*.sh test/*.sh   # CI와 동일한 린트
```

## 라이선스 및 고지

이 저장소의 스크립트와 문서는 [MIT License](./LICENSE)를 따른다.

카카오톡(KakaoTalk)은 (주)카카오의 독점 소프트웨어이며 관련 상표는 카카오에 귀속된다. 이
저장소는 카카오톡을 포함·재배포하지 않고 공식 CDN에서 내려받아 설치하는 절차만 자동화하며,
카카오가 후원하거나 승인한 프로젝트가 아니다. 카카오톡 사용에는 카카오의 이용약관이 적용된다.
Wine은 [WineHQ 프로젝트](https://www.winehq.org/)의 저작물로 각자의 라이선스를 따른다.
