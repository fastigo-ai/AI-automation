# --- Stage 1: Builder ---
FROM python:3.11-slim-bookworm AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Install Python requirements into a local directory
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# --- Stage 2: Runner ---
FROM python:3.11-slim-bookworm AS runner

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV PATH="/install/bin:${PATH}"

# Install runtime dependencies for Playwright/Chromium
# These are only the libraries needed for execution, not building
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libx11-xcb1 \
    libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /install

# Copy application code
COPY . .

# Install Playwright browsers (in the runner stage so they persist)
# We only install Chromium to keep it lightweight
RUN playwright install chromium

# Expose the API port
EXPOSE 8000

# Start command
CMD ["python", "api/server.py"]
