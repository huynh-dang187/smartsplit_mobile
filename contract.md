# SMARTSPLIT — DATA CONTRACT & API SPECIFICATION

## 1. TỔNG QUAN KIẾN TRÚC & QUY TẮC CHUNG
- **Đơn vị tiền tệ:** VNĐ (Số nguyên `Integer`, không dùng số thập phân. Ví dụ: `150000`).
- **Quy tắc làm tròn:** Mọi phép chia tỷ lệ (`Pro-rata`) hoặc chia đều được làm tròn đến hàng đơn vị (`Math.round`), phần dư lệch (1–2 đồng nếu có) cộng vào người trả hóa đơn (`paidBy`).
- **Format phản hồi chung (Standard API Response):**
```json
{
  "success": true,
  "message": "Thao tác thành công",
  "data": { ... }
}
```
- **Format lỗi chung (Standard Error Response):**
```json
{
  "success": false,
  "message": "Mô tả lỗi chi tiết",
  "errorCode": "VALIDATION_ERROR | AI_PARSE_FAILED | UNAUTHORIZED",
  "errors": []
}
```

---

## 2. MONGODB SCHEMAS (MONGOOSE MODELS)

### 2.1. Collection: `users`
Lưu thông tin định danh và tài khoản ngân hàng phục vụ tạo mã VietQR.
```typescript
interface IUser {
  _id: string; // ObjectId
  name: string;
  email: string;
  passwordHash: string;
  avatarUrl?: string;
  bankInfo?: {
    bankBin: string;      // Mã BIN ngân hàng theo chuẩn Napas (VD: "970436" - Vietcombank, "970422" - MB)
    bankShortName: string; // VD: "VCB", "MB"
    accountNo: string;    // Số tài khoản
    accountName: string;  // Tên chủ tài khoản viết hoa không dấu
  };
  createdAt: Date;
}
```

### 2.2. Collection: `groups`
Lưu thông tin nhóm, số dư ròng (`netBalance`) của từng thành viên và danh sách nợ đã tối giản.
```typescript
interface IGroupMember {
  userId: string;     // Ref: 'User'
  netBalance: number; // Dương (+): Chủ nợ (được nhận lại) | Âm (-): Con nợ (phải trả) | 0: Đã cân bằng
}

interface ISimplifiedDebt {
  fromUser: string;   // Ref: 'User' (Người phải chuyển tiền)
  toUser: string;     // Ref: 'User' (Người nhận tiền)
  amount: number;     // Số tiền cần chuyển (VNĐ)
}

interface IGroup {
  _id: string;
  name: string;
  description?: string;
  createdBy: string;  // Ref: 'User'
  members: IGroupMember[];
  simplifiedDebts: ISimplifiedDebt[]; // Tự động tính lại mỗi khi thêm Expense hoặc SettleUp
  createdAt: Date;
  updatedAt: Date;
}
```

### 2.3. Collection: `expenses`
Lưu chi tiết từng hóa đơn đã được xác nhận hoặc giao dịch trả nợ trực tiếp.
```typescript
interface IExpenseItem {
  name: string;           // Tên món (VD: "Lẩu Thái Tomyum")
  quantity: number;       // Số lượng (VD: 1)
  unitPrice: number;      // Đơn giá (VD: 250000)
  totalPrice: number;     // Thành tiền của món = quantity * unitPrice (VD: 250000)
  assignedTo: string[];   // Mảng UserId cùng sử dụng món này (tối thiểu 1 người)
}

interface IExtraCharges {
  tax: number;            // Thuế VAT (VNĐ, mặc định 0)
  serviceCharge: number;  // Phí phục vụ (VNĐ, mặc định 0)
  discount: number;       // Giảm giá / Voucher (VNĐ, số dương, mặc định 0)
}

interface IMemberShare {
  userId: string;         // Ref: 'User'
  baseAmount: number;     // Tiền món gốc của người này
  extraAmount: number;    // Phần thuế + phí - giảm giá phân bổ theo tỷ lệ Pro-rata
  finalAmount: number;    // Tổng thực tế người này phải chịu = baseAmount + extraAmount
}

interface IExpense {
  _id: string;
  groupId: string;        // Ref: 'Group'
  title: string;          // Tên hóa đơn (VD: "Ăn tối Gogi House" hoặc "Thanh toán nợ")
  type: "BILL" | "SETTLEMENT"; // BILL: Hóa đơn chi tiêu | SETTLEMENT: Chuyển khoản trả nợ
  paidBy: string;         // Ref: 'User' (Người rút ví trả tiền bill này)
  receiptImageUrl?: string;
  items: IExpenseItem[];
  extraCharges: IExtraCharges;
  subtotalAmount: number; // Tổng tiền các món gốc cộng lại
  totalAmount: number;    // Tổng thực trả cuối cùng = subtotal + tax + serviceCharge - discount
  memberShares: IMemberShare[]; // Lưu kết quả chia tiền chi tiết của từng người trong bill này
  createdAt: Date;
}
```

