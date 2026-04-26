FROM python:3.10-slim

# Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# Copy file requirements từ thư mục src/ vào thư mục hiện tại của container (.)
COPY src/requirements.txt .

# Cài đặt thư viện
RUN pip install --no-cache-dir -r requirements.txt

# Copy file code từ thư mục src/ vào thư mục hiện tại của container
COPY src/ingestion.py .

# Chạy script
CMD ["python", "ingestion.py"]