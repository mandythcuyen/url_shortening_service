# README

Những nội dung được ghi trong README
* Các vấn đề về bảo mật và hướng xử lý
* Khả năng mở rộng và xử lý collision
* Test coverage
* AI disclosure
> Lưu ý: Hướng dẫn chi tiết cách chạy assignment: file SETUP.md

# A. Các vấn đề về bảo mật và hướng xử lý
 (vấn đề XSS, SQL injection, CSRF, bảo mật key / mã hóa, mass asignment, session hijacking, bảo vệ thông tin nhạy cảm, bảo vệ khỏi các cuộc cào dữ liệu hoặc thuật toán dễ đoán)
> Liệt kê các tình huống attack (attack vectors) và ý tưởng protect:
### 1. XSS
* Cách thức tấn công: Gửi `<script>` trong URL, API trả lại không escape
* Biện pháp bảo vệ: Rails API auto-escape JSON, không render HTML. Swagger UI set Content-Type: application/json
### 2. SQL Injection
* Cách thức tấn công: Gửi SQL injection (ví dụ: nhập payload SQL trong URL hoặc short_code) để inject vào query
* Biện pháp bảo vệ: Dùng ActiveRecord parameterized queries, ví dụ: where(short_code: params[:short_code]), tuyệt đối không dùng find_by_sql hoặc raw SQL với string interpolation mà không có sự dè chừng
### 3. CSRF
* Cách thức tấn công: Gửi request từ domain khác để thao tác với API. Dùng session cookie nếu api sensitive.
* Biện pháp bảo vệ: Rails API mode dùng null_session; protect_from_forgery nếu có form web
### 4. Bảo mật key / mã hóa
* Cách thức tấn công: Lấy key / mã hóa từ source code hoặc environment variables
* Biện pháp bảo vệ: Sử dụng environment variables để lưu key / mã hóa, không để lộ key / mã hóa trong source code, attach/ set thủ công trên server
### 5. Mass assignment
* Cách thức tấn công: Gửi thêm parameter không mong muốn trong request để thay đổi attribute không mong muốn. Ví dụ gửi thêm params như id, short_code, v.v hoặc những param có thể chiếm quyền admin
* Biện pháp bảo vệ: Sử dụng strong parameters, chỉ cho phép parameter mong muốn. Ví dụ: params.require(:url).permit(:url) - chỉ permit url
### 6. Session hijacking
* Cách thức tấn công: Lấy session token từ cookie hoặc header để thao tác với API (đánh cắp & làm giả)
* Biện pháp bảo vệ: Cookie HttpOnly, Secure, SameSite=Strict/Lax, encrypt bằng Rails secret. session_token sinh random khi lần đầu và nên regenerates sau encode
### 7. Brute-force tìm short code + Bảo vệ khỏi các cuộc cào dữ liệu hoặc thuật toán dễ đoán
* Cách thức tấn công: Dò hàng loạt http://domain/AAAAAAA
* Biện pháp bảo vệ: Dùng Rack::Attack để giới hạn request theo IP. Ví dụ 100 request/phút cho decode/redirect), trả 429 Too Many Requests. short_code dài 7 ký tự SecureRandom.alphanumeric(7) ngẫu nhiên, lấy từ SecureRandom hầu như là không thể đoán được thuật toán. Không expose danh sách.
### 8. Mass submission / spam encode
* Cách thức tấn công: Bot tạo hàng nghìn link
* Biện pháp bảo vệ: Rack::Attack giới hạn POST /encode 10 request/1 phút/IP. Có thể thêm hidden honeypot field để detect bot, hoặc cooldown giữa các request
### 9. Open Redirect
* Cách thức tấn công: Redirect đến domain độc hại. Hoặc tạo short_link tới javascript:void(0) hoặc javascript:alert(1), hoặc //evil
* Biện pháp bảo vệ: Validate domain đích bằng URI.parse, chỉ cho phép schem http/https. Khi redirect, dùng URI.parse lại và từ chối scheme khác. 
## 10. SSRF nội bộ
* Cách thức tấn công: Sever tự gọi URL đích
* Biện pháp bảo vệ: Không gọi URL đích ở server, chỉ redirect client-site
### 11. Phishing / URL ẩn danh
* Cách thức tấn công: Rút gọn URL độc hại, 
* Biện pháp bảo vệ: Kiểm tra blacklist domain, từ chối URL chưa IP private như 127.0.0.1, 10.x.x.x, 192.168.x.x, 172.16.x.x
### 12. DoS qua payload lớn
* Cách thức tấn công: Gửi request với payload quá lớn (hàng MB)
* Biện pháp bảo vệ: Giới hạn kích thước request body trong Puma/Nginx (ví dụ: 4KB), validate kích thước URL không được quá 2048 ký tự.
### 13. Timing attack đoán short_code (so sánh thời gian phản hồi)
* Cách thức tấn công: Đo thời gian phản hồi để suy ra thông tin (ví dụ: kiểm tra tồn tại user). Không đáng kể ở bài này nhưng tránh dùng kiểu if exist? ... else create ... ngoài DB
* Biện pháp bảo vệ: Sử dụng so sánh thời gian cố định (constant-time comparison) để tránh timing leak, ví dụ có thể dùng insert với unique index + dùng retry, hoặc find_or_create_by có xử lý exception ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
### 14. Leak thông tin qua log
* Cách thức tấn công: Log chứa thông tin nhạy cảm
* Biện pháp bảo vệ: Không log URL gốc, chỉ log short_code và metadata không nhạy cảm. Cấu hình config/filter_parameters trong Rails để filter các field nhạy cảm như password, token, api_key. Không log full URL trong production.