---

## 3. ZOD SCHEMAS & PAYLOADS QUAN TRỌNG

### 3.1. `ParsedReceiptSchema` (Output của Gemini Vision AI)
Sử dụng cho API `POST /api/receipts/scan`. Chưa lưu vào DB, chỉ trả về cho Flutter hiển thị lên màn hình `SplitWorkspaceScreen`.
```typescript
import { z } from "zod";

export const ParsedReceiptItemSchema = z.object({
  id: z.string(), // UUID tạm thời do Backend sinh ra để Flutter dễ quản lý state khi tick chọn
  name: z.string().min(1),
  quantity: z.number().positive().default(1),
  unitPrice: z.number().nonnegative(),
  totalPrice: z.number().nonnegative(),
});

export const ParsedReceiptSchema = z.object({
  merchantName: z.string().optional().default("Hóa đơn mới"),
  items: z.array(ParsedReceiptItemSchema).min(1),
  extraCharges: z.object({
    tax: z.number().nonnegative().default(0),
    serviceCharge: z.number().nonnegative().default(0),
    discount: z.number().nonnegative().default(0),
  }),
  subtotalAmount: z.number().nonnegative(),
  totalAmount: z.number().positive(),
  // Các trường do Backend tự tính thêm sau khi AI trả kết quả:
  calculatedTotal: z.number().nonnegative(), // = sum(items.totalPrice) + tax + serviceCharge - discount
  isDiscrepancy: z.boolean(),                // true nếu calculatedTotal !== totalAmount (cảnh báo UI kiểm tra lại)
});
```

### 3.2. `CreateExpensePayloadSchema` (Body Flutter gửi lên khi bấm "Lưu hóa đơn")
Sử dụng cho API `POST /api/groups/:groupId/expenses`.
```typescript
export const CreateExpensePayloadSchema = z.object({
  title: z.string().min(1),
  paidBy: z.string().min(1), // UserId người ứng tiền
  items: z.array(
    z.object({
      name: z.string().min(1),
      quantity: z.number().positive(),
      unitPrice: z.number().nonnegative(),
      totalPrice: z.number().nonnegative(),
      assignedTo: z.array(z.string()).min(1, "Mỗi món phải có ít nhất 1 người ăn"),
    })
  ).min(1),
  extraCharges: z.object({
    tax: z.number().nonnegative().default(0),
    serviceCharge: z.number().nonnegative().default(0),
    discount: z.number().nonnegative().default(0),
  }),
  totalAmount: z.number().positive(),
});
```

---

## 4. CÔNG THỨC TOÁN HỌC & THUẬT TOÁN BACKEND

### 4.1. Công thức chia tiền theo tỷ lệ (`Pro-rata Calculation`)
Giả sử hóa đơn có:
- Tổng tiền món gốc: $S = \sum \text{item.totalPrice}$
- Phụ phí ròng: $E = \text{tax} + \text{serviceCharge} - \text{discount}$
- Tổng thực trả: $T = S + E$

Với mỗi thành viên $u$:
1. Tính tổng tiền món gốc của thành viên $u$ ($B_u$):
   - Với mỗi món mà $u$ có mặt trong `assignedTo` (có $k$ người cùng ăn món đó): cộng $\frac{\text{item.totalPrice}}{k}$ vào $B_u$.
