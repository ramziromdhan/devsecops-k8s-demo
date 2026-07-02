# ── Stage 1 : builder ──────────────────────────────────────────
# Utilise une version précise de Python — c'est ça la vraie sécurité
FROM python:3.12.5-slim AS builder

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY app/requirements.txt .

# --prefix isole les packages pour les copier proprement dans runtime
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2 : image finale ─────────────────────────────────────
# Même version de base que le builder pour cohérence
FROM python:3.12.5-slim AS runtime

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg62-turbo \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Utilisateur non-root — principe de moindre privilège
RUN useradd --no-create-home --uid 1001 appuser

WORKDIR /app

# Copie uniquement les packages Python installés, pas les outils de compilation
COPY --from=builder /install /usr/local
COPY app/ .

USER appuser
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]