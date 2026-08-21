<div align="center">

# ubuntu-kakaotalk

**Ubuntu 24.04에서 Windows용 카카오톡을 WineHQ staging으로 실행하는 설치 자동화**

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

카카오톡은 (주)카카오의 독점 소프트웨어다. 이 저장소는 **설치와 실행을 자동화할 뿐**
카카오톡 바이너리를 재배포하지 않으며 카카오와 아무런 관련이 없다.

## 설치 방법 세 가지

| | 방법 | 이런 사람에게 | 명령 |
|---|---|---|---|
| 🤖 | **에이전트에게 맡기기** | 터미널 작업을 대신 시키고 싶다 | 아래 프롬프트를 복사 |
| 🔧 | **직접 설치** | 호스트에 바로 깔고 싶다 | `./install.sh` |
| 📦 | **Docker** | 호스트를 안 건드리고 싶다 | `./docker/kakaotalk.sh build` |

어느 쪽이든 카카오톡 설치파일은 공식 CDN에서 자동으로 받고, 설치 마법사는 무인 모드로
돌아간다. **`다음` 버튼을 누를 일은 없다.**

### 🤖 1. 에이전트에게 맡기기

![난이도: 가장 쉬움](https://img.shields.io/badge/%EB%82%9C%EC%9D%B4%EB%8F%84-%EA%B0%80%EC%9E%A5_%EC%89%AC%EC%9B%80-brightgreen) ![sudo: 에이전트가 실행](https://img.shields.io/badge/sudo-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8%EA%B0%80_%EC%8B%A4%ED%96%89-blue)

Codex나 Claude Code 같은 코딩 에이전트에게 맡긴다. 저장소 루트에서 이렇게 요청한다.

```text
README.md와 KAKAOTALK_WINE_INSTALL.md를 읽고 ./install.sh로 설치해줘.
sudo가 필요한 시스템 명령은 먼저 보여주고, 기존 Wine prefix는 삭제하지 마.
끝나면 자체 점검 결과와 Display → Font → 나눔고딕 설정 필요 여부를 알려줘.
```

`install.sh`를 대신 돌려주는 것이라 결과물은 2번과 같다. 차이는 `sudo` 준비 단계까지
에이전트가 처리해준다는 점이다.

### 🔧 2. 직접 설치

![난이도: 보통](https://img.shields.io/badge/%EB%82%9C%EC%9D%B4%EB%8F%84-%EB%B3%B4%ED%86%B5-yellow) ![sudo: 직접 실행](https://img.shields.io/badge/sudo-%EC%A7%81%EC%A0%91_%EC%8B%A4%ED%96%89-orange)

```bash
git clone https://github.com/messy-snail/ubuntu-kakaotalk.git
cd ubuntu-kakaotalk
./install.sh
```

미리 준비해야 하는 건 apt 패키지뿐이다 — WineHQ staging, winetricks, `fonts-nanum` 계열.
`sudo`가 필요한 작업이라 스크립트가 대신 실행하지 않고, **빠진 게 있으면 필요한 명령을
출력하고 멈춘다.** 그 명령을 실행한 뒤 `./install.sh`를 다시 돌리면 된다.

Wine Gecko/Mono와 `cjkfonts`, 카카오톡 설치파일은 스크립트가 알아서 받는다. 절차 전문은
[`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md)에 있다.

### 📦 3. Docker

![난이도: 보통](https://img.shields.io/badge/%EB%82%9C%EC%9D%B4%EB%8F%84-%EB%B3%B4%ED%86%B5-yellow) ![격리: 호스트 무변경](https://img.shields.io/badge/%EA%B2%A9%EB%A6%AC-%ED%98%B8%EC%8A%A4%ED%8A%B8_%EB%AC%B4%EB%B3%80%EA%B2%BD-brightgreen)

```bash
./docker/kakaotalk.sh build
./docker/kakaotalk.sh run
```

apt 패키지까지 전부 이미지 안에서 준비되므로 `sudo` 단계가 없다. 대신 Docker daemon
접근 권한이 필요하다. 로그인 세션과 대화 데이터는 이미지 밖
`~/.local/share/kakaotalk-docker`에 남으므로 `build`를 다시 해도 유지된다.

자세한 내용은 [`docker/README.md`](./docker/README.md).

## 실행

```bash
~/.local/bin/kakaotalk-wine
```

데스크톱 앱 메뉴에서 `KakaoTalk`을 검색해도 같은 런처가 뜬다. Docker는
`./docker/kakaotalk.sh run`.

## 필수 앱 설정

> [!IMPORTANT]
> 로그인한 뒤 카카오톡에서 반드시 다음을 선택한다.
>
> ```text
> Settings → Display → Font → 나눔고딕
> ```
>
> `Settings → Chat`이 아니라 `Display` 탭이다. 이 설정 전에는 채팅 본문이 정상이어도
> 입력창의 한글이 깨지거나 입력 직후 Wine이 멈출 수 있다. 설치 경로와 무관하게 동일하다.

## 알려진 이슈

| 증상 | 원인 |
|---|---|
| 채팅방 백지 + `Encountered an improper argument.` 반복 | winetricks `gdiplus`·`riched20`·`vcrun2019`. 이 저장소는 넣지 않는다 |
| 입력창 한글만 깨짐 | 위 **필수 앱 설정** 미적용 |
| Docker 설치인데 글꼴 매핑이 깨짐 | v1.0.0 이미지가 비 UTF-8 로케일로 빌드됨. v1.0.1에서 수정 |
| 첫 실행이 `c0000409`로 즉시 종료 | 런처가 자동으로 최대 세 번 재시도한다 |

> [!WARNING]
> `winetricks gdiplus`, `riched20`, `vcrun2019`를 설치하지 않는다. 채팅방 백지 화면의
> 직접 원인이다. 이 저장소는 글꼴 전용 `cjkfonts`만 쓴다.

진단 명령, 복구 절차, 조사 중 **기각된 가설**(Wine 빌드, GPU, DLL override, WIC, WebView2
등)은 [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md)에 정리되어 있다.

## 문서

| 문서 | 언제 읽나 |
|---|---|
| [`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md) | 설치 절차를 손으로 따라가거나 환경변수를 바꿀 때 |
| [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) | 문제가 났을 때 |
| [`docker/README.md`](./docker/README.md) | Docker로 쓸 때 |
| [`test/README.md`](./test/README.md) | 코드를 고친 뒤 회귀 검증할 때 |
| [`CHANGELOG.md`](./CHANGELOG.md) | 릴리즈 간 변경점 |

검증 기준점은 Ubuntu 24.04.4 LTS + WineHQ staging 11.15 + KakaoTalk 26.7.1.5263이다
(2026-08-21 재검증). 강제 pin이 아니라 성공이 확인된 조합이며 이후 버전도 허용한다.

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
uv run --no-project cz commit                     # 커밋 작성
shellcheck -x install.sh docker/*.sh test/*.sh    # CI와 동일한 린트
```

## 라이선스 및 고지

이 저장소의 스크립트와 문서는 [MIT License](./LICENSE)를 따른다.

카카오톡(KakaoTalk)은 (주)카카오의 독점 소프트웨어이며 관련 상표는 카카오에 귀속된다. 이
저장소는 카카오톡을 포함·재배포하지 않고 공식 CDN에서 내려받아 설치하는 절차만 자동화하며,
카카오가 후원하거나 승인한 프로젝트가 아니다. 카카오톡 사용에는 카카오의 이용약관이 적용된다.
Wine은 [WineHQ 프로젝트](https://www.winehq.org/)의 저작물로 각자의 라이선스를 따른다.
