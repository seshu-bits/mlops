# Use local Python base image (no external registry dependency)
# This base is built from Dockerfile.base using Red Hat UBI or Alma Linux base
# For Alma Linux 8: use Dockerfile.almalinux directly instead
# Build the base first: eval $(minikube docker-env) && docker build -t local-python-base:3.11 -f Dockerfile.base .
# OR use the Alma-native version: docker build -t heart-disease-api:latest -f Dockerfile.almalinux .
FROM local-python-base:3.11

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip, setuptools, and wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies with verbose output
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY api_server.py .
COPY artifacts/ ./artifacts/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["uvicorn", "api_server:app", "--host", "0.0.0.0", "--port", "8000"]
