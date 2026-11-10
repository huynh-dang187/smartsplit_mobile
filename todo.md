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
  - Lớp lỗi tùy chỉnh `AppError` kế thừa `Error` chứa `statusCode`, `errorCode` kiểu chặt chẽ `ErrorCode` (loại bỏ `any`) và mảng `errors`.
  - Bộ bắt lỗi tập trung `errorHandler` chuẩn hóa phản hồi lỗi theo đúng Mục 1 Contract (`VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `BAD_REQUEST`, `AI_PARSE_FAILED`, `INTERNAL_SERVER_ERROR`).
  - Tự động bóc tách lỗi chi tiết của `ZodError` thành mảng `errors: [{ field, message }]`.
  - Bắt lỗi JSON body sai cú pháp từ `express.json()` (`entity.parse.failed`) trả về 400 `VALIDATION_ERROR`.
  - Bắt lỗi Mongoose `CastError` (ID sai định dạng) và Duplicate Key `11000` (email trùng) trả về 400 `BAD_REQUEST`.
  - Bắt lỗi JWT (`JsonWebTokenError`, `TokenExpiredError`) trả về 401 `UNAUTHORIZED`.
  - Bảo mật thông tin lỗi hệ thống (500): Trong môi trường production chỉ trả thông báo chung `"Lỗi hệ thống nội bộ"` để tránh rò rỉ cấu trúc DB hoặc đường dẫn server.
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

### 7. Cụm Quản lý Nhóm Controller & Routes (Mục 5 Contract)
- [x] **Group Controller** ([`backend/src/controllers/group.controller.ts`](./backend/src/controllers/group.controller.ts)):
  - `createGroup`: Xác thực `CreateGroupSchema`, tạo Group với `createdBy = req.user.userId`, khởi tạo `members = [{ userId: req.user.userId, netBalance: 0 }]`, `simplifiedDebts = []`. Trả về `status 201`.
  - `getMyGroups`: Tìm các Group mà `members.userId` chứa `req.user.userId`, populate thông tin `name email avatarUrl`, sắp xếp `updatedAt: -1`. Trả về `status 200`.
  - `getGroupDetail`: Tìm Group theo `groupId` (chặn 404 nếu không tìm thấy), chặn người ngoài nhóm (403 `FORBIDDEN`). Populate `members.userId`, `simplifiedDebts.fromUser`, `simplifiedDebts.toUser` kèm thông tin tài khoản ngân hàng `bankInfo`. Truy vấn đồng thời danh sách Expense của nhóm (populate `paidBy`, sắp xếp `createdAt: -1`) và trả về `{ group, expenses }` (`status 200`).
  - `addMember`: Parse `AddMemberSchema` (`email`), kiểm tra quyền thành viên trong nhóm (403), tìm user theo email (chặn 404 nếu chưa đăng ký), kiểm tra nếu user đã trong nhóm (chặn 400 `BAD_REQUEST`). Thêm thành viên mới với `netBalance = 0`, lưu vào DB và trả về nhóm đã cập nhật (`status 200`).
- [x] **Group Routes** ([`backend/src/routes/group.routes.ts`](./backend/src/routes/group.routes.ts)):
  - `router.use(requireAuth)` bảo vệ toàn bộ các endpoint nhóm.
  - `POST /api/groups` -> `createGroup`
  - `GET /api/groups` -> `getMyGroups`
  - `GET /api/groups/:groupId` -> `getGroupDetail`
  - `POST /api/groups/:groupId/members` -> `addMember`
- [x] **Mount Router Tổng** ([`backend/src/routes/index.ts`](./backend/src/routes/index.ts)): Gắn kết `groupRoutes` vào API router.

### 8. Cụm Hóa Đơn & Thanh Toán Nợ Controller & Routes (Mục 4 & 5 Contract)
- [x] **Expense Controller** ([`backend/src/controllers/expense.controller.ts`](./backend/src/controllers/expense.controller.ts)):
  - `scanReceipt`: Kiểm tra `req.file` (chặn 400 `VALIDATION_ERROR` nếu thiếu), gọi `scanReceiptWithAI` bóc tách món, thuế VAT, phụ phí, voucher giảm giá và trả về `ParsedReceipt` (`status 200`).
  - `createExpense`: Xác thực `CreateExpensePayloadSchema`, kiểm tra nhóm và quyền thành viên (404/403). Gọi `calculateProRataShares` tính `subtotalAmount` và `memberShares`. Lưu Expense mới với `type: 'BILL'`. Cập nhật `netBalance` trong Group: người `paidBy` được cộng `+totalAmount`, từng người trong `memberShares` bị trừ `-finalAmount`. Chạy thuật toán tham lam `simplifyGroupDebts` cập nhật danh sách nợ tối giản `simplifiedDebts` và lưu vào MongoDB. Trả về `status 201` kèm `{ expense, group }`.
  - `settleDebt`: Xác thực `SettleUpSchema` (`fromUser`, `toUser`, `amount`), chặn tự trả nợ cho chính mình (400), kiểm tra cả 2 người đều thuộc nhóm. Tạo bản ghi Expense với `type: 'SETTLEMENT'`, cập nhật số dư: `fromUser` được `+amount` (giảm nợ), `toUser` bị `-amount` (đã nhận tiền). Chạy lại `simplifyGroupDebts` triệt tiêu nợ và lưu Group. Trả về `status 200` kèm `{ settlement, group }`.
- [x] **Receipt Routes** ([`backend/src/routes/receipt.routes.ts`](./backend/src/routes/receipt.routes.ts)):
  - `POST /api/receipts/scan` gắn middleware `requireAuth` và `uploadReceipt` (giới hạn 5MB, lọc ảnh).
- [x] **Hoàn thiện Routes & Server Entry** ([`backend/src/routes/index.ts`](./backend/src/routes/index.ts) & [`backend/src/index.ts`](./backend/src/index.ts)):
  - Khởi tạo Express server với `cors()`, `express.json()`, `express.urlencoded()`.
  - Route kiểm tra tình trạng máy chủ `GET /api/health` trả về `{ success: true, message: 'SmartSplit API is running' }`.
  - Khớp chuẩn 100% toàn bộ 10 endpoints trong Mục 5 Contract.
  - Gắn middleware xử lý lỗi tập trung `errorHandler` ở cuối cùng.

### 9. Tài liệu API & Bộ sưu tập Postman (API Docs & Postman Collection)
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

### 10. Kiểm thử & Đảm bảo chất lượng (Verification)
- [x] Chạy script kiểm thử khởi tạo đối tượng Document và parse dữ liệu Zod thành công 100%.
- [x] Chạy script kiểm thử thuật toán Pro-rata và rút gọn nợ (`test-calculator.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử luồng AI Scanner (`test-ai-scanner.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử toàn bộ Middlewares (`test-middlewares.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử Auth Controller & Routes (`test-auth-controller.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử Group Controller & Routes (`test-group-controller.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử Expense Controller & Server Entry (`test-expense-controller.ts`) đạt 100% tiêu chí nghiệm thu (scan receipt, chia tiền Pro-rata, cập nhật nợ, thanh toán trả nợ SettleUp, xóa nợ về 0, GET /api/health).
- [x] Toàn bộ chuỗi kiểm thử hệ thống đạt 100% tiêu chí nghiệm thu.
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

### 6. Bản chất của Cụm Quản lý Nhóm: "Sổ bộ Thành viên & Phân quyền Truy cập"
* **Tạo nhóm (`createGroup`):**
  - Người gọi tạo nhóm tự động được gắn làm `createdBy` và thành viên đầu tiên trong mảng `members`.
  - Khởi tạo số dư ban đầu `netBalance = 0` và danh sách nợ rỗng `simplifiedDebts = []`.
* **Bảo vệ quyền riêng tư nhóm (`getGroupDetail`):**
  - Chặn ngay kẻ lạ không có tên trong `members` bằng mã lỗi `403 FORBIDDEN`.
  - Populate thông tin `bankInfo` của cả chủ nợ và con nợ trong `simplifiedDebts` để sẵn sàng hiển thị mã VietQR trên app Flutter.
  - Tải đồng thời toàn bộ lịch sử hóa đơn `expenses` đã sắp xếp theo thứ tự mới nhất.
* **Thêm thành viên (`addMember`):**
  - Yêu cầu người mời phải là thành viên trong nhóm.
  - Tìm kiếm bạn bè bằng email chuẩn hóa (`toLowerCase()`).
  - Chặn thêm trùng lặp người đã có trong nhóm (400 `BAD_REQUEST`).

### 7. Bản chất của Cụm Hóa Đơn & Thanh Toán Nợ: "Trái Tim Tài Chính của SmartSplit"
* **Bóc tách hóa đơn AI (`scanReceipt`):**
  - Nhận file ảnh qua bộ lọc Multer (tối đa 5MB, chỉ nhận JPEG/PNG/WEBP/HEIC).
  - Đưa Buffer vào Gemini Vision AI với cấu trúc Prompt tiếng Việt và Schema JSON cố định để đọc tên món, đơn giá, số lượng, thuế VAT, phí phục vụ, voucher giảm giá.
* **Chia hóa đơn (`createExpense`):**
  - Chạy thuật toán Pro-rata phân bổ phụ phí theo tỷ lệ ăn uống của từng người.
  - Người trả tiền (`paidBy`) được cộng tiền dương vào `netBalance` vì đã ứng trước.
  - Người ăn bị trừ tiền âm vào `netBalance`.
  - Thuật toán Greedy tự động tính toán lại đồ thị nợ tối giản `simplifiedDebts`.
* **Thanh toán nợ (`settleDebt`):**
  - Con nợ chuyển tiền cho chủ nợ (qua quét VietQR hoặc tiền mặt).
  - Server tạo bản ghi hóa đơn dạng `SETTLEMENT` để lưu lại lịch sử.
  - Con nợ được cộng tiền (tiến về 0), chủ nợ bị trừ tiền (tiến về 0).
  - Danh sách nợ `simplifiedDebts` tự động triệt tiêu và xóa sạch các khoản nợ đã thanh toán.

### 8. Cách Test API với Postman Một Chạm (1-Click Testing):
* Mở Postman $\rightarrow$ Chọn **Import** $\rightarrow$ Kéo file [`SmartSplit.postman_collection.json`](./SmartSplit.postman_collection.json) vào.
* Chạy request `1.1 Đăng ký` hoặc `1.2 Đăng nhập`: Script tự động lưu `accessToken` vào biến môi trường `{{accessToken}}`.
* Toàn bộ các request có bảo mật phía sau (như `PUT /profile`, tạo nhóm, scan bill) tự động được cấp quyền mà không cần copy/paste token thủ công.

---

## 📋 CÁC BƯỚC TIẾP THEO CẦN LÀM (TODO)

### Giai đoạn 1: Hoàn thiện Backend Core (ĐÃ HOÀN THÀNH 100% 🎉)
- [x] **Controllers & Routes**:
  - [x] Auth: `POST /api/auth/register`, `POST /api/auth/login`, `PUT /api/users/profile`.
  - [x] Groups: `POST /api/groups`, `GET /api/groups`, `GET /api/groups/:groupId`, `POST /api/groups/:groupId/members`.
  - [x] Expenses: `POST /api/receipts/scan`, `POST /api/groups/:groupId/expenses`, `POST /api/groups/:groupId/settle`.
- [x] **Server Entry**:
  - [x] `src/index.ts`: Khởi động Express server, kết nối DB, thiết lập CORS, health check `GET /api/health`, và gắn middleware `errorHandler` ở cuối.

---

### Giai đoạn 2: Phát triển Ứng dụng Di động (Mobile Flutter - Kiến trúc 4 Trục & Feature-First Cubit)

#### 🔹 Bước 4.1: Hạ tầng Nền tảng & Hệ thống Cốt lõi (Core & Common) — [x] ĐÃ HOÀN THÀNH 🎉
- [x] **Tài liệu Kiến trúc hệ thống** ([`mobile/ARCHITECTURE.md`](./mobile/ARCHITECTURE.md)):
  - Định nghĩa kiến trúc 4 trục (`common`, `core`, `features`, `shared`) + Feature-First MVVM + Cubit.
  - Bộ quy tắc code nghiêm ngặt: Không dùng Equatable/Sealed class cho State, cơ chế `part`/`part of`, kiểm tra `isClosed` an toàn bất đồng bộ, side effects qua callbacks `onSuccess`/`onError`, chuẩn hóa `BaseResult<T>`.
- [x] **Trục `common/` (Tài nguyên & Tiện ích chung độc lập)**:
  - `configs/app_config.dart`: `baseUrl: 'http://10.0.2.2:3000/api'`, timeouts mạng.
  - `constants/app_colors.dart`: Bảng màu Semantic Tokens đạt chuẩn tương phản WCAG AA >= 4.5:1 cho 5 trạng thái nghiệp vụ (Creditor, Debtor, Settled, Discrepancy, AI/VietQR).
  - `constants/app_spacing.dart`: Hệ thống lưới 4pt/8pt, chuẩn touch target >= 44dp, chiều cao button >= 48dp, bo góc.
  - `constants/app_theme.dart`: ThemeData Material 3, nút bấm, ô nhập liệu chuẩn UI-UX Pro Max.
  - `constants/bank_bins.dart`: Danh sách 10 ngân hàng Napas phổ biến tại Việt Nam (VCB, MB, TCB, BIDV, CTG, ACB, VPB, TPB, STB, VIB).
  - `extensions/context_x.dart` & `num_x.dart`: Truy xuất Theme/MediaQuery nhanh, hiển thị SnackBar, định dạng tiền tệ trực tiếp (`150000.toVnd()`).
  - `utils/currency_formatter.dart`: Định dạng VNĐ số nguyên (`150.000 đ`).
  - `utils/vietqr_helper.dart`: Hàm sinh link ảnh VietQR chuẩn Napas theo Mục 6 `contract.md`.
- [x] **Trục `core/` (Hệ thống cốt lõi dùng chung toàn app)**:
  - `domain/entities/base_result.dart`: Thực thể phản hồi chuẩn hóa `BaseResult<T>` (`success`, `data`, `message`, `errorCode`).
  - `domain/enums/bloc_status.dart`: `enum BlocStatus` (`init`, `loading`, `hasData`, `success`, `checking`, `error`, `validateError`, `initial`) kèm extension helpers.
  - `infrastructure/datasources/local/secured_storage.dart`: Lưu trữ / đọc JWT accessToken và UserModel qua `SharedPreferences`.
  - `infrastructure/datasources/network/api/restful_request.dart`: Dio client wrapper tự gắn `Authorization: Bearer <token>`, bắt và trích xuất lỗi từ Express backend, hỗ trợ upload ảnh hóa đơn qua MultipartFile.
  - `infrastructure/model/user_model.dart` & `bank_info_model.dart`: DTO người dùng và tài khoản ngân hàng khớp 100% `contract.md`.
  - `presentation/blocs/get_it.dart`: Service Locator đăng ký `SecuredStorage`, `RestfulRequest`, `AppCubit`.
  - `presentation/cubit/app/`: `app_cubit.dart` và `app_state.dart` quản lý phiên đăng nhập và User toàn cục.
  - `presentation/pages/app.dart`: Root Widget `SmartSplitRootApp` khởi tạo MaterialApp và cổng kiểm tra phiên `_AppSessionGate`.
  - `presentation/widgets/`: `common_loading.dart` (Shimmer Skeleton), `common_button.dart` (Touch target >= 48dp), `common_error_view.dart` (thông báo lỗi tiếng Việt + nút Thử lại).
- [x] **Trục `features/` & `shared/` (Sẵn sàng cho các giai đoạn tiếp theo)**:
  - Khởi tạo paths: `auth_path.dart`, `group_path.dart`, `expense_path.dart`.
  - Điều hướng: `app_router.dart`.
  - Widget mẫu: `group_balance_card.dart` dùng `Color.withValues(alpha: ...)`.
- [x] **Kiểm thử & Chất lượng**:
  - `flutter analyze`: **0 issues found!**
  - `flutter test`: **3/3 unit & widget tests passed!**

---

#### 🔹 Bước 4.2: Tầng Dữ liệu & Hợp đồng Nghiệp vụ 3 Features (Interfaces, Models, Repositories) — [x] ĐÃ HOÀN THÀNH 🎉
- [x] **Feature 1: Auth** ([`src/features/auth/`](./mobile/lib/src/features/auth/)):
  - Paths: `auth_path.dart` (`/auth/register`, `/auth/login`, `/users/profile`).
  - Interface: `i_auth_repositories.dart` (`register`, `login`, `updateProfile`).
  - Repository: `auth_repositories.dart` (Tự động lưu JWT `accessToken` và `UserModel` vào `SecuredStorage`).
- [x] **Feature 2: Groups** ([`src/features/groups/`](./mobile/lib/src/features/groups/)):
  - Paths: `group_path.dart` (`/groups`, `/groups/:id`, `/groups/:id/members`, `/groups/:id/settle`).
  - Models:
    + `group_member_model.dart`: Hỗ trợ linh hoạt `userId` dạng String hoặc populated `UserModel` kèm `bankInfo`.
    + `simplified_debt_model.dart`: Khoản nợ rút gọn chứa `fromUser`, `toUser` (kèm `bankInfo` chủ nợ để sinh VietQR) và `amount`.
    + `group_model.dart`: Mô hình nhóm hoàn chỉnh, hàm tiện ích `getUserNetBalance`, `getDebtsForUser`.
    + `group_detail_response_model.dart`: Bọc dữ liệu `{ group, expenses }` trả về từ API.
  - Interface: `i_group_repositories.dart` (`createGroup`, `getMyGroups`, `getGroupDetail`, `addMemberByEmail`, `settleDebt`).
  - Repository: `group_repositories.dart`.
- [x] **Feature 3: Expenses** ([`src/features/expenses/`](./mobile/lib/src/features/expenses/)):
  - Paths: `expense_path.dart` (`/receipts/scan`, `/groups/:id/expenses`).
  - Models:
    + `parsed_receipt_model.dart`: `ParsedReceiptItemModel`, `ExtraChargesModel` (`netExtra`), `ParsedReceiptModel` (cờ cảnh báo `isDiscrepancy`).
    + `expense_model.dart`: `ExpenseItemModel`, `MemberShareModel`, `ExpenseModel` (`BILL` & `SETTLEMENT`).
    + `create_expense_payload.dart`: Payload tạo hóa đơn gửi lên server khớp 100% Mục 3.2 `contract.md`.
  - Interface: `i_expense_repositories.dart` (`scanReceipt`, `createExpense`).
  - Repository: `expense_repositories.dart` (Upload ảnh qua `FormData` & `MultipartFile.fromFile`).
- [x] **Service Locator & Kiểm thử tự động**:
  - Đăng ký `IAuthRepositories`, `IGroupRepositories`, `IExpenseRepositories` vào `get_it.dart`.
  - Bộ kiểm thử `mobile/test/models_and_repos_test.dart` đạt 100% (6 tests).
  - `flutter analyze`: **0 issues found!**
  - `flutter test`: **9/9 tests passed!**

---

#### 🔹 Bước 5.1: Tầng Presentation Feature Auth (Cubit & 3 Màn hình UI) — [x] ĐÃ HOÀN THÀNH 🎉
- [x] **Quản lý trạng thái (`src/features/auth/presentation/cubits/`)**:
  - `auth_state.dart`: `final class AuthState` với `status`, `user`, `selectedBank`, `errorMessage`, `obscurePassword`.
  - `auth_cubit.dart`: Quản lý 5 controllers (`name`, `email`, `password`, `accountNo`, `accountName`), dọn dẹp `dispose()` đầy đủ trong `close()`, kiểm tra `isClosed` trước khi emit, callbacks `onSuccess`/`onError`, đồng bộ tự động `AppCubit`.
- [x] **Giao diện người dùng (`src/features/auth/presentation/pages/ & widgets/`)**:
  - `login_screen.dart`: Màn hình Đăng nhập Fintech hiện đại, logo SmartSplit, tagline, toggle mật khẩu >= 44dp, nút CTA loading mượt mà.
  - `register_screen.dart`: Màn hình Đăng ký tài khoản kèm khối tùy chọn cài đặt VietQR (chọn ngân hàng, số tài khoản, tên chủ tài khoản).
  - `profile_bank_screen.dart`: Màn hình Hồ sơ & Tài khoản VietQR (xem thông tin, đổi ngân hàng nhận tiền nợ, nút Đăng xuất).
  - `bank_selector_bottom_sheet.dart`: Modal Bottom Sheet tìm kiếm và chọn nhanh 10 ngân hàng Napas, bo góc 24dp, chống tràn chữ.
- [x] **Kiểm thử tự động & Nghiệm thu**:
  - `mobile/test/auth_feature_test.dart`: 10 bài kiểm thử đơn vị & widget (luồng đăng nhập, đăng ký, validate form, render 3 màn hình không lỗi overflow).
  - `flutter analyze`: **0 issues found!**
  - `flutter test`: **19/19 tests passed (100%)!**

---

#### 🔹 Bước 5.2: Tầng Presentation Feature Groups (Cubit & Màn hình Nhóm, VietQR) — [x] ĐÃ HOÀN THÀNH 🎉
- [x] **Quản lý trạng thái (`src/features/groups/presentation/cubits/`)**:
  - `group_list_cubit.dart` & `group_list_state.dart`: `GroupListCubit` quản lý 2 controllers (`name`, `description`), tải danh sách nhóm `fetchMyGroups`, tạo nhóm mới `createGroup` an toàn `isClosed` và callbacks.
  - `group_detail_cubit.dart` & `group_detail_state.dart`: `GroupDetailCubit` quản lý chi tiết nhóm, lịch sử hóa đơn, chuyển tab (Hóa đơn / Cấn trừ nợ), tính số dư ròng `getMyNetBalance(userId)`, thêm thành viên `addMember`, gạch nợ `settleDebt`.
- [x] **Giao diện & Widgets chuyên biệt (`src/features/groups/presentation/`)**:
  - `group_balance_card.dart`: Thể hiện 3 trạng thái nợ WCAG AA (Dương: "Bạn được nhận lại", Âm: "Bạn cần trả" kèm nút VietQR, Bằng 0: "Đã sòng phẳng"), hỗ trợ `onTapCard` mở chi tiết nhóm.
  - `vietqr_bottom_sheet.dart`: Modal Bottom Sheet chuẩn Napas bo góc 24dp, sinh ảnh VietQR qua `VietQrHelper` với `CachedNetworkImage` shimmer, nút copy STK, và nút xác nhận "Tôi đã chuyển khoản xong" gạch nợ tức thì.
  - `create_group_bottom_sheet.dart` & `add_member_bottom_sheet.dart`: Dialog đẩy theo bàn phím (`viewInsetsOf`), cho phép tạo nhóm và mời bạn bè qua email.
  - `group_list_screen.dart`: Màn hình danh sách nhóm hỗ trợ kéo tải lại `RefreshIndicator`, Shimmer loading, Empty state có nút CTA, và AppBar dẫn tới Profile.
  - `group_detail_screen.dart`: Màn hình chi tiết nhóm với thẻ số dư tổng quan, 2 Tab (Lịch sử hóa đơn `BILL`/`SETTLEMENT` & Danh sách nợ rút gọn Greedy `simplifiedDebts`), FAB nổi bật **"Quét Hóa Đơn AI"**.
- [x] **Điều hướng & Cấu hình**:
  - Đăng ký factory `GroupListCubit` và `GroupDetailCubit` trong `get_it.dart`.
  - Cập nhật Route `groupList` và `groupDetail` trong `app_router.dart`.
  - Thiết lập `_AppSessionGate` chuyển thẳng vào `GroupListScreen` khi đã đăng nhập.
- [x] **Kiểm thử tự động & Nghiệm thu**:
  - `mobile/test/groups_feature_test.dart`: 16 bài kiểm thử toàn diện Cubits và Widgets (render nợ âm/dương/0, sinh mã VietQR, chuyển tab, không overflow).
  - `flutter analyze`: **0 issues found!**
  - `flutter test`: **35/35 tests passed (100%)!**

---

#### 🔹 Bước 5.3: Tầng Presentation Feature Expenses (Cubit & Màn hình SplitWorkspace AI) — [x] ĐÃ HOÀN THÀNH 🎉
- [x] **Quản lý trạng thái (`src/features/expenses/presentation/cubits/`)**:
  - `split_workspace_state.dart`: State chuẩn Pro-rata với các getters tính toán Realtime (`subtotalAmount`, `calculatedTotal`, cờ `isDiscrepancy`, kiểm tra tính hợp lệ `isValidToSubmit`, và thuật toán `realtimeMemberShares` phân bổ phụ phí theo tỷ lệ và bù sai số làm tròn $\Delta$ vào người trả tiền `paidByUserId`).
  - `split_workspace_cubit.dart`: `SplitWorkspaceCubit` quản lý bóc tách hóa đơn AI `scanReceiptImage`, khởi tạo hóa đơn nhập tay `initManualBill`, bật/tắt thành viên cho từng món `toggleMemberForItem`, chọn nhanh cả nhóm `selectAllMembersForItem`, sửa/thêm/xóa món, cập nhật phụ phí (VAT, phí dịch vụ, giảm giá voucher), đổi người trả tiền, và đóng gói `CreateExpensePayload` gửi lên backend `submitExpense`.
- [x] **Giao diện & Widgets chuyên biệt (`src/features/expenses/presentation/`)**:
  - `discrepancy_warning_banner.dart`: Banner cảnh báo màu vàng hổ phách hiển thị khi tổng món cộng phụ phí lệch so với số in trên bill do AI nhận diện.
  - `receipt_item_card.dart`: Thẻ món ăn hiển thị tên, số lượng, đơn giá, tổng tiền, nút sửa/xóa, và danh sách Chips thành viên tương tác cao (touch target >= 44dp, nút chọn nhanh "Cả nhóm").
  - `member_share_bottom_bar.dart`: Thanh neo cố định ở đáy màn hình hiển thị số tiền nhảy realtime của từng thành viên và nút chính "Lưu & Chia Hóa Đơn".
  - `split_workspace_screen.dart`: Màn hình Workspace chia tiền hoàn chỉnh gồm hiệu ứng loading Gemini AI, chọn người trả tiền, danh sách món, phụ phí, và thanh neo dưới đáy.
- [x] **Khớp nối luồng điều hướng & Cấu hình**:
  - Tích hợp BottomSheet tùy chọn tại nút FAB **"Quét Hóa Đơn AI"** trong `GroupDetailScreen`: Chụp ảnh qua Camera (`ImageSource.camera`), chọn từ Gallery (`ImageSource.gallery`), hoặc tạo hóa đơn nhập tay.
  - Tự động làm mới danh sách hóa đơn và công nợ nhóm khi lưu hóa đơn thành công và quay lại `GroupDetailScreen`.
  - Đăng ký factory `SplitWorkspaceCubit` vào `get_it.dart` và Route `splitWorkspace` vào `app_router.dart`.
- [x] **Kiểm thử tự động & Nghiệm thu**:
  - `mobile/test/expenses_feature_test.dart`: 10 bài kiểm thử toàn diện toán học Pro-rata khớp 100% Mục 4.1 contract.md, bù sai số $\Delta$, cảnh báo `isDiscrepancy`, validate người ăn, và render UI widgets.
  - `flutter analyze`: **0 issues found!**
  - `flutter test`: **45/45 tests passed (100%)!**
