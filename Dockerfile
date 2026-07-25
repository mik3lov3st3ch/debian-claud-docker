FROM debian:bookworm-slim

# Nicht-interaktive Installation, keine empfohlenen Pakete
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=Europe/Vienna

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        tzdata \
        gnupg \
        git \
        ripgrep \
        procps \
        less \
        jq \
        unzip \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS (Voraussetzung für Claude Code) über NodeSource installieren
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI global installieren
RUN npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# Non-Root-User anlegen (UID/GID zur Laufzeit überschreibbar)
ARG APP_UID=1000
ARG APP_GID=1000
RUN groupadd -g ${APP_GID} app \
    && useradd -m -u ${APP_UID} -g ${APP_GID} -s /bin/bash app

WORKDIR /app

# Eigene Dateien ins Image kopieren (Verzeichnis "app/" neben dem Dockerfile)
# COPY --chown=app:app app/ /app/

USER app

# Claude Code legt Konfiguration/Login unter ~/.claude ab.
# Beim Starten des Containers dieses Verzeichnis als Volume mounten, damit der
# Login erhalten bleibt, z. B.: -v claude-config:/home/app/.claude
# Authentifizierung wahlweise per "claude login" im Container oder über
# eine zur Laufzeit gesetzte Umgebungsvariable ANTHROPIC_API_KEY.
VOLUME ["/home/app/.claude"]

# Einfacher Healthcheck – bei einer echten App auf deren Endpoint umstellen
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fsS http://localhost:8080/health || exit 1

# Platzhalter: hält den Container am Leben, damit du dich einloggen kannst.
# Später z. B. durch: CMD ["./start.sh"] ersetzen
CMD ["sleep", "infinity"]
