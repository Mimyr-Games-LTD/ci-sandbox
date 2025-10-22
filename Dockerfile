# Базируемся на официальном godot-ci стиле, но ставим Spine editor + templates
FROM ubuntu:noble
LABEL author="https://github.com/aBARICHELLO/godot-ci/graphs/contributors"

USER root
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# ---- База ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    unzip \
    wget \
    zip \
    adb \
    openjdk-17-jdk-headless \
    rsync \
    osslsigncode \
    wine64 \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# ---- Версии ----
ARG GODOT_VERSION="4.4.1"
ARG RELEASE_NAME="stable"        
ARG SPINE_VERSION="4.2"
# S3 cборки spine-godot
ARG SPINE_BASE_URL="https://spine-godot.s3.eu-central-1.amazonaws.com/${SPINE_VERSION}/${GODOT_VERSION}-${RELEASE_NAME}"

# ---- Заглушки, как в шаблоне ----
ARG GODOT_TEST_ARGS=""
ARG GODOT_PLATFORM="linux.x86_64"

# ---- Ставим Spine Godot editor ----
RUN set -eux; \
    wget -O /tmp/godot-editor-linux.zip "${SPINE_BASE_URL}/godot-editor-linux.zip"; \
    unzip -q /tmp/godot-editor-linux.zip -d /tmp/godot; \
    GODOT_BIN="$(find /tmp/godot -maxdepth 2 -type f -iname 'godot*' | head -n1)"; \
    test -n "$GODOT_BIN"; \
    install -m 0755 "$GODOT_BIN" /usr/local/bin/godot; \
    rm -rf /tmp/godot /tmp/godot-editor-linux.zip; \
    godot --version || true

# ---- Ставим Spine export templates и раскладываем их в оба HOME ----
RUN set -eux; \
    mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}; \
    mkdir -p /github/home/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}; \
    wget -O /tmp/spine-templates.tpz "${SPINE_BASE_URL}/spine-godot-templates-${SPINE_VERSION}-${GODOT_VERSION}-${RELEASE_NAME}.tpz"; \
    mkdir -p /tmp/tpl && unzip -q /tmp/spine-templates.tpz -d /tmp/tpl; \
    if [ -d /tmp/tpl/templates ]; then \
      rsync -a /tmp/tpl/templates/ /root/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/; \
      rsync -a /tmp/tpl/templates/ /github/home/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/; \
    else \
      rsync -a /tmp/tpl/ /root/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/; \
      rsync -a /tmp/tpl/ /github/home/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/; \
    fi; \
    rm -rf /tmp/tpl /tmp/spine-templates.tpz; \
    ls -la /root/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} || true; \
    ls -la /github/home/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} || true

# ---- rcedit для Windows-экспорта ----
RUN set -eux; \
    mkdir -p /opt/rcedit; \
    wget -O /opt/rcedit/rcedit-x64.exe https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe

# ---- Android SDK (как в шаблоне) ----
ENV ANDROID_HOME="/usr/lib/android-sdk"
RUN wget -O /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    && mkdir -p ${ANDROID_HOME} \
    && unzip -q /tmp/commandlinetools.zip -d /tmp/cmdline-tools \
    && mv /tmp/cmdline-tools ${ANDROID_HOME}/cmdline-tools \
    && rm -f /tmp/commandlinetools.zip
ENV PATH="${ANDROID_HOME}/cmdline-tools/cmdline-tools/bin:${PATH}"
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "build-tools;33.0.2" "platforms;android-33" "cmdline-tools;latest" "cmake;3.22.1" "ndk;25.2.9519653"

# ---- Debug keystore (как в шаблоне) ----
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore /root/debug.keystore -storepass android \
    -dname "CN=Android Debug,O=Android,C=US" -validity 9999

# ---- Прогон редактора один раз (генерация базовых настроек) ----
RUN godot -v -e --quit --headless ${GODOT_TEST_ARGS} || true

# ---- EditorSettings: пишем ОДНОВРЕМЕННО для /root И для /github/home ----
# Начиная с Godot 4.3 настройки версионируются по мажор.минор → editor_settings-4.4.tres для 4.4.x
RUN set -eux; \
    V_SHORT="${GODOT_VERSION%.*}"; \
    for H in /root /github/home; do \
      mkdir -p "$H/.config/godot"; \
      ES="$H/.config/godot/editor_settings-${V_SHORT}.tres"; \
      echo '[gd_resource type="EditorSettings" format=3]' > "$ES"; \
      echo '[resource]' >> "$ES"; \
      echo 'export/android/java_sdk_path = "/usr/lib/jvm/java-17-openjdk-amd64"' >> "$ES"; \
      echo 'export/android/android_sdk_path = "/usr/lib/android-sdk"' >> "$ES"; \
      echo 'export/android/debug_keystore = "/root/debug.keystore"' >> "$ES"; \
      echo 'export/android/debug_keystore_user = "androiddebugkey"' >> "$ES"; \
      echo 'export/android/debug_keystore_pass = "android"' >> "$ES"; \
      echo 'export/android/force_system_user = false' >> "$ES"; \
      echo 'export/android/timestamping_authority_url = ""' >> "$ES"; \
      echo 'export/android/shutdown_adb_on_exit = true' >> "$ES"; \
      # важное: Windows экспорт (rcedit + wine)
      echo 'export/windows/rcedit = "/opt/rcedit/rcedit-x64.exe"' >> "$ES"; \
      # в GH Actions иногда /usr/bin/wine64 недоступен под этим путём — на всякий случай продублируем:
      if [ -x /usr/bin/wine64 ]; then \
        echo 'export/windows/wine = "/usr/bin/wine64"' >> "$ES"; \
      else \
        echo 'export/windows/wine = "/usr/bin/wine"' >> "$ES"; \
      fi; \
      cat "$ES"; \
    done

# ---- Жёсткая проверка наличия Windows шаблонов в ОБОИХ домах ----
RUN test -f "/root/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/windows_debug_x86_64.exe" \
 && test -f "/root/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/windows_release_x86_64.exe" \
 && test -f "/github/home/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/windows_debug_x86_64.exe" \
 && test -f "/github/home/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}/windows_release_x86_64.exe" \
 && echo "Windows export templates OK under both /root and /github/home"


RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh \
  | sh -s -- -b /usr/local/bin

RUN ln -sf /usr/bin/python3 /usr/bin/python

ARG REQUIREMENTS_TMP_PATH="/tmp/requirements.txt"
COPY requirements.txt "${REQUIREMENTS_TMP_PATH}"
RUN pip install --no-cache-dir -r "${REQUIREMENTS_TMP_PATH}"