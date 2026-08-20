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
      libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 \
      mesa-vulkan-drivers:amd64 mesa-vulkan-drivers:i386 \
      python3 unzip winetricks xauth xvfb \
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
    fi \
 && mkdir -p /opt/kakaotalk /usr/local/lib/kakaotalk \
 && chown -R kakao:kakao /opt/kakaotalk /usr/local/lib/kakaotalk /home/kakao

COPY --chown=kakao:kakao install.sh /usr/local/lib/kakaotalk/install.sh
COPY --chown=kakao:kakao tools /usr/local/lib/kakaotalk/tools
COPY --chown=kakao:kakao docker/entrypoint.sh /usr/local/bin/kakaotalk-entrypoint

RUN chmod +x /usr/local/lib/kakaotalk/install.sh \
             /usr/local/lib/kakaotalk/tools/extract-exe-icon.py \
             /usr/local/bin/kakaotalk-entrypoint

USER kakao
ENV HOME=/home/kakao
WORKDIR /home/kakao

RUN xvfb-run -a env \
      KAKAOTALK_PREFIX=/home/kakao/.wine-template \
      KAKAOTALK_CACHE=/home/kakao/.cache/kakaotalk-installer \
      KAKAOTALK_INSTALL_DESKTOP=0 \
      /usr/local/lib/kakaotalk/install.sh

USER root
RUN mv /home/kakao/.wine-template /opt/kakaotalk/prefix-template \
 && cp /home/kakao/.cache/kakaotalk-installer/KakaoTalk_Setup.exe \
      /opt/kakaotalk/KakaoTalk_Setup.exe \
 && chown -R kakao:kakao /opt/kakaotalk

USER kakao
ENV WINEPREFIX=/home/kakao/.wine-kakaotalk \
    WINEARCH=win64 \
    WINEDEBUG=-all \
    XMODIFIERS=@im=ibus

ENTRYPOINT ["/usr/local/bin/kakaotalk-entrypoint"]
CMD ["run"]
