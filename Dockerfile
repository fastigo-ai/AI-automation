# --- Stage 1: Builder ---
FROM python:3.11-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# --- Stage 2: Runner ---
FROM python:3.11-slim-bookworm AS runner

# 1. Environment
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PATH="/install/bin:${PATH}" \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# 2. Install runtime deps + curl (for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    libnss3 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 libasound2 \
    libpangocairo-1.0-0 libx11-xcb1 libxshmfence1 libglib2.0-0 \
    libgtk-3-0 fonts-liberation libu2f-udev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 3. Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser \
    && mkdir -p /app /ms-playwright \
    && chown -R appuser:appuser /app /ms-playwright

WORKDIR /app

# 4. Copy dependencies + code
COPY --from=builder /install /install
COPY --chown=appuser:appuser . .

# 5. Switch to non-root user
USER appuser

# 6. Install browser safely
RUN playwright install chromium --no-deps

EXPOSE 8000

# 7. Proper init system
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["python", "api/server.py"]

# 8. Healthcheck (now curl exists)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/api/status || exit 1