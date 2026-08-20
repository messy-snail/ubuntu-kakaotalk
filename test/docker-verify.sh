#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

readonly IMAGE="kakaotalk-verify"
readonly CONTAINER="kakaotalk-verify-run"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SELF_DIR/.." && pwd)"
readonly CACHE_DIR="$SELF_DIR/.docker-cache"

usage() {
    cat <<USAGE
Usage: $0 {build|run|shell|clean|help}

  build  Ubuntu 24.04 + WineHQ staging 검증 이미지 빌드
  run    새 prefix에 install.sh를 실행하고 KakaoTalk GUI 표시
  shell  동일 이미지로 bash 진입
  clean  검증 이미지·컨테이너·test/.docker-cache 제거
  help   이 도움말

검증 절차는 cjkfonts만 사용하며 gdiplus/riched20/vcrun2019를 금지한다.
USAGE
}

require_docker() {
    command -v docker >/dev/null 2>&1 || {
        echo "ERROR: docker 명령이 없습니다." >&2
        exit 1
    }
    docker info >/dev/null 2>&1 || {
        echo "ERROR: Docker daemon 권한이 없습니다. docker 그룹 가입 후 다시 로그인하세요." >&2
        exit 1
    }
}

grant_x_access() {
    [ -n "${DISPLAY:-}" ] || {
        echo "ERROR: DISPLAY가 비어 있습니다." >&2
        exit 1
    }
    command -v xhost >/dev/null 2>&1 || {
        echo "ERROR: xhost가 없습니다. x11-xserver-utils를 설치하세요." >&2
        exit 1
    }
    xhost "+SI:localuser:$(id -un)" >/dev/null
    trap 'xhost "-SI:localuser:$(id -un)" >/dev/null 2>&1 || true' EXIT
}

append_graphics_devices() {
    local -n arguments="$1"
    local device gid known_gids=" "

    for device in /dev/dri/card* /dev/dri/renderD*; do
        [ -e "$device" ] || continue
        arguments+=(--device "$device")
        gid="$(stat -c '%g' "$device")"
        if [[ "$known_gids" != *" $gid "* ]]; then
            arguments+=(--group-add "$gid")
            known_gids+="$gid "
        fi
    done
}

run_container() {
    local entrypoint="${1:-}"
    local pulse_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pulse/native"
    local arguments=(
        --rm -it
        --name "$CONTAINER"
        --ipc=host
        -e "DISPLAY=$DISPLAY"
        -e "XMODIFIERS=@im=ibus"
        -v /tmp/.X11-unix:/tmp/.X11-unix:ro
        -v "$CACHE_DIR/installer:/home/kakao/.cache/kakaotalk-installer"
        -v "$CACHE_DIR/wine:/home/kakao/.cache/wine"
    )

    grant_x_access
    append_graphics_devices arguments

    if [ -S "$pulse_socket" ]; then
        arguments+=(
            --mount "type=bind,src=$pulse_socket,dst=/tmp/pulse-native"
            -e "PULSE_SERVER=unix:/tmp/pulse-native"
        )
    fi
    if [ -n "$entrypoint" ]; then
        arguments+=(--entrypoint "$entrypoint")
    fi

    docker run "${arguments[@]}" "$IMAGE"
}

command_name="${1:-help}"

case "$command_name" in
    build)
        require_docker
        docker build --pull \
            --build-arg HOST_UID="$(id -u)" \
            --build-arg HOST_GID="$(id -g)" \
            -f "$SELF_DIR/Dockerfile" \
            -t "$IMAGE" \
            "$REPO_ROOT"
        ;;
    run)
        require_docker
        mkdir -p "$CACHE_DIR/installer" "$CACHE_DIR/wine"
        run_container
        ;;
    shell)
        require_docker
        mkdir -p "$CACHE_DIR/installer" "$CACHE_DIR/wine"
        run_container bash
        ;;
    clean)
        require_docker
        docker container rm -f "$CONTAINER" >/dev/null 2>&1 || true
        docker image rm "$IMAGE" >/dev/null 2>&1 || true
        if [ -d "$CACHE_DIR" ]; then
            find "$CACHE_DIR" -depth -mindepth 1 -delete
            rmdir "$CACHE_DIR"
        fi
        echo "검증 이미지·컨테이너·캐시를 제거했습니다."
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
