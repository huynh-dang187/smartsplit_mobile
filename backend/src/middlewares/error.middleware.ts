import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";

/**
 * Danh sách mã lỗi chuẩn hóa toàn hệ thống theo Mục 1 của contract.md
 */
export type ErrorCode =
  | "VALIDATION_ERROR"
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "BAD_REQUEST"
  | "AI_PARSE_FAILED"
  | "INTERNAL_SERVER_ERROR";

export interface IErrorDetail {
  field?: string | undefined;
  message: string;
}

/**
 * Lớp lỗi tùy chỉnh cho ứng dụng SmartSplit
 */
export class AppError extends Error {
  public statusCode: number;
  public errorCode: ErrorCode;
  public errors: (IErrorDetail | string)[];

  constructor(
    statusCode: number,
    message: string,
    errorCode: ErrorCode = "BAD_REQUEST",
    errors: (IErrorDetail | string)[] = []
  ) {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.errors = errors;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

/**
 * Middleware bắt lỗi tập trung (Centralized Error Handler)
 * Chuẩn hóa phản hồi lỗi theo đúng Mục 1 của contract.md:
 * {
 *   success: false,
 *   message: "Mô tả lỗi chi tiết",
 *   errorCode: "VALIDATION_ERROR | UNAUTHORIZED | FORBIDDEN | NOT_FOUND | BAD_REQUEST | AI_PARSE_FAILED | INTERNAL_SERVER_ERROR",
 *   errors: []
 * }
 */
export function errorHandler(
  err: unknown,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  // 1. Bắt lỗi Zod validation
  if (err instanceof ZodError) {
    const formattedErrors: IErrorDetail[] = err.issues
      ? err.issues.map((issue) => ({
          field: issue.path.join("."),
          message: issue.message,
        }))
      : [];

    res.status(400).json({
      success: false,
      message: "Dữ liệu yêu cầu không hợp lệ",
      errorCode: "VALIDATION_ERROR",
      errors: formattedErrors,
    });
    return;
  }

  // 2. Bắt lỗi JSON sai cú pháp từ express.json() (entity.parse.failed)
  if (
    typeof err === "object" &&
    err !== null &&
    (("type" in err && (err as { type: unknown }).type === "entity.parse.failed") ||
      (err instanceof SyntaxError && "body" in err && (err as { status?: unknown }).status === 400))
  ) {
    res.status(400).json({
      success: false,
      message: "Body JSON không hợp lệ hoặc sai cú pháp",
      errorCode: "VALIDATION_ERROR",
      errors: [],
    });
    return;
  }

  // 3. Bắt lỗi nghiệp vụ tùy chỉnh AppError
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errorCode: err.errorCode,
      errors: err.errors ?? [],
    });
    return;
  }

  // 4. Bắt lỗi tải file của Multer
  if (
    typeof err === "object" &&
    err !== null &&
    "name" in err &&
    (err as { name: unknown }).name === "MulterError"
  ) {
    const multerErr = err as { code?: string; message?: string };
    const message =
      multerErr.code === "LIMIT_FILE_SIZE"
        ? "Dung lượng file vượt quá giới hạn cho phép (tối đa 5MB)"
        : multerErr.message || "Lỗi tải file";

    res.status(400).json({
      success: false,
      message,
      errorCode: "VALIDATION_ERROR",
      errors: multerErr.code ? [multerErr.code] : [],
    });
    return;
  }

  // 5. Bắt lỗi Mongoose CastError (ID sai định dạng ObjectId)
  if (
    typeof err === "object" &&
    err !== null &&
    "name" in err &&
    (err as { name: unknown }).name === "CastError"
  ) {
    const castErr = err as { path?: string; value?: unknown };
    res.status(400).json({
      success: false,
      message: `Định dạng ${castErr.path || "ID"} không hợp lệ: '${String(castErr.value)}'`,
      errorCode: "BAD_REQUEST",
      errors: [],
    });
    return;
  }

  // 6. Bắt lỗi Mongoose Duplicate Key Error (Code 11000)
  if (
    typeof err === "object" &&
    err !== null &&
    "code" in err &&
    (err as { code: unknown }).code === 11000
  ) {
    const dupErr = err as { keyPattern?: Record<string, unknown> };
    const field = dupErr.keyPattern ? Object.keys(dupErr.keyPattern)[0] : "dữ liệu";
    res.status(400).json({
      success: false,
      message: `${field === "email" ? "Email" : field} đã được sử dụng trong hệ thống`,
      errorCode: "BAD_REQUEST",
      errors: [],
    });
    return;
  }

  // 7. Bắt lỗi JWT Token (Sai chữ ký hoặc Hết hạn)
  if (
    typeof err === "object" &&
    err !== null &&
    "name" in err &&
    ((err as { name: unknown }).name === "JsonWebTokenError" ||
      (err as { name: unknown }).name === "TokenExpiredError")
  ) {
    const jwtErr = err as { name: string };
    const message =
      jwtErr.name === "TokenExpiredError"
        ? "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại"
        : "Token xác thực không hợp lệ hoặc đã bị thay đổi";

    res.status(401).json({
      success: false,
      message,
      errorCode: "UNAUTHORIZED",
      errors: [],
    });
    return;
  }

  // 8. Các lỗi hệ thống khác không lường trước (500)
  console.error("[ErrorHandler] Uncaught error:", err);

  // Bảo mật: Không làm lộ chi tiết lỗi nội bộ (stack trace, DB host, file paths) trong môi trường production
  const safeMessage =
    process.env.NODE_ENV === "production"
      ? "Lỗi hệ thống nội bộ"
      : err instanceof Error && err.message
      ? err.message
      : "Lỗi hệ thống nội bộ";

  res.status(500).json({
    success: false,
    message: safeMessage,
    errorCode: "INTERNAL_SERVER_ERROR",
    errors: [],
  });
}
