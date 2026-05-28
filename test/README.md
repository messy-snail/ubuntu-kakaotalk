# test/ — 도커 기반 INSTALL.md 검증 환경

루트 [`KAKAOTALK_WINE_INSTALL.md`](../KAKAOTALK_WINE_INSTALL.md) 절차를 깨끗한 Ubuntu 24.04 컨테이너에서 그대로 재현해 회귀를 잡는다. 새 PC 없이 절차가 깨지지 않았는지 확인하고 싶을 때 사용.

호스트의 카카오톡 환경(`~/.wine-kakaotalk-x64`, `~/.local/bin/kakaotalk-wine`)은 건드리지 않는다.

## 사전 준비

- **Docker**: 사용자가 `docker` 그룹에 포함 (재로그인 또는 `newgrp docker`)
- **X 세션 + xhost**: `x11-xserver-utils` 패키지
- **KakaoTalk_Setup.exe** (선택):
  - 아무 것도 안 두면 컨테이너가 카카오 CDN에서 자동 다운로드
  - 카카오 정책상 거절될 때(`"Unable to install this version"` 다이얼로그)는 카카오 사이트에서 직접 받아 `test/.docker-cache/KakaoTalk_Setup.exe` 에 두면 그걸 우선 사용

## 실행

```bash
./test/docker-verify.sh build
./test/docker-verify.sh run
```

`run`은 `xhost +local:docker`로 X 소켓을 잠시 열고, `/tmp/.X11-unix`·`test/.docker-cache`·`$HOME/.cache/winetricks`(있을 때)를 마운트해 컨테이너에서 절차를 실행한다. 종료 시 trap으로 `xhost -local:docker`를 자동 복구.

## 성공 기준

호스트 화면에 카카오톡 로그인 창이 뜨고, sum-up 5개 항목이 모두 OK.

```
==> 검증 결과 (INSTALL.md 3.1·3.3·3.4·3.5·3.6)
    Wine 11.9 runner:    OK
    Wine prefix(win10):  OK
    winetricks 4종:      OK
    런처 스크립트:        OK
    KakaoTalk 본체 설치:  OK
```

## winetricks 캐시 마운트

winetricks의 `vcrun2019` 보충 단계가 windows6.1(win7sp1) 패키지 약 1.5 GB를 다운로드한다. 호스트에 `$HOME/.cache/winetricks` 가 있으면 `run`이 자동으로 마운트해 재다운로드를 회피한다. 글로벌 파일 캐시이므로 호스트 카카오톡 환경에 영향 없음.

## 한계

- **3.7 / 3.8** `.desktop` entry와 Super 검색 — 호스트 GNOME 통합이 필요해 컨테이너로 검증 불가
- **3.5** KakaoTalk 본체 설치 — 카카오 서버의 installer 정책에 의존. 신선한 installer가 없으면 같은 거절 다이얼로그가 뜸. 컨테이너 결함이 아니라 카카오톡 정책 한계.

## 기타 명령

```bash
./test/docker-verify.sh shell   # 같은 이미지로 bash 진입 (디버깅)
./test/docker-verify.sh clean   # 이미지/컨테이너/캐시 제거
./test/docker-verify.sh help    # 도움말
```

## 파일

- [`Dockerfile`](./Dockerfile) — Ubuntu 24.04 + INSTALL.md 3.1 패키지 + 비-root 사용자
- [`container-install.sh`](./container-install.sh) — 컨테이너 안에서 INSTALL.md 3.3 ~ 4.1을 옮겨 적은 사본. 본문 절차를 바꿀 때 함께 업데이트.
- [`docker-verify.sh`](./docker-verify.sh) — 호스트에서 부르는 wrapper (build / run / shell / clean / help)
- `.docker-cache/` — Wine tarball, KakaoTalk_Setup.exe 캐시 (gitignore)
