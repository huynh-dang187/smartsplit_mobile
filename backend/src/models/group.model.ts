import { Schema, model, type Document, type Types } from "mongoose";

export interface IGroupMember {
  userId: Types.ObjectId | string; // Ref: 'User'
  netBalance: number; // Dương (+): Chủ nợ (được nhận lại) | Âm (-): Con nợ (phải trả) | 0: Đã cân bằng
}

export interface ISimplifiedDebt {
  fromUser: Types.ObjectId | string; // Ref: 'User' (Người phải chuyển tiền)
  toUser: Types.ObjectId | string; // Ref: 'User' (Người nhận tiền)
  amount: number; // Số tiền cần chuyển (VNĐ)
}

export interface IGroup {
  _id: Types.ObjectId | string;
  name: string;
  description?: string;
  createdBy: Types.ObjectId | string; // Ref: 'User'
  members: IGroupMember[];
  simplifiedDebts: ISimplifiedDebt[]; // Tự động tính lại mỗi khi thêm Expense hoặc SettleUp
  createdAt: Date;
  updatedAt: Date;
}

export type GroupDocument = Document<unknown, {}, IGroup> & IGroup;

const groupMemberSchema = new Schema<IGroupMember>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Thành viên phải có userId"],
    },
    netBalance: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  { _id: false }
);

const simplifiedDebtSchema = new Schema<ISimplifiedDebt>(
  {
    fromUser: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "fromUser là bắt buộc"],
    },
    toUser: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "toUser là bắt buộc"],
    },
    amount: {
      type: Number,
      required: [true, "Số tiền nợ là bắt buộc"],
      min: [0, "Số tiền nợ không được âm"],
    },
  },
  { _id: false }
);

const groupSchema = new Schema<IGroup>(
  {
    name: {
      type: String,
      required: [true, "Tên nhóm là bắt buộc"],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Người tạo nhóm là bắt buộc"],
    },
    members: {
      type: [groupMemberSchema],
      default: [],
    },
    simplifiedDebts: {
      type: [simplifiedDebtSchema],
      default: [],
    },
  },
  {
    timestamps: true,
    collection: "groups",
  }
);

export const Group = model<IGroup>("Group", groupSchema);
export default Group;
