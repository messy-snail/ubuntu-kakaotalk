FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      wine winetricks \
      curl tar xz-utils ca-certificates \
      cabextract p7zip-full unzip \
      fonts-noto-cjk \
      sudo \
 && rm -rf /var/lib/apt/lists/*

ARG HOST_UID=1000
ARG HOST_GID=1000

RUN if getent group "${HOST_GID}" >/dev/null; then \
        groupmod -n kakao "$(getent group ${HOST_GID} | cut -d: -f1)"; \
    else \
        groupadd -g "${HOST_GID}" kakao; \
    fi \
 && if getent passwd "${HOST_UID}" >/dev/null; then \
        usermod -l kakao -d /home/kakao -m "$(getent passwd ${HOST_UID} | cut -d: -f1)"; \
    else \
        useradd -m -u "${HOST_UID}" -g "${HOST_GID}" -s /bin/bash kakao; \
    fi

USER kakao
WORKDIR /home/kakao

RUN mkdir -p /home/kakao/.cache/kakaotalk-installer \
             /home/kakao/.cache/winetricks \
             /home/kakao/.local/share/wine-runners \
             /home/kakao/.local/bin

COPY --chown=kakao:kakao container-install.sh /home/kakao/install.sh
RUN chmod +x /home/kakao/install.sh

ENTRYPOINT ["/home/kakao/install.sh"]
