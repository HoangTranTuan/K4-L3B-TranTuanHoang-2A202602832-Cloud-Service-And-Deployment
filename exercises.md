# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Trần Tuấn Hoàng  Mã học viên: 2A202602832

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Nếu để mặc định "changeme", app khởi động bình thường và chạy trên production với API key yếu. Kẻ tấn công đoán được key, gọi /ask thoải mái, tốn tiền LLM mà mình không biết cho đến khi nhận hóa đơn. Khi bắt buộc khai báo, app crash ngay lúc deploy, CI/CD báo lỗi tức thì, buộc dev phải cấu hình key mạnh trước khi service lên production.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Ví dụ log JSON: `{"event":"ask_success","level":"info","ts":"2026-09-29T03:25:00Z","user_id":"user1","tokens":42,"latency_ms":312}`
> Hai việc làm được mà print thường không làm được: (1) Lọc và tìm kiếm theo field cụ thể, ví dụ dùng `jq '.[] | select(.user_id=="user1")'` để xem tất cả request của một user. (2) Đổ log vào hệ thống giám sát như ELK hoặc Grafana Loki để tạo dashboard, cảnh báo tự động khi latency vượt ngưỡng, vì máy parse JSON trực tiếp được.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ... MB |
| Multi-stage | ... MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Single-stage khoảng 400–500 MB, multi-stage khoảng 150–180 MB. Phần chênh lệch là compiler toolchain (gcc, build-essential), pip cache, header files dùng để build dependencies. Multi-stage chỉ copy artifacts đã build xong sang image runtime sạch nên loại bỏ hết phần thừa đó.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Với Dockerfile hiện tại (COPY requirements.txt trước, RUN pip install, rồi mới COPY . .), khi sửa main.py thì layer pip install được dùng lại từ cache, chỉ layer COPY source code chạy lại. Nếu đặt COPY . . lên trước RUN pip install, mỗi lần sửa bất kỳ file nào cũng invalidate cache từ COPY . . trở đi, khiến pip install phải chạy lại toàn bộ, tốn thêm vài phút mỗi lần build.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi sự kiện: Lỗ hổng trong code Python (ví dụ path traversal hoặc RCE) cho phép kẻ tấn công thực thi lệnh trong container. Nếu container chạy bằng root, kẻ tấn công có quyền root trong container, từ đó có thể mount filesystem host, truy cập Docker socket, hoặc khai thác kernel exploit để escape ra host với quyền root. Lệnh USER appuser cắt đứt chuỗi ngay sau bước đầu: kẻ tấn công chỉ có quyền của user thường, không thể cài package, không đọc được file hệ thống, không escape ra host.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request trong 2 giây liên tiếp. Cách đạt được: gửi 10 request vào giây 59 của phút trước (vẫn nằm trong hạn mức phút đó), rồi gửi tiếp 10 request vào giây 00 của phút sau (counter reset, hạn mức mới). Sliding window tránh được vấn đề này vì nó luôn nhìn lùi 60 giây liên tục, không có thời điểm reset đột ngột.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn tần suất (số request/phút), cost guard giới hạn chi phí tích lũy (tổng tiền/tháng). Tình huống rate limit cho qua nhưng cost guard chặn: user gửi 1 request/phút nhưng đã dùng hết budget tháng do nhiều câu hỏi dài, tốn nhiều token. Tình huống ngược lại: user mới đầu tháng (budget còn nhiều) nhưng gửi 50 request liên tục trong 1 phút, rate limit chặn ngay ở request thứ 11.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp làm một và check Redis: Redis mất kết nối 30 giây → endpoint trả 503 → orchestrator (Docker/K8s) thấy health check fail → đánh dấu cả 3 container unhealthy → restart hoặc kill cả 3 cùng lúc → không còn container nào phục vụ request → downtime hoàn toàn. Khi tách riêng, /health chỉ kiểm tra process còn sống (không check Redis) nên container vẫn healthy, /ready trả 503 để load balancer tạm ngừng gửi traffic đến. Khi Redis khôi phục, /ready trả 200, traffic tự quay lại mà không cần restart.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Với Redis, history_length tăng đều đặn bất kể request rơi vào container nào, vì cả 3 container đọc/ghi cùng một Redis. Nếu lưu trong dict Python (bộ nhớ riêng của mỗi process), history_length sẽ nhảy lên xuống thất thường: request 1 vào container A thì length=1, request 2 vào container B thì length=1 (vì B chưa có gì), request 3 quay lại A thì length=2. Mỗi container có lịch sử riêng, user thấy câu trả lời thiếu ngữ cảnh.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Lỗi gặp phải: /ready trả 500 Internal Server Error sau khi deploy. Nguyên nhân: code trên container cũ chưa có endpoint /ready (build image từ code cũ). Tìm ra bằng cách curl thử endpoint và thấy 500, kiểm tra lại thì container đang chạy image cũ. Sửa bằng cách chạy `docker compose up -d --build` để rebuild image với code mới nhất, sau đó /ready trả 200 OK bình thường.
