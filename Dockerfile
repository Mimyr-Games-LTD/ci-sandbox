FROM ubuntu:22.04

LABEL maintainer="naxa1ka"

ENV DEBIAN_FRONTEND=noninteractive 
ENV PATH="/usr/local/bin:${PATH}"

# ---------- Base packages ----------
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
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# ---------- Args ----------
ARG SPINE_VERSION="4.2"
ARG GODOT_VERSION="4.4.1"
ARG GODOT_CHANNEL="stable"
ARG SPINE_BASE_URL="https://spine-godot.s3.eu-central-1.amazonaws.com/${SPINE_VERSION}/${GODOT_VERSION}-${GODOT_CHANNEL}"

ARG GODOT_INSTALL_PATH="/usr/local/bin/godot"
ARG GODOT_TEMPLATES_ROOT="/root/.local/share/godot/export_templates"

# ---------- Godot (Spine editor) ----------
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

# ---------- Export templates (Spine build) ----------
# Важно: раскладываем файлы прямо в ~/.local/share/godot/export_templates/4.4.1.stable/
RUN set -eux; \
    templates_dir="${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}"; \
    mkdir -p "$templates_dir"; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    tpz_name="spine-godot-templates-${SPINE_VERSION}-${GODOT_VERSION}-${GODOT_CHANNEL}.tpz"; \
    echo "Downloading Spine export templates: ${SPINE_BASE_URL}/${tpz_name}"; \
    curl -fLO "${SPINE_BASE_URL}/${tpz_name}"; \
    unzip -q "$tpz_name"; \
    # В tpz обычно папка templates/ – переносим её содержимое в каталог версии
    if [ -d templates ]; then rsync -a templates/ "$templates_dir/"; else rsync -a ./ "$templates_dir/"; fi; \
    rm -rf "$tmpdir"; \
    echo "Installed templates to: $templates_dir"; \
    ls -la "$templates_dir" || true

# ---------- rcedit + Godot editor settings ----------
# Ставим rcedit в /opt/rcedit/rcedit-x64.exe и прописываем wine и rcedit в editor_settings-4.tres
RUN set -eux; \
    mkdir -p /opt/rcedit; \
    wget -O /opt/rcedit/rcedit-x64.exe https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe; \
    mkdir -p /root/.config/godot; \
    printf '%s\n' \
      '[gd_resource type="EditorSettings" format=3]' \
      '' \
      '[resource]' \
      'export/windows/rcedit="/opt/rcedit/rcedit-x64.exe"' \
      'export/windows/wine="/usr/bin/wine64"' \
      > /root/.config/godot/editor_settings-4.tres; \
    echo "Editor settings written to /root/.config/godot/editor_settings-4.tres"; \
    cat /root/.config/godot/editor_settings-4.tres

# ---------- (Опционально) helper для установки иконки через ImageMagick + wine+rcedit ----------
RUN set -eux; \
    mkdir -p /opt/rcedit/bin; \
    echo 'convert "$1" -define icon:auto-resize=256,128,64,48,32,16 /tmp/icon.ico && wine "/opt/rcedit/rcedit-x64.exe" "$2" --set-icon /tmp/icon.ico' > /opt/rcedit/bin/set-icon; \
    chmod +x /opt/rcedit/bin/set-icon

# ---------- Butler (itch.io) ----------
RUN set -eux; \
    mkdir -p /opt/butler; \
    wget -O /opt/butler/butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default; \
    unzip /opt/butler/butler.zip -d /opt/butler; \
    rm -rf /opt/butler/butler.zip; \
    chmod +x /opt/butler/butler; \
    /opt/butler/butler -V

# ---------- reviewdog ----------
RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh \
  | sh -s -- -b /usr/local/bin

# ---------- Python symlink ----------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------- Python requirements (если нужны в CI) ----------
ARG REQUIREMENTS_TMP_PATH="/tmp/requirements.txt"
COPY requirements.txt "${REQUIREMENTS_TMP_PATH}"
RUN pip install --no-cache-dir -r "${REQUIREMENTS_TMP_PATH}"

# ---------- Smoke test ----------
# Не критично, но полезно для раннего падения, если что-то не так
RUN godot --version || true \
 && test -f "${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}/windows_debug_x86_64.exe" \
 && test -f "${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}/windows_release_x86_64.exe" \
 && echo "Export templates OK"
