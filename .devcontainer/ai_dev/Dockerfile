FROM debian:bookworm-slim

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        less \
        procps \
        ripgrep \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd \
        --uid "${USER_UID}" \
        --gid "${USER_GID}" \
        --create-home \
        --shell /bin/bash \
        "${USERNAME}" \
    && mkdir -p \
        /workspace \
        /home/${USERNAME}/.vscode-server \
        /home/${USERNAME}/.cache \
    && chown -R "${USER_UID}:${USER_GID}" \
        /workspace \
        /home/${USERNAME}

USER vscode

ENV HOME=/home/vscode

WORKDIR /workspace

CMD ["sleep", "infinity"]