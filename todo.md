# SMARTSPLIT — TIẾN ĐỘ DỰ ÁN & TO-DO LIST

> Tài liệu theo dõi tiến độ phát triển hệ thống SmartSplit (Backend Express + TypeScript + MongoDB & Mobile Flutter). Bám sát đặc tả kỹ thuật tại [contract.md](./contract.md) và cẩm nang hướng dẫn Postman tại [api.md](./api.md).

---

## 📌 PHẦN ĐÃ HOÀN THÀNH (DONE)

### 1. Hạ tầng & Cấu hình cơ bản (Infrastructure)
- [x] Đọc và đối soát toàn bộ mục 1, 2, 3 của `contract.md` (Đơn vị tiền tệ VNĐ làm tròn số nguyên, quy tắc API response chuẩn, mô hình dữ liệu).
- [x] Cấu hình dự án backend hỗ trợ ESM (`"type": "module"` trong `backend/package.json`).
- [x] Khởi tạo kết nối MongoDB Atlas qua Mongoose tại [`backend/src/config/db.ts`](./backend/src/config/db.ts):
  - Đọc biến môi trường `MONGODB_URI` từ `.env`.
  - Bắt lỗi kết nối, log trạng thái và hỗ trợ hàm `disconnectDB()`.

### 2. Mongoose Models — CSDL MongoDB (Mục 2 Contract)
- [x] **User Model** ([`backend/src/models/user.model.ts`](./backend/src/models/user.model.ts)):
  - Lưu thông tin định danh: `name`, `email` (unique, lowercase, index), `passwordHash`, `avatarUrl`.
  - Nhúng `bankInfo` chuẩn Napas (`bankBin`, `bankShortName`, `accountNo`, `accountName`) phục vụ sinh mã VietQR.
  - Tự động quản lý `createdAt`.
- [x] **Group Model** ([`backend/src/models/group.model.ts`](./backend/src/models/group.model.ts)):
  - Lưu thông tin nhóm: `name`, `description`, `createdBy` (Ref `User`).
  - Mảng `members` theo dõi số dư ròng `netBalance` (âm: con nợ, dương: chủ nợ).
  - Mảng `simplifiedDebts` lưu danh sách nợ đã tối giản (`fromUser`, `toUser`, `amount`).
  - Tự động quản lý `createdAt`, `updatedAt`.
- [x] **Expense Model** ([`backend/src/models/expense.model.ts`](./backend/src/models/expense.model.ts)):
  - Phân loại `type`: `"BILL"` (hóa đơn ăn uống) hoặc `"SETTLEMENT"` (chuyển khoản trả nợ).
  - Chi tiết từng món `items` (`name`, `quantity`, `unitPrice`, `totalPrice`, `assignedTo`).
  - Phụ phí `extraCharges` (`tax`, `serviceCharge`, `discount`).
  - Kết quả phân bổ chi phí chi tiết `memberShares` (`userId`, `baseAmount`, `extraAmount`, `finalAmount`).
  - Tổng tiền `subtotalAmount`, `totalAmount`.
- [x] **Barrel Export** ([`backend/src/models/index.ts`](./backend/src/models/index.ts)): Gom export toàn bộ models và interfaces.

### 3. Zod Schemas — Kiểm tra tính hợp lệ dữ liệu (Mục 3 Contract & Bổ sung)
- [x] **Auth Schemas** ([`backend/src/schemas/auth.schema.ts`](./backend/src/schemas/auth.schema.ts)):
  - `BankInfoSchema`: Kiểm tra thông tin ngân hàng (`bankBin`, `bankShortName`, `accountNo`, `accountName`).
  - `RegisterSchema`: Kiểm tra đăng ký (tên, email chuẩn, password >= 6 ký tự, `bankInfo` optional).
  - `LoginSchema`: Kiểm tra đăng nhập (email chuẩn, password).
  - `UpdateProfileSchema`: Cập nhật profile (`name`, `avatarUrl`, `bankInfo`).
  - Export types: `BankInfoInput`, `RegisterInput`, `LoginInput`, `UpdateProfileInput`.
- [x] **Group Schemas** ([`backend/src/schemas/group.schema.ts`](./backend/src/schemas/group.schema.ts)):
  - `CreateGroupSchema`: Tạo nhóm (`name`, `description` optional).
  - `AddMemberSchema`: Thêm thành viên (kiểm tra `email` hợp lệ).
  - `SettleUpSchema`: Trả nợ (`fromUser`, `toUser`, `amount` là số nguyên dương VNĐ).
  - Export types: `CreateGroupInput`, `AddMemberInput`, `SettleUpInput`.
