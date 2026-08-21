## v1.0.1 (2026-08-21)

Docker 이미지가 비 UTF-8 로케일로 빌드되어 한글 글꼴 매핑이 깨진 채 prefix에 굳던 문제를
고친다. v1.0.0 이미지로 만든 prefix를 쓰고 있다면 `./docker/kakaotalk.sh build`로 이미지를
다시 빌드해야 한다. 진단과 복구 절차는 `TROUBLESHOOTING.md`에 있다.

### Bug Fixes

- **install**: 비 UTF-8 로케일에서 한글 글꼴 매핑이 깨지는 문제 (#2)
- **test**: 회귀 컨테이너가 캐시 볼륨 때문에 완주하지 못하던 문제

### Docs

- README를 설치 방법(에이전트·직접 설치·Docker) 중심으로 다시 구성
- 알려진 이슈 표 추가. 환경변수와 회귀 검증 절은 전담 문서로 이동

## v1.0.0 (2026-08-21)

Ubuntu 24.04에서 Windows용 카카오톡을 WineHQ staging으로 실행하는 첫 공개 릴리즈다.
설치 자동화, Docker 실사용 환경, 깨끗한 컨테이너 회귀 검증 환경을 포함한다.

검증 기준: Ubuntu 24.04.4 LTS, WineHQ staging 11.15, KakaoTalk 26.7.1.5263 (2026-08-20).
`gdiplus`, `riched20`, `vcrun2019`는 설치하지 않으며 글꼴 전용 `cjkfonts`만 사용한다.
설치 후 카카오톡에서 `Settings → Display → Font → 나눔고딕`을 반드시 선택해야 한다.

### Packaging

- MIT 라이선스 추가
- 배지와 문서 지도를 갖춘 한국어 README, 영어 `README.en.md` 추가
- commitizen 기반 버전 관리와 `CHANGELOG.md` 도입
- `install.sh`에 버전 상수와 시작 배너 추가
- shellcheck 린트 CI와 태그 기반 릴리즈 자동화 추가

### Features

- **docker**: 영속 데이터 기반 실사용 이미지 추가
- **install**: WineHQ staging 기반 카카오톡 설치 자동화 추가
- **test**: 도커 기반 INSTALL.md 검증 환경 추가

### Bug Fixes

- **docker**: UTF-8 한글 입력 환경 고정
- **docker**: 그래픽 장치 인자 경고 제거