# B. Khả năng mở rộng
## Tối ưu tốc độ
### Cấu hình DB và index phù hợp
* Sử dụng unique index trên short_code để tránh race condition và tăng tốc độ tìm kiếm
`add_index :short_links, :short_code, unique: true, name: "index_short_links_on_short_code"`
* Vì thường xuyên lookup cặp này session_token + original_url (để lấy short_code), nên thêm index cho cặp này, tuy nhiên original_url có thể dài nên dùng original_url_hash để tối ưu kích thước index giúp query nhanh hơn
`add_index :short_links, [:session_token, :original_url_hash], unique: true, name: "index_short_links_on_session_token_and_original_url_hash"`
* Khi tìm kiếm dùng pick để chỉ lấy short_code thay vì select * (phát sinh pluck) `original_url = ::ShortLink.where(short_code: short_code).pick(:original_url)`

### Caching
> Ý tưởng: Giúp giảm tải cho database bằng cách cache các truy vấn thường xuyên
* Sử dụng Redis để cache 2 loại sau:
i. short_code -> original_url (decode/redirect) - TTL dài 30 ngày
ii. session_token + original_url -> short_code (same-user -> re-encode) - có thể đặt TTL ngắn thôi (ví dụ: 5 phút)
* Rails cache store: redis_cache_store

### Tối ưu khác - Dọn dẹp link quá "cũ kỹ":
> Ý tưởng: Dọn dẹp expired cache và expired short links định kỳ
khi có quá nhiều record được tạo tại database postgresql và redis, cơ chế clear (expired) thì hướng giải quyết như nào
* PostgreSQL: dữ liệu nhiều + cần dọn dẹp
  - i. Thêm cột expires_at hoặc last_accessed_at. Tùy tình huống user sử dụng, cập nhật last_accessed_at để biết link nào còn sống.
  - ii. Background job dọn dẹp định kỳ: Tạo 1 background job (ví dụ Sidekiq) chạy định kỳ (ví dụ mỗi đêm) để xóa các record expired. ví dụ expires_at < NOW() hoặc last_accessed_at < 1.year.ago. Nên xóa hàng loạt bằng LIMIT để tránh lock bảng quá lâu.
  - iii. Partition theo thời gian: chia table thành các partition theo tháng/năm để dễ xóa data cũ. Khi hết hạn, có thể DROP PARTITION hoặc TRUNCATE nhanh hơn xóa từng dòng.
  - iv. Archiving trước khi xóa: chuyển sang lưu chỗ rẻ hơn 1 thời gian trước khi xóa hẳn
* Redis: dữ liệu cache + tự động expired. 
  - Set ttl (expires_in) cho cache key, Redis sẽ tự xóa key khi hết hạn.
  - Redis có cơ chế cho chọn eviction policy phù hợp, ví dụ: allkeys-lru	-> Xóa key ít dùng gần đây nhất
  - Key naming theo pattern để dọn dẹp dễ. Ví dụ trong dự án này: `decode:GeAi9K` và 
