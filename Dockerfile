FROM ubuntu:22.04

LABEL maintainer="naxa1ka"

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    zip \
    unzip \
    wget \
    xvfb \
    rsync \
    python3 \
    python3-venv \
    python3-pip \
    fontconfig \
    curl \
    wine64 \
    osslsigncode \
    && rm -rf /var/lib/apt/lists/*

ARG SPINE_VERSION="4.2"
ARG GODOT_VERSION="4.4.1"
ARG GODOT_CHANNEL="stable"
ARG SPINE_BASE_URL="https://spine-godot.s3.eu-central-1.amazonaws.com/${SPINE_VERSION}/${GODOT_VERSION}-${GODOT_CHANNEL}"

ARG GODOT_INSTALL_PATH="/usr/local/bin/godot"
ARG GODOT_TEMPLATES_ROOT="/root/.local/share/godot/export_templates"
ENV PATH="/usr/local/bin:${PATH}"

RUN set -eux; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    echo "Downloading Spine Godot editor: ${SPINE_BASE_URL}/godot-editor-linux.zip"; \
    curl -fLO "${SPINE_BASE_URL}/godot-editor-linux.zip"; \
    unzip -q godot-editor-linux.zip; \
    GODOT_BIN="$(find . -maxdepth 2 -type f -iname 'godot*' | head -n1)"; \
    test -n "$GODOT_BIN"; \
    install -m 0755 "$GODOT_BIN" "${GODOT_INSTALL_PATH}"; \
    rm -rf "$tmpdir"; \
    "${GODOT_INSTALL_PATH}" --version || true

RUN set -eux; \
    templates_dir="${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}"; \
    mkdir -p "$templates_dir"; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    tpz_name="spine-godot-templates-${SPINE_VERSION}-${GODOT_VERSION}-${GODOT_CHANNEL}.tpz"; \
    echo "Downloading Spine export templates: ${SPINE_BASE_URL}/${tpz_name}"; \
    curl -fLO "${SPINE_BASE_URL}/${tpz_name}"; \
    unzip -q "$tpz_name" -d "$templates_dir"; \
    rm -rf "$tmpdir"; \
    echo "Installed templates to: $templates_dir"; \
    ls -la "$templates_dir" || true

RUN wget https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe -O /opt/rcedit.exe
RUN echo 'export/windows/rcedit = "/opt/rcedit.exe"' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/windows/wine = "/usr/bin/wine64-stable"' >> ~/.config/godot/editor_settings-4.tres

RUN mkdir -p /opt/butler
RUN wget -O /opt/butler/butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
RUN unzip /opt/butler/butler.zip -d /opt/butler
RUN rm -rf /opt/butler/butler.zip
RUN ls /opt/butler
RUN chmod +x /opt/butler/butler
RUN /opt/butler/butler -V

RUN echo "convert \$1 -define icon:auto-resize=256,128,64,48,32,16 /tmp/icon.ico && wine /opt/rcedit/rcedit-x64.exe \$2 --set-icon /tmp/icon.ico" > /opt/rcedit/bin/set-icon
RUN chmod +x /opt/rcedit/bin/set-icon

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh \
  | sh -s -- -b /usr/local/bin



RUN ln -sf /usr/bin/python3 /usr/bin/python

ARG REQUIREMENTS_TMP_PATH="/tmp/requirements.txt"
COPY requirements.txt "${REQUIREMENTS_TMP_PATH}"
RUN pip install --no-cache-dir -r "${REQUIREMENTS_TMP_PATH}"
