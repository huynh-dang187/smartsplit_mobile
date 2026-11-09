import { Schema, model, type Document, type Types } from "mongoose";

export interface IExpenseItem {
  name: string; // Tên món (VD: "Lẩu Thái Tomyum")
  quantity: number; // Số lượng (VD: 1)
  unitPrice: number; // Đơn giá (VD: 250000)
  totalPrice: number; // Thành tiền của món = quantity * unitPrice (VD: 250000)
  assignedTo: (Types.ObjectId | string)[]; // Mảng UserId cùng sử dụng món này (tối thiểu 1 người)
}

export interface IExtraCharges {
  tax: number; // Thuế VAT (VNĐ, mặc định 0)
  serviceCharge: number; // Phí phục vụ (VNĐ, mặc định 0)
  discount: number; // Giảm giá / Voucher (VNĐ, số dương, mặc định 0)
}

export interface IMemberShare {
  userId: Types.ObjectId | string; // Ref: 'User'
  baseAmount: number; // Tiền món gốc của người này
  extraAmount: number; // Phần thuế + phí - giảm giá phân bổ theo tỷ lệ Pro-rata
  finalAmount: number; // Tổng thực tế người này phải chịu = baseAmount + extraAmount
}

export type ExpenseType = "BILL" | "SETTLEMENT";

export interface IExpense {
  _id: Types.ObjectId | string;
  groupId: Types.ObjectId | string; // Ref: 'Group'
  title: string; // Tên hóa đơn (VD: "Ăn tối Gogi House" hoặc "Thanh toán nợ")
  type: ExpenseType; // BILL: Hóa đơn chi tiêu | SETTLEMENT: Chuyển khoản trả nợ
  paidBy: Types.ObjectId | string; // Ref: 'User' (Người rút ví trả tiền bill này)
  receiptImageUrl?: string | undefined;
  items: IExpenseItem[];
  extraCharges: IExtraCharges;
  subtotalAmount: number; // Tổng tiền các món gốc cộng lại
  totalAmount: number; // Tổng thực trả cuối cùng = subtotal + tax + serviceCharge - discount
  memberShares: IMemberShare[]; // Lưu kết quả chia tiền chi tiết của từng người trong bill này
  createdAt: Date;
}

export type ExpenseDocument = Document<unknown, {}, IExpense> & IExpense;

const expenseItemSchema = new Schema<IExpenseItem>(
  {
    name: {
      type: String,
      required: [true, "Tên món là bắt buộc"],
      trim: true,
    },
    quantity: {
      type: Number,
      required: [true, "Số lượng món là bắt buộc"],
      min: [1, "Số lượng phải lớn hơn hoặc bằng 1"],
      default: 1,
    },
    unitPrice: {
      type: Number,
      required: [true, "Đơn giá là bắt buộc"],
      min: [0, "Đơn giá không được âm"],
    },
    totalPrice: {
      type: Number,
      required: [true, "Thành tiền là bắt buộc"],
      min: [0, "Thành tiền không được âm"],
    },
    assignedTo: [
      {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true,
      },
    ],
  },
  { _id: false }
);

const extraChargesSchema = new Schema<IExtraCharges>(
  {
    tax: {
      type: Number,
      required: true,
      default: 0,
      min: [0, "Thuế VAT không được âm"],
    },
    serviceCharge: {
      type: Number,
      required: true,
      default: 0,
      min: [0, "Phí phục vụ không được âm"],
    },
    discount: {
      type: Number,
      required: true,
      default: 0,
      min: [0, "Giảm giá không được âm"],
    },
  },
  { _id: false }
);

const memberShareSchema = new Schema<IMemberShare>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "userId là bắt buộc"],
    },
    baseAmount: {
      type: Number,
      required: true,
      default: 0,
    },
    extraAmount: {
      type: Number,
      required: true,
      default: 0,
    },
    finalAmount: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  { _id: false }
);

const expenseSchema = new Schema<IExpense>(
  {
    groupId: {
      type: Schema.Types.ObjectId,
      ref: "Group",
      required: [true, "groupId là bắt buộc"],
      index: true,
    },
    title: {
      type: String,
      required: [true, "Tên hóa đơn là bắt buộc"],
      trim: true,
    },
    type: {
      type: String,
      enum: ["BILL", "SETTLEMENT"],
      required: [true, "Loại chi tiêu là bắt buộc"],
      default: "BILL",
    },
    paidBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "paidBy là bắt buộc"],
    },
    receiptImageUrl: {
      type: String,
      trim: true,
    },
    items: {
      type: [expenseItemSchema],
      default: [],
    },
    extraCharges: {
      type: extraChargesSchema,
      default: () => ({ tax: 0, serviceCharge: 0, discount: 0 }),
    },
    subtotalAmount: {
      type: Number,
      required: [true, "subtotalAmount là bắt buộc"],
      default: 0,
      min: [0, "subtotalAmount không được âm"],
    },
    totalAmount: {
      type: Number,
      required: [true, "totalAmount là bắt buộc"],
      min: [0, "totalAmount không được âm"],
    },
    memberShares: {
      type: [memberShareSchema],
      default: [],
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: "expenses",
  }
);

export const Expense = model<IExpense>("Expense", expenseSchema);
export default Expense;
