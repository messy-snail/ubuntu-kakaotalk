# Docker로 KakaoTalk 실행

Ubuntu 24.04와 WineHQ staging, 한글 글꼴, KakaoTalk 본체가 포함된 로컬 실사용
이미지다. 로그인 세션과 대화 데이터는 이미지 밖에 보존된다.

## 준비

- Docker Engine
- X11 또는 XWayland 세션과 `xhost`
- 한글 입력용 호스트 IBus/XIM (`ibus-x11` 권장)
- 선택: `/dev/dri` GPU 장치와 PulseAudio 호환 소켓

현재 사용자가 Docker daemon에 접근할 수 없다면 사용자가 직접 다음 명령을 실행하고
로그아웃/로그인한다. 스크립트는 이 권한을 자동으로 바꾸지 않는다.

```bash
sudo usermod -aG docker "$USER"
```

## 빌드와 실행

```bash
./docker/kakaotalk.sh build
./docker/kakaotalk.sh run
```

첫 실행에서 이미지의 prefix 템플릿을
`~/.local/share/kakaotalk-docker`로 복사한다. 이후 실행에서는 이 디렉터리를 그대로
사용하므로 로그인과 사용자 데이터가 유지된다.

> **첫 실행 필수 설정:** KakaoTalk에 로그인한 뒤
> `Settings → Display → Font → 나눔고딕`을 선택한다. 이 설정 전에는 대화창 입력 한글이
> 깨지거나 입력 직후 Wine이 멈출 수 있다. 선택 결과는 영속 데이터에 저장되므로 이후
> 컨테이너 실행에서도 유지된다.

## 관리 명령

```bash
./docker/kakaotalk.sh shell
./docker/kakaotalk.sh update
./docker/kakaotalk.sh clean
```

- `update`는 이미지를 새로 빌드한 뒤 기존 prefix에 새 KakaoTalk installer를 적용한다.
- `clean`은 컨테이너와 이미지만 제거한다. 사용자 데이터 디렉터리는 삭제하지 않는다.
- 데이터 경로를 바꾸려면 `KAKAOTALK_DOCKER_DATA=/path`를 지정한다.

## 호스트 연동

래퍼는 실행 중에만 현재 로컬 사용자에게 X 접근을 허용하고 종료 시 복구한다. IBus용
`XMODIFIERS=@im=ibus`와 UTF-8 locale, PulseAudio 소켓, `/dev/dri` 장치와 장치 그룹을
자동 전달한다. UTF-8 locale은 Wine XIM에서 한글 입력을 처리하는 데 필요하다.
호스트의 NVIDIA GLVND 강제 환경변수는 컨테이너에 전달하지 않으며 컨테이너는 Mesa를
사용한다.
