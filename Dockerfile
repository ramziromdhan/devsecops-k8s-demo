# ── Stage 1 : builder ──────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build
COPY app/requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2 : image finale ────────────────────────────────────
FROM python:3.12-slim AS runtime

# Ne pas tourner en root — bonne pratique sécurité dès le départ
RUN useradd --no-create-home --uid 1001 appuser

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ .

USER appuser
EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]