2. Tính phần phụ phí phân bổ theo tỷ lệ ($E_u$):
   - $E_u = \text{Math.round}\left( E \times \frac{B_u}{S} \right)$
3. Tổng tiền thành viên $u$ phải chịu trong hóa đơn này:
   - $F_u = \text{Math.round}(B_u) + E_u$
4. Xử lý sai số làm tròn: Nếu $\sum F_u \neq T$, phần chênh lệch $\Delta = T - \sum F_u$ sẽ được cộng vào $F_{\text{paidBy}}$.

### 4.2. Thuật toán Rút gọn nợ chéo (`Greedy Debt Simplification`)
1. Cập nhật `netBalance` cho từng người trong Group khi có Bill mới:
   - Người trả tiền (`paidBy`): `netBalance += totalAmount`
   - Từng thành viên $u$: `netBalance -= F_u`
2. Tách các thành viên có `netBalance != 0` thành 2 danh sách:
   - `Creditors` (Chủ nợ: `netBalance > 0`), sắp xếp giảm dần.
   - `Debtors` (Con nợ: `netBalance < 0`), sắp xếp tăng dần (tức số nợ tuyệt đối lớn nhất đứng đầu).
3. Lặp khi cả 2 danh sách còn phần tử:
   - Lấy chủ nợ lớn nhất $C$ và con nợ lớn nhất $D$.
   - Số tiền chuyển $M = \min(C.\text{balance}, \vert{}D.\text{balance}\vert{})$.
   - Tạo bản ghi `{ fromUser: D.userId, toUser: C.userId, amount: M }`.
   - Cập nhật $C.\text{balance} -= M$ và $D.\text{balance} += M$. Loại bỏ người nào đã về 0.

---

## 5. DANH SÁCH RESTFUL API ENDPOINTS

| Method | Endpoint | Mô tả nghiệp vụ | Auth |
|---|---|---|---|
| `POST` | `/api/auth/register` | Đăng ký tài khoản kèm `bankInfo` | Không |
| `POST` | `/api/auth/login` | Đăng nhập, trả về `accessToken` (JWT) + `user` | Không |
| `PUT` | `/api/users/profile` | Cập nhật tên hoặc thông tin ngân hàng (`bankInfo`) | Có |
| `POST` | `/api/groups` | Tạo nhóm mới | Có |
| `GET` | `/api/groups` | Lấy danh sách nhóm của user hiện tại | Có |
| `GET` | `/api/groups/:groupId` | Lấy chi tiết nhóm: `members` (populated), `simplifiedDebts` (populated `bankInfo`), và danh sách `expenses` gần đây | Có |
| `POST` | `/api/ groups/:groupId/members` | Thêm thành viên vào nhóm bằng `email` | Có |
| `POST` | `/api/receipts/scan` | Upload file ảnh (`multipart/form-data`, field `receipt`) -> Trả về `ParsedReceiptSchema` | Có |
| `POST` | `/api/groups/:groupId/expenses` | Lưu hóa đơn mới (Chạy Mongoose Transaction: lưu Expense -> cập nhật `netBalance` -> chạy `simplifyDebts`) | Có |
| `POST` | `/api/groups/:groupId/settle` | Xác nhận trả nợ `{ fromUser, toUser, amount }` -> Tạo 1 Expense loại `SETTLEMENT` và cập nhật lại `netBalance` | Có |

---

## 6. QUY TẮC TẠO MÃ VIETQR TRÊN FLUTTER
Khi hiển thị màn hình Settle Up cho khoản nợ `{ fromUser, toUser, amount }`, lấy `bankInfo` của `toUser` để ghép chuỗi URL ảnh VietQR:
```text
[https://img.vietqr.io/image/](https://img.vietqr.io/image/){bankBin}-{accountNo}-compact2.png?amount={amount}&addInfo={encodedMessage}&accountName={encodedAccountName}
```
Trong đó `addInfo` mặc định là: `"SmartSplit {fromUserName} thanh toan {groupName}"`.