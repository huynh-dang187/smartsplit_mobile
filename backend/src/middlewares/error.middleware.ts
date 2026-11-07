import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";

/**
 * Lớp lỗi tùy chỉnh cho ứng dụng SmartSplit
 */
export class AppError extends Error {
  public statusCode: number;
  public errorCode: string;
  public errors: any[];

  constructor(
    statusCode: number,
    message: string,
    errorCode: string = "BAD_REQUEST",
    errors: any[] = []
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
 *   errorCode: "VALIDATION_ERROR | AI_PARSE_FAILED | UNAUTHORIZED",
 *   errors: []
 * }
 */
export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  // 1. Bắt lỗi Zod validation
  if (err instanceof ZodError) {
    const formattedErrors = err.issues
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

  // 2. Bắt lỗi nghiệp vụ tùy chỉnh AppError
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errorCode: err.errorCode,
      errors: err.errors ?? [],
    });
    return;
  }

  // 3. Bắt lỗi tải file của Multer
  if (err.name === "MulterError") {
    const message =
      err.code === "LIMIT_FILE_SIZE"
        ? "Dung lượng file vượt quá giới hạn cho phép (tối đa 5MB)"
        : err.message || "Lỗi tải file";

    res.status(400).json({
      success: false,
      message,
      errorCode: "VALIDATION_ERROR",
      errors: [err.code || err.message],
    });
    return;
  }

  // 4. Các lỗi hệ thống khác không lường trước
  console.error("[ErrorHandler] Uncaught error:", err);
  res.status(500).json({
    success: false,
    message: err.message || "Lỗi hệ thống nội bộ",
    errorCode: "INTERNAL_SERVER_ERROR",
    errors: [],
  });
}
