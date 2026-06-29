# ── Stage 1 : builder ──────────────────────────────────────────
FROM python:3.12-slim AS builder

# Installation des dépendances de compilation pour Pillow
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY app/requirements.txt .

# Installation des dépendances Python vers le dossier /install
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2 : image finale ────────────────────────────────────
FROM python:3.12-slim AS runtime

# Installation des bibliothèques runtime nécessaires (pour Pillow)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg62-turbo \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Création de l'utilisateur non-root
RUN useradd --no-create-home --uid 1001 appuser

WORKDIR /app

# Copie des packages installés depuis le builder
COPY --from=builder /install /usr/local
COPY app/ .

USER appuser
EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]