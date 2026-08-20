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
