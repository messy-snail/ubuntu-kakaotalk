FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
 && mkdir -pm755 /etc/apt/keyrings \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
      -o /etc/apt/keyrings/winehq-archive.key \
 && curl -fsSL \
      https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
      -o /etc/apt/sources.list.d/winehq-noble.sources \
 && apt-get update \
 && apt-get install -y --install-recommends winehq-staging \
 && apt-get install -y --no-install-recommends \
      cabextract desktop-file-utils fonts-nanum fonts-nanum-extra fonts-noto-cjk \
      python3 unzip winetricks \
 && rm -rf /var/lib/apt/lists/*

ARG HOST_UID=1000
ARG HOST_GID=1000

RUN if getent group "${HOST_GID}" >/dev/null; then \
        groupmod -n kakao "$(getent group "${HOST_GID}" | cut -d: -f1)"; \
    else \
        groupadd -g "${HOST_GID}" kakao; \
    fi \
 && if getent passwd "${HOST_UID}" >/dev/null; then \
        usermod -l kakao -d /home/kakao -m "$(getent passwd "${HOST_UID}" | cut -d: -f1)"; \
    else \
        useradd -m -u "${HOST_UID}" -g "${HOST_GID}" -s /bin/bash kakao; \
    fi

COPY --chown=kakao:kakao install.sh /usr/local/lib/kakaotalk/install.sh
COPY --chown=kakao:kakao tools /usr/local/lib/kakaotalk/tools
COPY --chown=kakao:kakao test/container-install.sh /home/kakao/container-install.sh

RUN chmod +x /usr/local/lib/kakaotalk/install.sh \
             /usr/local/lib/kakaotalk/tools/extract-exe-icon.py \
             /home/kakao/container-install.sh

USER kakao
# 이 UTF-8 로케일은 검증 마지막의 GUI 실행용이다. install.sh 자체는
# container-install.sh가 일부러 LC_ALL=C로 호출해 로케일 회귀를 잡는다.
ENV HOME=/home/kakao \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
WORKDIR /home/kakao

ENTRYPOINT ["/home/kakao/container-install.sh"]
