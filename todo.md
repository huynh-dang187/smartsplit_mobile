# SMARTSPLIT — TIẾN ĐỘ DỰ ÁN & TO-DO LIST

> Tài liệu theo dõi tiến độ phát triển hệ thống SmartSplit (Backend Express + TypeScript + MongoDB & Mobile Flutter). Bám sát đặc tả kỹ thuật tại [contract.md](./contract.md).

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

### 5. Kiểm thử & Đảm bảo chất lượng (Verification)
- [x] Chạy script kiểm thử khởi tạo đối tượng Document và parse dữ liệu Zod thành công 100%.
- [x] Chạy script kiểm thử thuật toán Pro-rata và rút gọn nợ (`test-calculator.ts`) đạt 100% tiêu chí nghiệm thu.
- [x] Chạy script kiểm thử luồng AI Scanner (`test-ai-scanner.ts`) đạt 100% tiêu chí nghiệm thu.
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

---

## 📋 CÁC BƯỚC TIẾP THEO CẦN LÀM (TODO)

### Giai đoạn 1: Hoàn thiện Backend Core
- [ ] **Middlewares**:
  - `src/middlewares/auth.middleware.ts`: Xác thực JSON Web Token (JWT).
  - `src/middlewares/validate.middleware.ts`: Middleware bọc Zod Schema tự động bắt lỗi VALIDATION_ERROR.
  - `src/middlewares/error.middleware.ts`: Bắt lỗi tập trung theo format chuẩn ở Mục 1 Contract (`success`, `message`, `errorCode`, `errors`).
  - `src/middlewares/upload.middleware.ts`: Multer xử lý nhận file ảnh hóa đơn từ mobile.
- [ ] **Controllers & Routes**:
  - Auth: `POST /api/auth/register`, `POST /api/auth/login`, `PUT /api/users/profile`.
  - Groups: `POST /api/groups`, `GET /api/groups`, `GET /api/groups/:groupId`, `POST /api/groups/:groupId/members`.
  - Expenses: `POST /api/receipts/scan`, `POST /api/groups/:groupId/expenses`, `POST /api/groups/:groupId/settle`.
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
