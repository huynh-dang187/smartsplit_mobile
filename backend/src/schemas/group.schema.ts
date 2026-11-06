import { z } from "zod";

export const CreateGroupSchema = z.object({
  name: z.string().trim().min(1, "Tên nhóm không được để trống"),
  description: z.string().trim().optional(),
});

export const AddMemberSchema = z.object({
  email: z.string().trim().email("Email không hợp lệ").toLowerCase(),
});

export const SettleUpSchema = z.object({
  fromUser: z.string().trim().min(1, "fromUser là bắt buộc"),
  toUser: z.string().trim().min(1, "toUser là bắt buộc"),
  amount: z
    .number()
    .int("Số tiền phải là số nguyên (VNĐ)")
    .positive("Số tiền thanh toán phải lớn hơn 0"),
});

export type CreateGroupInput = z.infer<typeof CreateGroupSchema>;
export type AddMemberInput = z.infer<typeof AddMemberSchema>;
export type SettleUpInput = z.infer<typeof SettleUpSchema>;