- [x] **Expense & Receipt Schemas** ([`backend/src/schemas/expense.schema.ts`](./backend/src/schemas/expense.schema.ts)):
  - `ParsedReceiptItemSchema` & `ParsedReceiptSchema`: Kiểm tra kết quả bóc tách từ Gemini Vision AI, bao gồm cờ cảnh báo chênh lệch `isDiscrepancy` và `calculatedTotal`.
  - `CreateExpensePayloadSchema`: Kiểm tra dữ liệu Flutter gửi lên khi tạo hóa đơn (kiểm tra tiền không âm, `assignedTo` tối thiểu 1 người).
  - Export các type suy luận TypeScript (`ParsedReceiptItem`, `ParsedReceipt`, `CreateExpensePayload`).
- [x] **Barrel Export Schemas** ([`backend/src/schemas/index.ts`](./backend/src/schemas/index.ts)): Re-export toàn bộ schemas và types.

### 4. Dịch vụ & Thuật toán cốt lõi (Core Services - Mục 3 & 4 Contract)
- [x] **Split Calculator Service** ([`backend/src/services/splitCalculator.service.ts`](./backend/src/services/splitCalculator.service.ts)):
  - Hàm `calculateProRataShares`: Phân bổ chi phí món gốc $B_u$, phụ phí ròng $E_u$, làm tròn VNĐ số nguyên (`Math.round`), bù sai số lệch $\Delta$ vào người trả tiền (`paidBy`).
  - Hàm `simplifyGroupDebts`: Thuật toán tham lam (Greedy) khớp chủ nợ lớn nhất với con nợ lớn nhất, rút gọn đồ thị nợ chéo về số giao dịch tối thiểu.
  - Test script ([`backend/src/test-calculator.ts`](./backend/src/test-calculator.ts)) kiểm thử thành công 100% cả 2 kịch bản:
    1. Chia bill 110.000đ cho 3 người (A, B, C): A trả tiền chịu 36.666đ, B chịu 36.667đ, C chịu 36.667đ (Tổng tròn 110.000đ).
    2. Rút gọn nợ bắc cầu A ➔ B ➔ C thành 1 giao dịch trực tiếp: A trả C 100.000đ.
- [x] **AI Receipt Scanner Service** ([`backend/src/services/aiScanner.service.ts`](./backend/src/services/aiScanner.service.ts)):
  - Tích hợp SDK `@google/genai` (`GoogleGenAI`, `Type`) với model `gemini-2.5-flash`.
  - Hàm `scanReceiptWithAI`: Bóc tách ảnh hóa đơn đa phương thức với `responseMimeType: 'application/json'` và `responseSchema`.
  - Prompt tiếng Việt chuyên sâu quy đổi mọi số tiền về số nguyên VNĐ, chủ động lọc bỏ dòng tiền thừa/tiền khách đưa.
  - Tự động gắn `id: uuidv4()` cho từng món, tính lại `subtotalAmount`, `calculatedTotal`, và cờ `isDiscrepancy`.
  - Validate nghiệm ngặt bằng `ParsedReceiptSchema.parse()`.
  - Test script ([`backend/src/test-ai-scanner.ts`](./backend/src/test-ai-scanner.ts)) kiểm thử thành công 100% các tình huống hóa đơn chuẩn và hóa đơn chênh lệch.

### 5. Tầng Middlewares Kiểm soát & An ninh (Mục 1 & 5 Contract)
- [x] **Error Middleware** ([`backend/src/middlewares/error.middleware.ts`](./backend/src/middlewares/error.middleware.ts)):
  - Lớp lỗi tùy chỉnh `AppError` kế thừa `Error` chứa `statusCode`, `errorCode` và `errors`.
  - Bộ bắt lỗi tập trung `errorHandler` chuẩn hóa phản hồi lỗi theo đúng Mục 1 Contract (`VALIDATION_ERROR`, `UNAUTHORIZED`, `NOT_FOUND`, `INTERNAL_SERVER_ERROR`).
  - Tự động bóc tách lỗi chi tiết của `ZodError` thành mảng `errors: [{ field, message }]`.
- [x] **Auth Middleware** ([`backend/src/middlewares/auth.middleware.ts`](./backend/src/middlewares/auth.middleware.ts)):
  - Mở rộng kiểu dữ liệu `Express.Request` với thuộc tính `user?: { userId: string; email: string }`.
  - Middleware `requireAuth` đọc và xác thực token JWT từ header `Authorization: Bearer <token>`, tự động ném `AppError(401, '...', 'UNAUTHORIZED')` nếu thiếu hoặc sai token.
