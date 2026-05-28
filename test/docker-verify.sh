#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="kakaotalk-verify"
CONTAINER="kakaotalk-verify-run"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="$SELF_DIR/.docker-cache"

usage() {
    cat <<USAGE
Usage: $0 {build|run|shell|clean|help}

  build  - Ubuntu 24.04 베이스에서 검증 이미지 빌드
  run    - 컨테이너에서 INSTALL.md 절차 실행, 본체 설치 + GUI까지 시도
  shell  - 동일 이미지로 bash 진입 (디버깅용)
  clean  - 이미지/컨테이너/.docker-cache 모두 제거
  help   - 이 도움말

사전 준비:
  - DISPLAY 환경변수와 X 세션 (xhost 명령 필요)
  - 카카오톡 silent 설치까지 보려면 .docker-cache/KakaoTalk_Setup.exe 에
    카카오에서 신선하게 받은 installer를 둘 것. 시간이 지난 installer는
    카카오 서버가 outdated 판정으로 거절할 수 있음.
  - winetricks가 vcrun2019 보충 단계로 windows6.1(win7sp1) 패키지 ~1.5 GB를
    다운로드함. 호스트에 \$HOME/.cache/winetricks 가 있으면 run이 자동으로
    마운트해서 재다운로드를 회피.

검증 범위:
  - 3.1 패키지 설치 / 3.3 Wine 11.9 runner / 3.4 prefix + winetricks 4종
  - 3.6 런처 스크립트
  - 3.5 KakaoTalk 본체 설치 (silent) — installer 유효성에 의존
  - 4.1 GUI 실행 — 본체 설치 성공 시 자동 띄움

검증 제외 (호스트 GNOME 통합):
  - 3.7 / 3.8 .desktop entry, Super 검색

성공 기준:
  - sum-up 4개 항목(Wine runner, prefix, winetricks, 런처) 모두 OK
  - KakaoTalk 본체 설치 OK + 호스트 화면에 카카오톡 로그인 창 표시
USAGE
}

require_display() {
    if [ -z "${DISPLAY:-}" ]; then
        echo "ERROR: DISPLAY 환경변수가 비어 있습니다. X 세션에서 실행하세요." >&2
        exit 1
    fi
    if ! command -v xhost >/dev/null 2>&1; then
        echo "ERROR: xhost 명령이 없습니다. x11-xserver-utils 패키지를 설치하세요." >&2
        exit 1
    fi
}

cmd="${1:-help}"

case "$cmd" in
    build)
        docker build \
            --build-arg HOST_UID="$(id -u)" \
            --build-arg HOST_GID="$(id -g)" \
            -t "$IMAGE" \
            "$SELF_DIR"
        ;;
    run)
        require_display
        mkdir -p "$CACHE_DIR"
        xhost +local:docker >/dev/null
        trap 'xhost -local:docker >/dev/null' EXIT
        docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
        WT_CACHE_MOUNT=()
        if [ -d "$HOME/.cache/winetricks" ]; then
            WT_CACHE_MOUNT=(-v "$HOME/.cache/winetricks:/home/kakao/.cache/winetricks")
        fi
        docker run --rm -it \
            -e DISPLAY="$DISPLAY" \
            -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
            -v "$CACHE_DIR:/home/kakao/.cache/kakaotalk-installer" \
            "${WT_CACHE_MOUNT[@]}" \
            --ipc=host \
            --name "$CONTAINER" \
            "$IMAGE"
        ;;
    shell)
        require_display
        mkdir -p "$CACHE_DIR"
        xhost +local:docker >/dev/null
        trap 'xhost -local:docker >/dev/null' EXIT
        docker run --rm -it \
            -e DISPLAY="$DISPLAY" \
            -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
            -v "$CACHE_DIR:/home/kakao/.cache/kakaotalk-installer" \
            --ipc=host \
            --entrypoint bash \
            "$IMAGE"
        ;;
    clean)
        docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
        docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
        rm -rf "$CACHE_DIR"
        echo "이미지/컨테이너/캐시 제거 완료"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
