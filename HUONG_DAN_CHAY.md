# Hướng dẫn chạy dự án URL Shortening Service

Dự án được xây dựng trên **Ruby on Rails 8.1.3**, sử dụng **Ruby 4.0.6**, cơ sở dữ liệu **PostgreSQL** và **Redis** cho cache / Action Cable. Hỗ trợ ba cách chạy: local, Docker.

---

## Yêu cầu chung

| Công cụ | Phiên bản / ghi chú |
|---------|---------------------|
| Ruby | 4.0.6 (xem `.ruby-version`) |
| Rails | ~> 8.1.3 |
| PostgreSQL | 17 khuyến nghị, hỗ trợ 9.5+ |
| Redis | Bất kỳ phiên bản ổn định |
| Docker | Để chạy bằng Docker hoặc triển khai production |
| Node.js | Không cần, project là API backend thuần |

Lấy `RAILS_MASTER_KEY` từ file `config/master.key` trước khi chạy bất kỳ môi trường nào.

---

## 1. Chạy ở local (development)

### 1.1. Chuẩn bị môi trường

```bash
# Cài Ruby 4.0.6 (ví dụ qua rbenv, asdf hoặc rvm)
rbenv install 4.0.6
rbenv local 4.0.6

# Cài PostgreSQL + Redis
# macOS với Homebrew:
brew install postgresql redis

# Khởi động dịch vụ
brew services start postgresql
brew services start redis
```

### 1.2. Cài dependencies

```bash
cd /Users/mandythcuyen/Documents/MyProjects/url_shortening_service
bundle install
```

### 1.3. Cấu hình biến môi trường

```bash
cp .env.example .env
```

Chỉnh sửa `.env`:

```env
RAILS_MASTER_KEY=<nội dung config/master.key>
HOST=http://localhost:3000
REDIS_URL=redis://localhost:6379/0
```

### 1.4. Tạo và migrate database

```bash
bin/rails db:create db:migrate
```

### 1.5. Chạy server

```bash
bin/rails server
```

Truy cập:

```bash
curl http://localhost:3000/up
```

### 1.6. Chạy test suite

```bash
bundle exec rspec
```

### 1.7. Lệnh hữu ích

```bash
# Kiểm tra lint
bundle exec rubocop

# Kiểm tra bảo mật
bundle exec brakeman
bundle exec bundler-audit
```

---

## 2. Chạy bằng Docker (production-like)

Stack Docker bao gồm: PostgreSQL, Redis, Rails app (Puma qua Thruster) và Caddy reverse proxy với TLS tự động.

### 2.1. Cấu hình môi trường

```bash
cp .env.production.example .env.production
chmod 600 .env.production
```

Điền các giá trị sau:

```env
RAILS_MASTER_KEY=<nội dung config/master.key>
HOST=http://localhost
APP_DOMAIN=localhost
POSTGRES_USER=url_shortening_service
POSTGRES_PASSWORD=<mật khẩu tùy chọn>
POSTGRES_DB=url_shortening_service_production
```

> Với `APP_DOMAIN=localhost`, Caddy sẽ phục vụ HTTP trên `:80`.

### 2.2. Build và chạy

```bash
docker compose up --build -d
```

### 2.3. Kiểm tra trạng thái

```bash
docker compose ps
docker compose logs -f web
```

### 2.4. Truy cập

```bash
curl -I http://localhost/up
```

### 2.5. Dừng và xóa container

```bash
docker compose down
```

### 2.6. Dừng và xóa cả dữ liệu

```bash
docker compose down -v
```

---

## Lưu ý bảo mật

- Không bao giờ commit `config/master.key`, `.env`, `.env.production`, hoặc `cookies.txt`.
- `config/master.key` là bí mật duy nhất cần thiết để giải mã `config/credentials.yml.enc`.
- Mở firewall chỉ các port 22, 80 và 443 trên server production; tuyệt đối không mở 3000 hay 5432.
