import { z } from "zod";

export const BankInfoSchema = z.object({
  bankBin: z.string().trim().min(1, "Mã BIN ngân hàng không được để trống"),
  bankShortName: z.string().trim().min(1, "Tên viết tắt ngân hàng không được để trống"),
  accountNo: z.string().trim().min(1, "Số tài khoản không được để trống"),
  accountName: z.string().trim().min(1, "Tên chủ tài khoản không được để trống"),
});

export const RegisterSchema = z.object({
  name: z.string().trim().min(1, "Tên người dùng không được để trống"),
  email: z.string().trim().email("Email không hợp lệ").toLowerCase(),
  password: z.string().min(6, "Mật khẩu phải có tối thiểu 6 ký tự"),
  bankInfo: BankInfoSchema.optional(),
});

export const LoginSchema = z.object({
  email: z.string().trim().email("Email không hợp lệ").toLowerCase(),
  password: z.string().min(1, "Mật khẩu không được để trống"),
});

export const UpdateProfileSchema = z.object({
  name: z.string().trim().min(1, "Tên người dùng không được để trống").optional(),
  avatarUrl: z.string().trim().optional(),
  bankInfo: BankInfoSchema.optional(),
});

export type BankInfoInput = z.infer<typeof BankInfoSchema>;
export type RegisterInput = z.infer<typeof RegisterSchema>;
export type LoginInput = z.infer<typeof LoginSchema>;
export type UpdateProfileInput = z.infer<typeof UpdateProfileSchema>;
