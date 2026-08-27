# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Install dependencies into a virtual environment so only what we need is
# copied to the final image (keeps the final layer small and avoids build tools).
FROM python:3.12-slim AS builder

WORKDIR /app

RUN python -m venv .venv
COPY requirements.txt .
RUN .venv/bin/pip install --upgrade pip && \
    .venv/bin/pip install --no-cache-dir -r requirements.txt

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# Non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app

# Copy only the pre-built venv from builder
COPY --from=builder /app/.venv .venv

# Copy application source
COPY app/ ./app/

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "2", "app.main:app"]
