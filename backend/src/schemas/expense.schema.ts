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
  isDiscrepancy: z.boolean(), // true nếu calculatedTotal !== totalAmount (cảnh báo UI kiểm tra lại)
});

export const CreateExpensePayloadSchema = z.object({
  title: z.string().min(1),
  paidBy: z.string().min(1), // UserId người ứng tiền
  items: z
    .array(
      z.object({
        name: z.string().min(1),
        quantity: z.number().positive(),
        unitPrice: z.number().nonnegative(),
        totalPrice: z.number().nonnegative(),
        assignedTo: z.array(z.string()).min(1, "Mỗi món phải có ít nhất 1 người ăn"),
      })
    )
    .min(1),
  extraCharges: z.object({
    tax: z.number().nonnegative().default(0),
    serviceCharge: z.number().nonnegative().default(0),
    discount: z.number().nonnegative().default(0),
  }),
  totalAmount: z.number().positive(),
});

export type ParsedReceiptItem = z.infer<typeof ParsedReceiptItemSchema>;
export type ParsedReceipt = z.infer<typeof ParsedReceiptSchema>;
export type CreateExpensePayload = z.infer<typeof CreateExpensePayloadSchema>;
