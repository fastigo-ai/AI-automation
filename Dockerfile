FROM mcr.microsoft.com/playwright/python:v1.42.0

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install Python deps first (better caching, lower rebuild cost)
COPY requirements.txt .
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt

# Copy app
COPY . .

# Run app
CMD ["python", "api/server.py"]