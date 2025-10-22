# Базовый лёгкий образ; можно заменить на свой
FROM ubuntu:22.04

LABEL maintainer="naxa1ka"
ENV DEBIAN_FRONTEND=noninteractive
# Очень важно: в контейнере GH Actions HOME=/github/home
ENV HOME=/github/home
ENV PATH="/usr/local/bin:${PATH}"

# ---------- Базовые пакеты ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip zip rsync xvfb fontconfig \
    python3 python3-pip python3-venv git git-lfs \
    wine64 osslsigncode imagemagick \
 && rm -rf /var/lib/apt/lists/*

# ---------- Аргументы версии ----------
ARG SPINE_VERSION="4.2"
ARG GODOT_VERSION="4.4.1"
ARG GODOT_CHANNEL="stable"
ARG SPINE_BASE_URL="https://spine-godot.s3.eu-central-1.amazonaws.com/${SPINE_VERSION}/${GODOT_VERSION}-${GODOT_CHANNEL}"

ARG GODOT_INSTALL_PATH="/usr/local/bin/godot"
ARG GODOT_TEMPLATES_ROOT="${HOME}/.local/share/godot/export_templates"

# ---------- Установка Spine-Godot (editor) ----------
RUN set -eux; \
    tmpdir="$(mktemp -d)"; cd "$tmpdir"; \
    echo "Downloading Spine Godot editor: ${SPINE_BASE_URL}/godot-editor-linux.zip"; \
    curl -fLO "${SPINE_BASE_URL}/godot-editor-linux.zip"; \
    unzip -q godot-editor-linux.zip; \
    GODOT_BIN="$(find . -maxdepth 2 -type f -iname 'godot*' | head -n1)"; \
    test -n "$GODOT_BIN"; \
    install -m 0755 "$GODOT_BIN" "${GODOT_INSTALL_PATH}"; \
    rm -rf "$tmpdir"; \
    "${GODOT_INSTALL_PATH}" --version || true

# ---------- Установка export-templates (Spine) ----------
RUN set -eux; \
    templates_dir="${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}"; \
    mkdir -p "$templates_dir"; \
    tmpdir="$(mktemp -d)"; cd "$tmpdir"; \
    tpz_name="spine-godot-templates-${SPINE_VERSION}-${GODOT_VERSION}-${GODOT_CHANNEL}.tpz"; \
    echo "Downloading Spine export templates: ${SPINE_BASE_URL}/${tpz_name}"; \
    curl -fLO "${SPINE_BASE_URL}/${tpz_name}"; \
    unzip -q "$tpz_name"; \
    if [ -d templates ]; then rsync -a templates/ "$templates_dir/"; else rsync -a ./ "$templates_dir/"; fi; \
    rm -rf "$tmpdir"; \
    echo "Installed templates to: $templates_dir"; \
    ls -la "$templates_dir" || true

# ---------- rcedit + Editor Settings ----------
RUN set -eux; \
    mkdir -p /opt/rcedit; \
    wget -O /opt/rcedit/rcedit-x64.exe https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe; \
    mkdir -p "${HOME}/.config/godot"; \
    printf '%s\n' \
      '[gd_resource type="EditorSettings" format=3]' \
      '' \
      '[resource]' \
      'export/windows/rcedit="/opt/rcedit/rcedit-x64.exe"' \
      'export/windows/wine="/usr/bin/wine64"' \
      > "${HOME}/.config/godot/editor_settings-4.tres"; \
    echo "Editor settings at ${HOME}/.config/godot/editor_settings-4.tres:"; \
    cat "${HOME}/.config/godot/editor_settings-4.tres"

# ---------- (опционально) helper для иконки ----------
RUN set -eux; \
    mkdir -p /opt/rcedit/bin; \
    echo 'convert "$1" -define icon:auto-resize=256,128,64,48,32,16 /tmp/icon.ico && wine "/opt/rcedit/rcedit-x64.exe" "$2" --set-icon /tmp/icon.ico' > /opt/rcedit/bin/set-icon; \
    chmod +x /opt/rcedit/bin/set-icon

# ---------- Удобства ----------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------- Smoke test (падает = сразу увидим проблему сборки образа) ----------
RUN godot --version || true \
 && test -f "${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}/windows_debug_x86_64.exe" \
 && test -f "${GODOT_TEMPLATES_ROOT}/${GODOT_VERSION}.${GODOT_CHANNEL}/windows_release_x86_64.exe" \
 && echo "Export templates: OK; HOME=${HOME}"
