#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly IMAGE="ubuntu-kakaotalk:local"
readonly CONTAINER="ubuntu-kakaotalk"
readonly DATA_DIR="${KAKAOTALK_DOCKER_DATA:-$HOME/.local/share/kakaotalk-docker}"

usage() {
    cat <<EOF
Usage: $0 {build|run|shell|update|clean|help}

  build   현재 UID/GID로 실사용 이미지를 빌드
  run     영속 데이터로 KakaoTalk 실행
  shell   같은 이미지와 데이터로 디버깅 shell 실행
  update  최신 이미지를 다시 빌드하고 기존 prefix의 KakaoTalk만 업데이트
  clean   컨테이너와 이미지만 제거 (사용자 데이터는 보존)
  help    이 도움말

사용자 데이터: $DATA_DIR
EOF
}

require_docker() {
    command -v docker >/dev/null 2>&1 || {
        echo "ERROR: docker 명령이 없습니다." >&2
        exit 1
    }
    if ! docker info >/dev/null 2>&1; then
        cat >&2 <<'EOF'
ERROR: Docker daemon에 접근할 수 없습니다.
필요하면 사용자가 직접 아래 명령을 실행하고 다시 로그인하세요.

  sudo usermod -aG docker "$USER"
EOF
        exit 1
    fi
}

validate_data_dir() {
    case "$DATA_DIR" in
        /*) ;;
        *) echo "ERROR: KAKAOTALK_DOCKER_DATA는 절대 경로여야 합니다: $DATA_DIR" >&2; exit 1 ;;
    esac
    case "$DATA_DIR" in
        /|"$HOME") echo "ERROR: 안전하지 않은 사용자 데이터 경로입니다: $DATA_DIR" >&2; exit 1 ;;
    esac
}

build_image() {
    local refresh="${1:-0}"
    local options=(--pull)
    [ "$refresh" = "1" ] && options+=(--no-cache)

    docker build "${options[@]}" \
        --build-arg HOST_UID="$(id -u)" \
        --build-arg HOST_GID="$(id -g)" \
        -f "$SCRIPT_DIR/Dockerfile" \
        -t "$IMAGE" \
        "$REPO_ROOT"
}

grant_x_access() {
    [ -n "${DISPLAY:-}" ] || {
        echo "ERROR: DISPLAY가 비어 있습니다. X11/XWayland 세션에서 실행하세요." >&2
        exit 1
    }
    command -v xhost >/dev/null 2>&1 || {
        echo "ERROR: xhost가 없습니다. x11-xserver-utils를 설치하세요." >&2
        exit 1
    }
    local host_user
    host_user="$(id -un)"
    xhost "+SI:localuser:$host_user" >/dev/null
    trap 'xhost "-SI:localuser:$(id -un)" >/dev/null 2>&1 || true' EXIT
}

append_graphics_devices() {
    local -n args_ref="$1"
    local device gid known_gids=" "

    for device in /dev/dri/card* /dev/dri/renderD*; do
        [ -e "$device" ] || continue
        args_ref+=(--device "$device")
        gid="$(stat -c '%g' "$device")"
        if [[ "$known_gids" != *" $gid "* ]]; then
            args_ref+=(--group-add "$gid")
            known_gids+="$gid "
        fi
    done
}

run_container() {
    local mode="$1"
    local pulse_socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pulse/native"
    local arguments=(
        --rm -it
        --name "$CONTAINER"
        --init
        --ipc=host
        -e "DISPLAY=$DISPLAY"
        -e "XMODIFIERS=@im=ibus"
        -v /tmp/.X11-unix:/tmp/.X11-unix:ro
        -v "$DATA_DIR:/home/kakao/.wine-kakaotalk"
    )

    validate_data_dir
    mkdir -p "$DATA_DIR"
    grant_x_access
    append_graphics_devices arguments

    if [ -S "$pulse_socket" ]; then
        arguments+=(
            --mount "type=bind,src=$pulse_socket,dst=/tmp/pulse-native"
            -e "PULSE_SERVER=unix:/tmp/pulse-native"
        )
    else
        echo "WARN: PulseAudio 소켓이 없어 오디오 없이 실행합니다: $pulse_socket" >&2
    fi

    docker run "${arguments[@]}" "$IMAGE" "$mode"
}

command_name="${1:-help}"

case "$command_name" in
    build)
        require_docker
        build_image
        ;;
    run)
        require_docker
        run_container run
        ;;
    shell)
        require_docker
        run_container shell
        ;;
    update)
        require_docker
        build_image 1
        run_container update
        ;;
    clean)
        require_docker
        docker container rm -f "$CONTAINER" >/dev/null 2>&1 || true
        docker image rm "$IMAGE" >/dev/null 2>&1 || true
        printf '컨테이너와 이미지를 제거했습니다. 사용자 데이터는 보존했습니다: %s\n' "$DATA_DIR"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