- [x] **Upload Middleware** ([`backend/src/middlewares/upload.middleware.ts`](./backend/src/middlewares/upload.middleware.ts)):
  - Cấu hình Multer với `multer.memoryStorage()`, giới hạn file 5MB.
  - Bộ lọc file `fileFilter` chỉ chấp nhận các định dạng ảnh hóa đơn hợp lệ (`image/jpeg`, `image/png`, `image/webp`, `image/heic`).
  - Export middleware `uploadReceipt = upload.single('receipt')`.
- [x] **Barrel Export Middlewares** ([`backend/src/middlewares/index.ts`](./backend/src/middlewares/index.ts)): Re-export toàn bộ middlewares.

### 6. Cụm Auth & User Profile Controller & Routes (Mục 1 & 5 Contract)
- [x] **Auth Controller** ([`backend/src/controllers/auth.controller.ts`](./backend/src/controllers/auth.controller.ts)):
  - `register`: Xác thực `RegisterSchema`, kiểm tra email trùng lặp (`AppError(400, 'Email đã được sử dụng', 'BAD_REQUEST')`), băm mật khẩu với `bcryptjs` (salt 10), lưu `User` vào MongoDB, ký JWT token hạn 7 ngày chứa `{ userId, email }`, trả về status 201 kèm `{ success: true, message: 'Đăng ký thành công', data: { accessToken, user } }` (bảo mật tuyệt đối, không trả về `passwordHash`).
  - `login`: Xác thực `LoginSchema`, tìm user theo email, đối chiếu mật khẩu với `bcrypt.compare`, ném `AppError(401, 'Email hoặc mật khẩu không chính xác', 'UNAUTHORIZED')` nếu sai, trả về status 200 kèm `{ success: true, message: 'Đăng nhập thành công', data: { accessToken, user } }`.
  - `updateProfile`: Lấy `userId` từ `req.user`, xác thực `UpdateProfileSchema`, cập nhật `name`, `avatarUrl`, `bankInfo` qua `findByIdAndUpdate(..., { new: true })`, trả về status 200 kèm thông tin user đã cập nhật.
  - `sanitizeUser`: Tiện ích làm sạch đối tượng User loại bỏ triệt để `passwordHash` trước khi phản hồi về Client.
- [x] **Auth & User Routes** ([`backend/src/routes/auth.routes.ts`](./backend/src/routes/auth.routes.ts)):
  - `POST /api/auth/register` (và alias `/register`) -> `register`
  - `POST /api/auth/login` (và alias `/login`) -> `login`
  - `PUT /api/users/profile` -> `requireAuth`, `updateProfile`
- [x] **Barrel Routes Setup** ([`backend/src/routes/index.ts`](./backend/src/routes/index.ts)): Gắn kết `authRoutes` vào API router tổng quát.

### 7. Tài liệu API & Bộ sưu tập Postman (API Docs & Postman Collection)
- [x] **Tài liệu API chi tiết** ([`api.md`](./api.md)):
  - Liệt kê đầy đủ 10 RESTful API endpoints theo Mục 5 Contract (Auth, Groups, Expenses, Receipts).
  - Quy chuẩn định dạng Request, Response chuẩn và mã lỗi HTTP.
  - Hướng dẫn thiết lập Postman Environment (`baseUrl`, `accessToken`, `groupId`).
  - Script tự động trích xuất JWT Token và lưu vào biến môi trường sau khi Login/Register.
  - Hướng dẫn upload file ảnh hóa đơn qua form-data với key `receipt`.
  - Công thức tích hợp hiển thị mã VietQR qua `img.vietqr.io`.
  - Kịch bản kiểm thử luồng thực tế (End-to-End Walkthrough) 6 bước.
  - Bảng mã lỗi thường gặp (400, 401, 404, 500) và cách khắc phục.
- [x] **Bộ sưu tập Postman v2.1** ([`SmartSplit.postman_collection.json`](./SmartSplit.postman_collection.json)):
  - Định dạng chuẩn Postman Collection v2.1 sẵn sàng Import vào Postman.
  - Gồm 3 thư mục request: Auth & User Profile, Groups, Receipts AI & Expenses.
  - Cấu hình sẵn URL, Headers, Body JSON mẫu và Script tự lưu Token.

