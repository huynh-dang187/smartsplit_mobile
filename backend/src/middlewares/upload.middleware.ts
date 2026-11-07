import multer from "multer";
import type { Request } from "express";
import { AppError } from "./error.middleware.js";

const storage = multer.memoryStorage();

const ALLOWED_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
];

export const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // Giới hạn 5MB
  },
  fileFilter: (
    req: Request,
    file: Express.Multer.File,
    cb: multer.FileFilterCallback
  ) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new AppError(
          400,
          "Chỉ chấp nhận file hình ảnh hóa đơn (JPEG, PNG, WEBP, HEIC)",
          "VALIDATION_ERROR"
        )
      );
    }
  },
});

/**
 * Middleware nhận 1 file ảnh hóa đơn từ multipart/form-data với field name là 'receipt'
 */
export const uploadReceipt = upload.single("receipt");
