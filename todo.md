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

### 3. Zod Schemas — Kiểm tra tính hợp lệ dữ liệu (Mục 3 Contract)
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

### 4. Kiểm thử & Đảm bảo chất lượng (Verification)
- [x] Chạy script kiểm thử khởi tạo đối tượng Document và parse dữ liệu Zod thành công 100%.
- [x] Kiểm tra TypeScript compiler (`npx tsc --noEmit`) đạt 0 lỗi.

---

## 📋 CÁC BƯỚC TIẾP THEO CẦN LÀM (TODO)

### Giai đoạn 1: Hoàn thiện Backend Core
- [ ] **Core Business Services**:
  - `src/services/splitCalculator.service.ts`:
    - Thuật toán Pro-rata tính toán chia tiền món gốc + phân bổ thuế, phí, voucher và bù sai số làm tròn vào `paidBy`.
    - Thuật toán Greedy Debt Simplification rút gọn đồ thị nợ chéo về số giao dịch tối thiểu.
  - `src/services/aiScanner.service.ts`:
    - Tích hợp Gemini 1.5 Flash / Gemini Vision (`@google/genai`) bóc tách ảnh hóa đơn thành JSON theo `ParsedReceiptSchema`.
- [ ] **Middlewares**:
  - `src/middlewares/auth.middleware.ts`: Xác thực JSON Web Token (JWT).
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