### 8. Kiểm thử & Đảm bảo chất lượng (Verification)
- [x] Chạy script kiểm thử khởi tạo đối tượng Document và parse dữ liệu Zod thành công 100%.
- [x] Chạy script kiểm thử thuật toán Pro-rata và rút gọn nợ (`test-calculator.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử luồng AI Scanner (`test-ai-scanner.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử toàn bộ Middlewares (`test-middlewares.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử Auth Controller & Routes (`test-auth-controller.ts`) đạt 100% tiêu chí nghiệm thu (register, login, updateProfile, route mapping, kiểm tra bảo mật `sanitizeUser`).
- [x] Kiểm tra TypeScript compiler (`npx tsc --noEmit`) đạt 0 lỗi.

---

## 🧭 CẨM NANG KIẾN TRÚC & LUỒNG XỬ LÝ (CHEAT SHEET)

### 1. Trình tự đi qua các folder khi 1 Request gửi từ Flutter tới Server:

```
Flutter Client Request
  │
  ▼
1. routes/        👉 [Lễ tân]: Ánh xạ URL (VD: POST /api/groups) tới Controller tương ứng.
  │
  ▼
2. middlewares/   👉 [Bảo vệ]: Soát token JWT & chạy Zod validation từ thư mục schemas/.
  │
  ▼
3. controllers/   👉 [Tiếp tân]: Bóc tách req.body, gọi Service xử lý, trả res.json chuẩn format contract.
  │
  ▼
4. services/      👉 [Thợ chính]: Chứa toàn bộ não bộ tính toán (Pro-rata, Rút gọn nợ, Gemini AI).
  │
  ▼
5. models/        👉 [Két sắt]: Thực thể Mongoose Document lưu trữ dữ liệu vào MongoDB.
```

### 2. Tóm tắt 2 Thuật toán cốt lõi:

* **Chia tiền theo tỷ lệ (Pro-rata):**
  - $B_u$: Tiền món ăn gốc của người $u$.
  - $E$: Phụ phí ròng = Thuế VAT + Phí phục vụ - Voucher giảm giá.
  - Phụ phí từng người: $E_u = \text{Math.round}\left(E \times \frac{B_u}{S}\right)$ (Ăn bao nhiêu % thì chịu bấy nhiêu % phụ phí).
  - Bù sai số tiền lẻ: $\Delta = T - \sum F_u$ được cộng vào người thanh toán (`paidBy`).

* **Rút gọn nợ chéo (Greedy Algorithm):**
  - `netBalance > 0`: **Chủ nợ** (dương tiền, cần nhận lại).
  - `netBalance < 0`: **Con nợ** (âm tiền, cần chuyển khoản trả).
  - Cơ chế tham lam: Lấy con nợ lớn nhất trả cho chủ nợ lớn nhất số tiền $M = \min(\text{Chủ nợ}, |\text{Con nợ}|)$ $\rightarrow$ Triệt tiêu nợ bắc cầu $A \rightarrow B \rightarrow C$ thành $A \rightarrow C$ trực tiếp.

### 3. Bản chất của AI Gemini Scanner: "Bộ lọc thông minh & Quy chuẩn hóa"
* **Loại bỏ rác:** Lược bỏ toàn bộ thông tin thừa (ngày giờ, số bàn, mã số thuế, pass wifi, tiền khách đưa, tiền thối lại).
* **Lọc thông tin sạch:** Chỉ nhặt đúng tên món ăn, số lượng, đơn giá, phụ phí (thuế VAT, phí dịch vụ, voucher).
* **Quy chuẩn hóa số tiền:** Chuyển đổi mọi cách viết tắt (*150k, 150.000đ, 150 ngàn*) về **số nguyên VNĐ chuẩn (150000)**.
* **Cảnh báo sai lệch (`isDiscrepancy`):** Tự động phát hiện khi tổng tiền món cộng phụ phí bị lệch so với số tiền in dưới đáy hóa đơn.

### 4. Bản chất của Tầng Middlewares: "3 Chú Bảo Vệ Trạm Gác"
* **`auth.middleware.ts` (Bác bảo vệ soát vé JWT):**
  - Đọc header `Authorization: Bearer <token>`.
  - Dùng con dấu bí mật `JWT_SECRET` tính toán lại chữ ký xem vé có hợp lệ không.
  - Sau khi hợp lệ: Nhét thẻ tên `{ userId, email }` vào túi áo `req.user` để các Controller phía sau tự tin lấy dùng mà không sợ bị giả mạo danh tính!
* **`upload.middleware.ts` (Máy soi hành lý):**
  - Giữ tạm file trong RAM (`memoryStorage`), không lưu ổ cứng để tránh rác server.
  - Giới hạn dung lượng tối đa 5MB (`limits: { fileSize: 5 * 1024 * 1024 }`).
  - Màng lọc `fileFilter`: Chỉ cho phép ảnh hóa đơn (`jpeg`, `png`, `webp`, `heic`), chặn đứng file lạ và virus.
* **`error.middleware.ts` (Đội cứu thương & Chuẩn hóa lỗi):**
  - `AppError`: Tờ đơn báo cáo sự cố chuyên nghiệp chứa mã HTTP (`statusCode`) và mã lỗi (`errorCode`).
  - `errorHandler`: Đứng ở cuối đường đón mọi lỗi, phân loại (Zod, AppError, Multer, Internal) và đóng gói thành JSON lịch sự theo Mục 1 Contract để app Flutter không bao giờ bị văng (crash).

### 5. Bản chất của Cụm Auth & User Controller: "Quản lý Hộ tịch & Cấp phát Thẻ thông hành"
* **Đăng ký (`register`):**
  - Kiểm tra email đã có người đăng ký chưa (chặn trùng 400 `BAD_REQUEST`).
  - Băm mật khẩu bằng thuật toán 1 chiều `bcryptjs` với độ phức tạp `salt = 10` trước khi lưu vào MongoDB (kể cả admin/hacker lộ DB cũng không xem được pass gốc).
  - Ký thẻ thông hành JWT có thời hạn 7 ngày chứa `{ userId, email }`.
  - Dùng `sanitizeUser` tước bỏ trường `passwordHash` trước khi trả dữ liệu về app Flutter.
* **Đăng nhập (`login`):**
  - Tìm User theo email.
  - Dùng `bcrypt.compare` so sánh mật khẩu nhập vào với mã hash trong DB (chống timing attack).
  - Trả về token JWT mới cùng profile user (loại bỏ `passwordHash`).
* **Cập nhật hồ sơ (`updateProfile`):**
  - Nhờ trạm gác `requireAuth` kiểm tra thẻ trước, lấy `req.user.userId` đáng tin cậy.
  - Cập nhật tên, ảnh đại diện, hoặc thông tin ngân hàng Napas (`bankInfo`) để phục vụ nhận tiền chuyển khoản / tạo mã VietQR.

### 6. Cách Test API với Postman Một Chạm (1-Click Testing):
* Mở Postman $\rightarrow$ Chọn **Import** $\rightarrow$ Kéo file [`SmartSplit.postman_collection.json`](./SmartSplit.postman_collection.json) vào.
* Chạy request `1.1 Đăng ký` hoặc `1.2 Đăng nhập`: Script tự động lưu `accessToken` vào biến môi trường `{{accessToken}}`.
* Toàn bộ các request có bảo mật phía sau (như `PUT /profile`, tạo nhóm, scan bill) tự động được cấp quyền mà không cần copy/paste token thủ công.

---

## 📋 CÁC BƯỚC TIẾP THEO CẦN LÀM (TODO)

### Giai đoạn 1: Hoàn thiện Backend Core
- [ ] **Controllers & Routes**:
  - [x] Auth: `POST /api/auth/register`, `POST /api/auth/login`, `PUT /api/users/profile`.
  - [ ] Groups: `POST /api/groups`, `GET /api/groups`, `GET /api/groups/:groupId`, `POST /api/groups/:groupId/members`.
  - [ ] Expenses: `POST /api/receipts/scan`, `POST /api/groups/:groupId/expenses`, `POST /api/groups/:groupId/settle`.
- [ ] **Server Entry**:
  - `src/index.ts`: Khởi động Express server, kết nối DB, thiết lập CORS và routes.

---

### Giai đoạn 2: Phát triển Ứng dụng Di động (Mobile Flutter)
- [ ] Khởi tạo cấu trúc project Flutter trong thư mục `mobile/`.
- [ ] Xây dựng tầng Network / API Client (Dio hoặc HTTP client).
- [ ] Quản lý trạng thái (Riverpod / Bloc).
- [ ] Màn hình Xác thực: Đăng nhập, Đăng ký kèm nhập thông tin ngân hàng.
- [ ] Màn hình Danh sách nhóm & Chi tiết nhóm (hiển thị số dư `netBalance`).
- [ ] Màn hình Scan hóa đơn bằng Camera và Workspace phân chia món (`SplitWorkspaceScreen`).
- [ ] Màn hình Settle Up: Tự động hiển thị mã VietQR từ link ảnh `img.vietqr.io` để người dùng quét thanh toán nhanh.