`encode:<session_id>:https://example.com`. Khi cần xóa toàn bộ decode cache, dùng SCAN + DEL: ví dụ `redis.scan_each(match: "decode:<....>") { |key| redis.del(key) }`
* Vấn đề: Nếu mỗi lần redirect đều UPDATE PostgreSQL để cập nhật last_accessed_at, thì sẽ mất lợi ích của Redis vì vẫn gây write vào DB liên tục. Hướng tối ưu là đọc từ Redis, nhưng ghi thống kê vào Redis trước, rồi flush về PostgreSQL theo batch định kỳ. Cấu trúc ví dụ: 
  ```ruby
  decode:{short_code} => original_url (TTL 24h)
  click:{short_code} => integer (tổng click từ lần sync trước)
  access_log:{short_code} => list timestamp (các lần truy cập)
  ```
  Sau đó, đồng bộ thống kê về PostgreSQL bằng background job (cứ mỗi N phút hoặc khi list đủ lớn, chạy job). Nên sử dụng batch update để tránh lock bảng quá lâu.

## Xử lý vấn đề collision (race condition)
> Ý tưởng: Khi có collision (cùng short_code được tạo), hệ thống cần xử lý để đảm bảo tính duy nhất và không mất dữ liệu.
* Khi tạo short_code, kiểm tra xem short_code đã tồn tại chưa. Nếu tồn tại, thì tạo short_code mới cho đến khi không trùng. (retry, rescue, MAX_RETRIES, ...)
* Có thể sử dụng retry logic với backoff để tránh collision liên tục. (MAX_RETRIES)
* Có thể sử dụng phương án mã hóa khó dò thuật toán, ổn định và hạn chế khả năng collision để đảm bảo tính duy nhất.

## Scale
* Sharding theo ký tự đầu short code ví dụ như A->Z, 0->9 để phân bố dữ liệu đều hơn và dễ quản lý.
* Generate trước pool của short_code bằng Background job để tránh collision và tăng tốc độ tạo short_code, insert nhanh hơn.
* Sử dụng CDN (CloudFront) để cache response và giảm tải traffic cho server. Ví dụ: lần đầu Request có thể cần đi tới Rails/Redis/DB, CloudFront có thể lưu response đó, sau đó lần sau không cần đi tới Rails/Redis/DB nữa.
* Read Replicas: Hiện tại hệ thống dùng Redis để giảm database reads. Nếu traffic tiếp tục tăng, có thể tiếp tục scale database bằng cách thêm Read Replicas để phân tán các truy vấn đọc.

# Kiểm thử
* Unit: ShortLink model validations, EncoderService, DecoderService.
* Integration/Request: POST /api/v1/encode, GET /api/v1/decode, GET /:short_code.
* Rswag specs: vừa là docs vừa là test.
* Edge cases:
   * Cùng session + cùng URL → trả cùng short code.
   * Session khác + cùng URL → tạo mới.
   * Invalid URL.
   * Duplicate short_code sinh ra (stub SecureRandom để test retry).
   * Brute force trả 429.
   * Open redirect bị chặn.
* Công cụ QC
   * RSpec: Unit + integration tests.
   * Factory Bot: Test data.
   * Brakeman: Scan lỗ hổng Rails.
   * bundler-audit: Kiểm tra gem có CVE.
   * Bullet: Phát hiện N+1.
   * RuboCop / Rubocop-Rails: Code style, best practice.
   * Rack::Attack: Rate limiting.
   * wrk/oha/k6: Benchmark decode/redirect.
* Tiêu chí chấp nhận
   * Tất cả RSpec pass.
   * Brakeman không có high/medium.
   * Bullet không cảnh báo N+1.
   * POST /encode trả về đúng, lần 2 với cùng session < 20ms.
   * 100% route hoạt động trên domain demo.mandyseeyoo.com.
# AI disclosure

Các core logic - bao gồm encoder/decoder services, short-code generation và collision handling, URL validation, controllers, caching strategy, rate limiting và toàn bộ test suite đều được chính tôi thực hiện. 

AI cũng được sử dụng để hỗ trợ debug và sửa lỗi trong các file liên quan đến deployment, như Docker, Caddy và CI/CD configuration, cũng như hỗ trợ generate SETUP documentation để tiết kiệm thời gian.

README.md chứa các vấn đề đáng chú ý và cách giải quyết được tự tôi thực hiện, lấy ví dụ trên dự án đã làm và các ý tưởng mở rộng / refactor.





 
