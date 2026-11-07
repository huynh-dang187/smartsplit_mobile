import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { AppError } from "./error.middleware.js";

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET || "smartsplit_jwt_secret_key_2026";

export interface UserPayload {
  userId: string;
  email: string;
}

export interface AuthRequest extends Request {
  user?: UserPayload;
}

declare global {
  namespace Express {
    interface Request {
      user?: UserPayload;
    }
  }
}

/**
 * Middleware bảo vệ các route yêu cầu đăng nhập (JWT Verification)
 * Đọc header Authorization: Bearer <token>
 */
export function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next(
      new AppError(
        401,
        "Token xác thực không được cung cấp",
        "UNAUTHORIZED"
      )
    );
  }

  const token = authHeader.split(" ")[1];
  if (!token) {
    return next(
      new AppError(
        401,
        "Token không hợp lệ hoặc đã hết hạn",
        "UNAUTHORIZED"
      )
    );
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    if (!decoded || !decoded.userId || !decoded.email) {
      return next(
        new AppError(
          401,
          "Token không hợp lệ hoặc đã hết hạn",
          "UNAUTHORIZED"
        )
      );
    }

    req.user = {
      userId: decoded.userId,
      email: decoded.email,
    };
    next();
  } catch (error) {
    return next(
      new AppError(
        401,
        "Token không hợp lệ hoặc đã hết hạn",
        "UNAUTHORIZED"
      )
    );
  }
}
