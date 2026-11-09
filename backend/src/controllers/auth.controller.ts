import type { Request, Response, NextFunction } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { User, type IUser } from "../models/user.model.js";
import {
  RegisterSchema,
  LoginSchema,
  UpdateProfileSchema,
} from "../schemas/auth.schema.js";
import { AppError } from "../middlewares/error.middleware.js";
import type { AuthRequest } from "../middlewares/auth.middleware.js";

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET || "smartsplit_jwt_secret_key_2026";

/**
 * Loại bỏ passwordHash và các trường nhạy cảm trước khi trả về client
 */
export const sanitizeUser = (user: any) => {
  return {
    _id: user._id,
    name: user.name,
    email: user.email,
    avatarUrl: user.avatarUrl,
    bankInfo: user.bankInfo,
    createdAt: user.createdAt,
  };
};

/**
 * POST /api/auth/register
 * Đăng ký tài khoản người dùng mới kèm thông tin ngân hàng VietQR (tùy chọn)
 */
export async function register(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // 1. Validate payload đầu vào bằng Zod
    const parsed = RegisterSchema.parse(req.body);

    // 2. Kiểm tra email đã được đăng ký chưa
    const existingUser = await User.findOne({ email: parsed.email });
    if (existingUser) {
      throw new AppError(400, "Email đã được sử dụng", "BAD_REQUEST");
    }

    // 3. Băm mật khẩu bằng bcryptjs (salt 10)
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(parsed.password, salt);

    // 4. Lưu User mới vào Database
    const newUserData: {
      name: string;
      email: string;
      passwordHash: string;
      bankInfo?: typeof parsed.bankInfo;
    } = {
      name: parsed.name,
      email: parsed.email,
      passwordHash,
    };
    if (parsed.bankInfo) {
      newUserData.bankInfo = parsed.bankInfo;
    }

    const newUser = await User.create(newUserData);

    // 5. Ký mã JWT token thời hạn 7 ngày
    const accessToken = jwt.sign(
      {
        userId: newUser._id.toString(),
        email: newUser.email,
      },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // 6. Phản hồi chuẩn RESTful (Mục 1 contract.md, tuyệt đối không trả passwordHash)
    res.status(201).json({
      success: true,
      message: "Đăng ký thành công",
      data: {
        accessToken,
        user: sanitizeUser(newUser),
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/login
 * Đăng nhập tài khoản bằng email & mật khẩu, trả về accessToken và thông tin user
 */
export async function login(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // 1. Validate payload đăng nhập
    const parsed = LoginSchema.parse(req.body);

    // 2. Tìm người dùng theo email
    const user = await User.findOne({ email: parsed.email });
    if (!user) {
      throw new AppError(401, "Email hoặc mật khẩu không chính xác", "UNAUTHORIZED");
    }

    // 3. Đối chiếu mật khẩu băm
    const isPasswordMatch = await bcrypt.compare(parsed.password, user.passwordHash);
    if (!isPasswordMatch) {
      throw new AppError(401, "Email hoặc mật khẩu không chính xác", "UNAUTHORIZED");
    }

    // 4. Ký mã JWT token (7 ngày)
    const accessToken = jwt.sign(
      {
        userId: user._id.toString(),
        email: user.email,
      },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // 5. Phản hồi thành công
    res.status(200).json({
      success: true,
      message: "Đăng nhập thành công",
      data: {
        accessToken,
        user: sanitizeUser(user),
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * PUT /api/users/profile
 * Cập nhật tên, avatarUrl hoặc thông tin tài khoản ngân hàng của user hiện tại
 */
export async function updateProfile(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // 1. Lấy userId từ auth.middleware (req.user)
    const userId = req.user?.userId;
    if (!userId) {
      throw new AppError(401, "Token xác thực không hợp lệ", "UNAUTHORIZED");
    }

    // 2. Validate payload cập nhật
    const parsed = UpdateProfileSchema.parse(req.body);

    const updateFields: Partial<IUser> = {};
    if (parsed.name !== undefined) updateFields.name = parsed.name;
    if (parsed.avatarUrl !== undefined) updateFields.avatarUrl = parsed.avatarUrl;
    if (parsed.bankInfo !== undefined) updateFields.bankInfo = parsed.bankInfo;

    // 3. Cập nhật trong MongoDB
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $set: updateFields },
      { new: true, runValidators: true }
    );

    if (!updatedUser) {
      throw new AppError(404, "Không tìm thấy người dùng", "NOT_FOUND");
    }

    // 4. Phản hồi user đã cập nhật
    res.status(200).json({
      success: true,
      message: "Cập nhật hồ sơ thành công",
      data: {
        user: sanitizeUser(updatedUser),
      },
    });
  } catch (error) {
    next(error);
  }
}
