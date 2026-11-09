import type { Request, Response, NextFunction } from "express";
import { isValidObjectId } from "mongoose";
import { Expense } from "../models/expense.model.js";
import { Group } from "../models/group.model.js";
import { CreateExpensePayloadSchema } from "../schemas/expense.schema.js";
import { SettleUpSchema } from "../schemas/group.schema.js";
import { aiScannerService, scanReceiptWithAI } from "../services/aiScanner.service.js";
import {
  calculateProRataShares,
  simplifyGroupDebts,
} from "../services/splitCalculator.service.js";
import { AppError } from "../middlewares/error.middleware.js";

/**
 * 1. POST /api/receipts/scan
 * Bóc tách hóa đơn bằng Gemini Vision AI:
 * - Kiểm tra req.file
 * - Gọi scanReceiptWithAI(req.file.buffer, req.file.mimetype)
 * - Trả về status 200 kèm kết quả ParsedReceipt
 */
export const scanReceipt = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.file) {
      throw new AppError(
        400,
        "Vui lòng tải lên hình ảnh hóa đơn",
        "VALIDATION_ERROR"
      );
    }

    const parsedReceipt = await aiScannerService.scanReceiptWithAI(
      req.file.buffer,
      req.file.mimetype
    );

    res.status(200).json({
      success: true,
      message: "Bóc tách hóa đơn thành công",
      data: parsedReceipt,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 2. POST /api/groups/:groupId/expenses
 * Lưu hóa đơn chi tiêu (BILL) và phân bổ nợ:
 * - Validate req.body bằng CreateExpensePayloadSchema
 * - Tìm Group (404 nếu không thấy, 403 nếu không thuộc nhóm)
 * - Chạy calculateProRataShares tính subtotalAmount và memberShares
 * - Lưu Expense với type: 'BILL'
 * - Cập nhật netBalance: paidBy được +totalAmount, từng memberShare bị -finalAmount
 * - Chạy simplifyGroupDebts cập nhật simplifiedDebts và lưu group
 * - Trả về status 201 kèm { expense, group }
 */
export const createExpense = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user?.userId) {
      throw new AppError(401, "Chưa xác thực người dùng", "UNAUTHORIZED");
    }

    const groupId = String(req.params.groupId);
    if (!groupId || !isValidObjectId(groupId)) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    const payload = CreateExpensePayloadSchema.parse(req.body);

    const group = await Group.findById(groupId);
    if (!group) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    // Kiểm tra người gọi API có phải thành viên nhóm không
    const currentUserId = req.user.userId;
    const isMember = group.members.some(
      (m: any) =>
        (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
        currentUserId
    );
    if (!isMember) {
      throw new AppError(403, "Bạn không thuộc nhóm này", "FORBIDDEN");
    }

    // Kiểm tra người thanh toán (paidBy) có trong nhóm không
    const paidByMember = group.members.find(
      (m: any) =>
        (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
        payload.paidBy
    );
    if (!paidByMember) {
      throw new AppError(
        400,
        "Người thanh toán (paidBy) phải là thành viên của nhóm",
        "BAD_REQUEST"
      );
    }

    // 1. Phân bổ chi phí theo tỷ lệ Pro-rata
    const { subtotalAmount, memberShares } = calculateProRataShares(payload);

    // Kiểm tra các thành viên trong memberShares đều phải thuộc nhóm
    for (const share of memberShares) {
      const member = group.members.find(
        (m: any) =>
          (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
          share.userId
      );
      if (!member) {
        throw new AppError(
          400,
          `Thành viên ${share.userId} không thuộc nhóm`,
          "BAD_REQUEST"
        );
      }
    }

    // 2. Lưu Expense mới
    const newExpense = await Expense.create({
      groupId,
      title: payload.title,
      type: "BILL",
      paidBy: payload.paidBy,
      items: payload.items,
      extraCharges: payload.extraCharges,
      subtotalAmount,
      totalAmount: payload.totalAmount,
      memberShares,
    });

    // 3. Cập nhật netBalance trong Group
    // Người trả tiền (paidBy) được nhận lại số tiền đã ứng trước (+totalAmount)
    paidByMember.netBalance += payload.totalAmount;

    // Mỗi thành viên chịu phần của mình (-finalAmount)
    for (const share of memberShares) {
      const member = group.members.find(
        (m: any) =>
          (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
          share.userId
      );
      if (member) {
        member.netBalance -= share.finalAmount;
      }
    }

    // 4. Rút gọn nợ chéo (Greedy Algorithm)
    const memberBalances = group.members.map((m: any) => ({
      userId: m.userId._id ? m.userId._id.toString() : m.userId.toString(),
      netBalance: m.netBalance,
    }));
    group.simplifiedDebts = simplifyGroupDebts(memberBalances) as any;

    await group.save();

    res.status(201).json({
      success: true,
      message: "Lưu hóa đơn và phân bổ chi phí thành công",
      data: {
        expense: newExpense,
        group,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 3. POST /api/groups/:groupId/settle
 * Xác nhận trả nợ (SETTLEMENT) và cân bằng số dư:
 * - Validate req.body bằng SettleUpSchema (fromUser, toUser, amount)
 * - Tìm Group và kiểm tra quyền thành viên
 * - Kiểm tra fromUser và toUser đều thuộc nhóm
 * - Tạo 1 Expense với type: 'SETTLEMENT'
 * - Cập nhật netBalance: fromUser được +amount (giảm nợ), toUser bị -amount (đã nhận tiền)
 * - Chạy simplifyGroupDebts cập nhật simplifiedDebts và lưu group
 * - Trả về status 200 kèm { settlement, group }
 */
export const settleDebt = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user?.userId) {
      throw new AppError(401, "Chưa xác thực người dùng", "UNAUTHORIZED");
    }

    const groupId = String(req.params.groupId);
    if (!groupId || !isValidObjectId(groupId)) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    const payload = SettleUpSchema.parse(req.body);

    if (payload.fromUser === payload.toUser) {
      throw new AppError(
        400,
        "Không thể tự thanh toán nợ cho chính mình",
        "BAD_REQUEST"
      );
    }

    const group = await Group.findById(groupId);
    if (!group) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    // Kiểm tra người gọi API có phải thành viên nhóm không
    const currentUserId = req.user.userId;
    const isCallerMember = group.members.some(
      (m: any) =>
        (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
        currentUserId
    );
    if (!isCallerMember) {
      throw new AppError(403, "Bạn không thuộc nhóm này", "FORBIDDEN");
    }

    // Kiểm tra cả fromUser và toUser đều thuộc nhóm
    const fromMember = group.members.find(
      (m: any) =>
        (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
        payload.fromUser
    );
    const toMember = group.members.find(
      (m: any) =>
        (m.userId._id ? m.userId._id.toString() : m.userId.toString()) ===
        payload.toUser
    );

    if (!fromMember || !toMember) {
      throw new AppError(
        400,
        "Cả người trả nợ (fromUser) và người nhận (toUser) phải là thành viên của nhóm",
        "BAD_REQUEST"
      );
    }

    // 1. Tạo bản ghi Expense dạng SETTLEMENT
    const settlement = await Expense.create({
      groupId,
      title: "Thanh toán nợ",
      type: "SETTLEMENT",
      paidBy: payload.fromUser,
      subtotalAmount: payload.amount,
      totalAmount: payload.amount,
      items: [],
      extraCharges: {
        tax: 0,
        serviceCharge: 0,
        discount: 0,
      },
      memberShares: [
        {
          userId: payload.toUser,
          baseAmount: payload.amount,
          extraAmount: 0,
          finalAmount: payload.amount,
        },
      ],
    });

    // 2. Cập nhật netBalance
    fromMember.netBalance += payload.amount;
    toMember.netBalance -= payload.amount;

    // 3. Rút gọn nợ chéo (Greedy Algorithm)
    const memberBalances = group.members.map((m: any) => ({
      userId: m.userId._id ? m.userId._id.toString() : m.userId.toString(),
      netBalance: m.netBalance,
    }));
    group.simplifiedDebts = simplifyGroupDebts(memberBalances) as any;

    await group.save();

    res.status(200).json({
      success: true,
      message: "Xác nhận trả nợ thành công",
      data: {
        settlement,
        group,
      },
    });
  } catch (error) {
    next(error);
  }
};
