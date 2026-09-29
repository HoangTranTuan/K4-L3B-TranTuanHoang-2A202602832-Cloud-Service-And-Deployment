# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (Production-ready Multi-stage Dockerfile)
# ═══════════════════════════════════════════════════════════════════

# Stage 1: builder — cài đặt dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: runtime — image chạy thực tế, gọn nhẹ và bảo mật
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy thư viện từ stage builder sang runtime
COPY --from=builder /install /usr/local

# Tạo non-root user
RUN useradd --create-home --uid 10001 appuser

# Copy mã nguồn sau khi đã cài dependency (tận dụng cache layer)
COPY . .

# Chuyển sang user thường (không chạy bằng root)
USER appuser

EXPOSE 8000

# Healthcheck gọi endpoint /health
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health').read()" || exit 1

# Bind 0.0.0.0 và đọc cổng từ biến môi trường PORT (mặc định 8000)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
