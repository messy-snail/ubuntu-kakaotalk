# `test/` — 깨끗한 컨테이너 설치 회귀 검증

루트 [`install.sh`](../install.sh)를 새 Ubuntu 24.04 컨테이너에서 실행해 문서와 자동화가
같은 절차를 유지하는지 확인한다. 호스트의 Wine prefix는 마운트하지 않는다.

## 실행

```bash
./test/docker-verify.sh build
./test/docker-verify.sh run
```

첫 `run`은 Gecko, Mono, `cjkfonts`, KakaoTalk installer를
`test/.docker-cache`에 저장한다. 다음 실행부터 캐시를 재사용한다.

`install.sh`는 일부러 `LC_ALL=C`로 호출한다. Wine은 명령줄 인자를 로케일 인코딩으로
해석하므로, 스크립트가 스스로 UTF-8을 고정하지 않으면 한글 레지스트리 값 이름이 깨진다.
컨테이너 기본 로케일을 UTF-8로 두면 이 회귀를 잡을 수 없다.

## 자동 검사

- `/opt/wine-staging/bin/wine` 존재
- Windows 10 prefix
- `cjkfonts` 설치
- `gdiplus`, `riched20`, `vcrun2019` 미설치
- NanumBarunGothic 복사
- `나눔고딕` → NanumGothic, `맑은 고딕` → NanumBarunGothic 매핑
- `Program Files (x86)`의 KakaoTalk 본체
- 재시도 런처 생성

자동 검사 통과 후 호스트 X 화면에 로그인 창을 띄운다. 로그인 후
`Settings → Display → Font → 나눔고딕`을 선택하고 채팅 본문과 입력창 한글, 오류창
재발 여부를 사람이 확인해야 한다.

## 제약

- Docker daemon 권한과 X11/XWayland 세션이 필요하다.
- `clean`은 `test/.docker-cache`까지 삭제한다. 호스트 Wine prefix나 실사용 Docker 데이터는
  건드리지 않는다.

## 기타 명령

```bash
./test/docker-verify.sh shell
./test/docker-verify.sh clean
./test/docker-verify.sh help
```
