import { Schema, model, type Document, type Types } from "mongoose";

export interface IBankInfo {
  bankBin: string; // Mã BIN ngân hàng theo chuẩn Napas (VD: "970436" - Vietcombank, "970422" - MB)
  bankShortName: string; // VD: "VCB", "MB"
  accountNo: string; // Số tài khoản
  accountName: string; // Tên chủ tài khoản viết hoa không dấu
}

export interface IUser {
  _id: Types.ObjectId | string;
  name: string;
  email: string;
  passwordHash: string;
  avatarUrl?: string;
  bankInfo?: IBankInfo;
  createdAt: Date;
}

export type UserDocument = Document<unknown, {}, IUser> & IUser;

const bankInfoSchema = new Schema<IBankInfo>(
  {
    bankBin: {
      type: String,
      required: true,
      trim: true,
    },
    bankShortName: {
      type: String,
      required: true,
      trim: true,
    },
    accountNo: {
      type: String,
      required: true,
      trim: true,
    },
    accountName: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { _id: false }
);

const userSchema = new Schema<IUser>(
  {
    name: {
      type: String,
      required: [true, "Tên người dùng là bắt buộc"],
      trim: true,
    },
    email: {
      type: String,
      required: [true, "Email là bắt buộc"],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    passwordHash: {
      type: String,
      required: [true, "Mật khẩu băm là bắt buộc"],
    },
    avatarUrl: {
      type: String,
      trim: true,
    },
    bankInfo: {
      type: bankInfoSchema,
      required: false,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: "users",
  }
);

export const User = model<IUser>("User", userSchema);
export default User;
