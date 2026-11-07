import jwt from "jsonwebtoken";
import { z, ZodError } from "zod";
import type { Request, Response, NextFunction } from "express";
import { AppError, errorHandler } from "./middlewares/error.middleware.js";
import { requireAuth } from "./middlewares/auth.middleware.js";
import { uploadReceipt, upload } from "./middlewares/upload.middleware.js";

const JWT_SECRET = process.env.JWT_SECRET || "smartsplit_jwt_secret_key_2026";

/** Helper tạo mock response để kiểm tra kết quả trả về của middleware */
function createMockResponse() {
  const res: any = {
    statusCode: 200,
    body: null,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(data: any) {
      this.body = data;
      return this;
    },
  };
  return res;
}

console.log("=================================================");
console.log("TEST 1: Kiểm tra Auth Middleware (requireAuth)");
console.log("=================================================");

// 1.1. Không có header Authorization
const reqNoAuth: any = { headers: {} };
const resNoAuth = createMockResponse();
let errorNoAuth: any = null;
requireAuth(reqNoAuth, resNoAuth, (err?: any) => {
  errorNoAuth = err;
});
if (!errorNoAuth || errorNoAuth.statusCode !== 401 || errorNoAuth.errorCode !== "UNAUTHORIZED") {
  throw new Error("FAIL TEST 1.1: requireAuth không chặn khi thiếu header Authorization!");
}
console.log("✓ Chặn thành công khi thiếu token (401 UNAUTHORIZED).");

// 1.2. Token sai / giả mạo
const reqFakeAuth: any = { headers: { authorization: "Bearer token_sai_hoan_toan" } };
let errorFakeAuth: any = null;
requireAuth(reqFakeAuth, createMockResponse(), (err?: any) => {
  errorFakeAuth = err;
});
if (!errorFakeAuth || errorFakeAuth.statusCode !== 401 || errorFakeAuth.errorCode !== "UNAUTHORIZED") {
  throw new Error("FAIL TEST 1.2: requireAuth không chặn khi token giả mạo!");
}
console.log("✓ Chặn thành công khi token sai hoặc giả mạo (401 UNAUTHORIZED).");

// 1.3. Token hợp lệ
const validToken = jwt.sign(
  { userId: "usr_abc123", email: "nam@smartsplit.vn" },
  JWT_SECRET,
  { expiresIn: "1h" }
);
const reqValidAuth: any = { headers: { authorization: `Bearer ${validToken}` } };
let errorValidAuth: any = null;
requireAuth(reqValidAuth, createMockResponse(), (err?: any) => {
  errorValidAuth = err;
});
if (errorValidAuth) {
  throw new Error(`FAIL TEST 1.3: Token hợp lệ nhưng báo lỗi: ${errorValidAuth.message}`);
}
if (!reqValidAuth.user || reqValidAuth.user.userId !== "usr_abc123" || reqValidAuth.user.email !== "nam@smartsplit.vn") {
  throw new Error("FAIL TEST 1.3: req.user không được gán đúng thông tin giải mã!");
}
console.log("✓ Token hợp lệ: Giải mã và gán user thành công:", reqValidAuth.user);

console.log("\n=================================================");
console.log("TEST 2: Kiểm tra Centralized Error Handler (errorHandler)");
console.log("=================================================");

// 2.1. Lỗi AppError nghiệp vụ (VD: NOT_FOUND)
const appErr = new AppError(404, "Không tìm thấy nhóm chi tiêu", "NOT_FOUND");
const resAppErr = createMockResponse();
errorHandler(appErr, {} as Request, resAppErr as Response, (() => {}) as NextFunction);
console.log("Kết quả AppError:", resAppErr.body);
if (
  resAppErr.statusCode !== 404 ||
  resAppErr.body.success !== false ||
  resAppErr.body.errorCode !== "NOT_FOUND" ||
  resAppErr.body.message !== "Không tìm thấy nhóm chi tiêu"
) {
  throw new Error("FAIL TEST 2.1: errorHandler format sai chuẩn cho AppError!");
}
console.log("✓ Chuẩn hóa AppError khớp chuẩn Mục 1 contract.md.");

// 2.2. Lỗi ZodError (Dữ liệu không hợp lệ)
const testSchema = z.object({
  email: z.string().email("Email không hợp lệ"),
  amount: z.number().positive("Số tiền phải lớn hơn 0"),
});

let zodErrInstance: any = null;
try {
  testSchema.parse({ email: "invalid-email", amount: -50000 });
} catch (e) {
  zodErrInstance = e;
}

const resZodErr = createMockResponse();
errorHandler(zodErrInstance, {} as Request, resZodErr as Response, (() => {}) as NextFunction);
console.log("Kết quả ZodError:", resZodErr.body);
if (
  resZodErr.statusCode !== 400 ||
  resZodErr.body.success !== false ||
  resZodErr.body.errorCode !== "VALIDATION_ERROR" ||
  !Array.isArray(resZodErr.body.errors) ||
  resZodErr.body.errors.length < 2
) {
  throw new Error("FAIL TEST 2.2: errorHandler format sai chuẩn cho ZodError!");
}
console.log("✓ Chuẩn hóa ZodError thành VALIDATION_ERROR kèm chi tiết các trường bị lỗi.");

console.log("\n=================================================");
console.log("TEST 3: Kiểm tra cấu hình Upload Middleware (uploadReceipt)");
console.log("=================================================");

if (typeof uploadReceipt !== "function") {
  throw new Error("FAIL TEST 3: uploadReceipt chưa được export là function!");
}

// Kiểm tra fileFilter từ cấu hình multer
const fileFilterFn = (upload as any).fileFilter;
if (typeof fileFilterFn === "function") {
  // Test file ảnh hợp lệ (image/jpeg)
  let allowedErr: any = null;
  fileFilterFn({} as Request, { mimetype: "image/jpeg" }, (err: any, accept: boolean) => {
    allowedErr = err;
    if (!accept) throw new Error("FAIL TEST 3: File image/jpeg bị từ chối!");
  });
  if (allowedErr) throw allowedErr;
  console.log("✓ Chấp nhận file ảnh hợp lệ (image/jpeg).");

  // Test file không hợp lệ (application/pdf)
  let rejectedErr: any = null;
  fileFilterFn({} as Request, { mimetype: "application/pdf" }, (err: any, accept: boolean) => {
    rejectedErr = err;
  });
  if (!rejectedErr || rejectedErr.errorCode !== "VALIDATION_ERROR") {
    throw new Error("FAIL TEST 3: File pdf không bị chặn hoặc thiếu mã lỗi VALIDATION_ERROR!");
  }
  console.log("✓ Chặn thành công file không hợp lệ (application/pdf) với mã VALIDATION_ERROR.");
}

console.log("\n=================================================");
console.log("TẤT CẢ TIÊU CHÍ MIDDLEWARES ĐÃ VƯỢT QUA 100%!");
console.log("=================================================");
