# ubuntu-kakaotalk

Ubuntu 24.04에서 Windows용 KakaoTalk을 WineHQ staging으로 실행하는 설치 자동화와
Docker 실사용 환경이다.

> **중요:** `winetricks gdiplus`, `riched20`, `vcrun2019`를 설치하지 않는다. 이 DLL
> verb들은 채팅방 백지 화면과 `Encountered an improper argument.` 오류를 일으킨다.
> 이 저장소는 글꼴 전용 `cjkfonts`만 사용한다.

검증 기준은 2026-08-20의 Ubuntu 24.04.4, WineHQ staging 11.15, KakaoTalk
26.7.1.5263이다. WineHQ staging과 KakaoTalk installer의 이후 업데이트도 허용한다.

## 설치

```bash
git clone https://github.com/messy-snail/ubuntu-kakaotalk.git
cd ubuntu-kakaotalk
./install.sh
```

시스템 의존성이 없으면 스크립트가 필요한 `sudo` 명령을 출력하고 중단한다. 명령을 직접
실행한 뒤 `./install.sh`를 다시 실행하면 된다. 전체 절차와 환경변수는
[`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md)에 있다.

설치 후 KakaoTalk에서 반드시 다음 앱 설정을 적용한다.

```text
Settings → Display → Font → 나눔고딕
```

## 실행

```bash
~/.local/bin/kakaotalk-wine
```

기본 prefix는 `~/.wine-kakaotalk-clean`이다. 별도 prefix를 설치하거나 실행하려면 다음처럼
지정한다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-test" ./install.sh
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-test" ~/.local/bin/kakaotalk-wine
```

## Docker

```bash
./docker/kakaotalk.sh build
./docker/kakaotalk.sh run
```

로그인과 대화 데이터는 `~/.local/share/kakaotalk-docker`에 보존된다. 자세한 사용법은
[`docker/README.md`](./docker/README.md)를 참고한다.

## 회귀 검증

```bash
./test/docker-verify.sh build
./test/docker-verify.sh run
```

컨테이너 검증 환경은 호스트 Wine prefix를 마운트하지 않는다. 자세한 범위와 제약은
[`test/README.md`](./test/README.md)에 있다.

문제가 생기면 [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md)를 먼저 확인한다.

## 에이전트에게 설치 맡기기

저장소 루트에서 다음 요청을 사용한다.

```text
README.md와 KAKAOTALK_WINE_INSTALL.md를 읽고 ./install.sh로 설치해줘.
sudo가 필요한 시스템 명령은 먼저 보여주고, 기존 Wine prefix는 삭제하지 마.
끝나면 자체 점검 결과와 Display → Font → 나눔고딕 설정 필요 여부를 알려줘.
```
