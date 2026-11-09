import type { Request, Response, NextFunction } from "express";
import { isValidObjectId } from "mongoose";
import { Group } from "../models/group.model.js";
import { User } from "../models/user.model.js";
import { Expense } from "../models/expense.model.js";
import {
  CreateGroupSchema,
  AddMemberSchema,
} from "../schemas/group.schema.js";
import { AppError } from "../middlewares/error.middleware.js";

/**
 * 1. POST /api/groups
 * Tạo nhóm mới:
 * - Validate body bằng CreateGroupSchema
 * - createdBy = req.user.userId
 * - members = [{ userId: req.user.userId, netBalance: 0 }]
 * - simplifiedDebts = []
 * - Trả về 201 với { success: true, message: "Tạo nhóm thành công", data: { group } }
 */
export const createGroup = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user?.userId) {
      throw new AppError(401, "Chưa xác thực người dùng", "UNAUTHORIZED");
    }

    const parsed = CreateGroupSchema.parse(req.body);

    const groupData: {
      name: string;
      createdBy: any;
      members: { userId: any; netBalance: number }[];
      simplifiedDebts: any[];
      description?: string;
    } = {
      name: parsed.name,
      createdBy: req.user.userId,
      members: [
        {
          userId: req.user.userId,
          netBalance: 0,
        },
      ],
      simplifiedDebts: [],
    };

    if (parsed.description !== undefined) {
      groupData.description = parsed.description;
    }

    const newGroup = await Group.create(groupData);

    res.status(201).json({
      success: true,
      message: "Tạo nhóm thành công",
      data: {
        group: newGroup,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 2. GET /api/groups
 * Lấy danh sách nhóm của user hiện tại:
 * - Tìm các nhóm có members.userId chứa req.user.userId
 * - Populate members.userId (name email avatarUrl)
 * - Sắp xếp updatedAt: -1
 */
export const getMyGroups = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user?.userId) {
      throw new AppError(401, "Chưa xác thực người dùng", "UNAUTHORIZED");
    }

    const groups = await Group.find({ "members.userId": req.user.userId })
      .populate("members.userId", "name email avatarUrl")
      .sort({ updatedAt: -1 });

    res.status(200).json({
      success: true,
      message: "Lấy danh sách nhóm thành công",
      data: {
        groups,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 3. GET /api/groups/:groupId
 * Lấy chi tiết nhóm:
 * - Kiểm tra nhóm tồn tại (404 NOT_FOUND)
 * - Kiểm tra user hiện tại có thuộc nhóm không (403 FORBIDDEN)
 * - Populate members.userId (name email avatarUrl bankInfo)
 * - Populate simplifiedDebts.fromUser và simplifiedDebts.toUser (name email avatarUrl bankInfo)
 * - Lấy danh sách Expense của groupId (populate paidBy với name email avatarUrl, sort createdAt: -1)
 * - Trả về { group, expenses }
 */
export const getGroupDetail = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user?.userId) {
      throw new AppError(401, "Chưa xác thực người dùng", "UNAUTHORIZED");
    }

    const { groupId } = req.params;
    if (!groupId || !isValidObjectId(groupId)) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    const group = await Group.findById(groupId)
      .populate("members.userId", "name email avatarUrl bankInfo")
      .populate("simplifiedDebts.fromUser", "name email avatarUrl bankInfo")
      .populate("simplifiedDebts.toUser", "name email avatarUrl bankInfo");

    if (!group) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    // Kiểm tra thành viên
    const currentUserId = req.user.userId;
    const isMember = group.members.some((m: any) => {
      if (!m || !m.userId) return false;
      const memberId = m.userId._id ? m.userId._id.toString() : m.userId.toString();
      return memberId === currentUserId;
    });

    if (!isMember) {
      throw new AppError(403, "Bạn không thuộc nhóm này", "FORBIDDEN");
    }

    // Lấy danh sách hóa đơn của nhóm
    const expenses = await Expense.find({ groupId })
      .populate("paidBy", "name email avatarUrl")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      message: "Lấy chi tiết nhóm thành công",
      data: {
        group,
        expenses,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 4. POST /api/groups/:groupId/members
 * Thêm thành viên vào nhóm bằng email:
 * - Parse req.body bằng AddMemberSchema (email)
 * - Tìm user theo email (lowercase) -> 404 nếu không thấy
 * - Kiểm tra user đã trong nhóm chưa -> 400 nếu trùng
 * - Thêm { userId: foundUser._id, netBalance: 0 } vào group.members
 * - group.save() và trả về group đã cập nhật
 */
export const addMember = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user?.userId) {
      throw new AppError(401, "Chưa xác thực người dùng", "UNAUTHORIZED");
    }

    const { groupId } = req.params;
    if (!groupId || !isValidObjectId(groupId)) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    const parsed = AddMemberSchema.parse(req.body);

    const group = await Group.findById(groupId);
    if (!group) {
      throw new AppError(404, "Không tìm thấy nhóm", "NOT_FOUND");
    }

    // Kiểm tra người gọi API có phải thành viên nhóm không
    const isCurrentMember = group.members.some((m: any) => {
      if (!m || !m.userId) return false;
      const memberId = m.userId._id ? m.userId._id.toString() : m.userId.toString();
      return memberId === req.user!.userId;
    });

    if (!isCurrentMember) {
      throw new AppError(
        403,
        "Bạn không có quyền thêm thành viên vào nhóm này",
        "FORBIDDEN"
      );
    }

    // Tìm User theo email (lowercase)
    const foundUser = await User.findOne({ email: parsed.email.toLowerCase() });
    if (!foundUser) {
      throw new AppError(
        404,
        "Không tìm thấy người dùng với email này",
        "NOT_FOUND"
      );
    }

    // Kiểm tra nếu user đã trong nhóm thì ném 400 BAD_REQUEST
    const isAlreadyMember = group.members.some((m: any) => {
      if (!m || !m.userId) return false;
      const memberId = m.userId._id ? m.userId._id.toString() : m.userId.toString();
      return memberId === foundUser._id.toString();
    });

    if (isAlreadyMember) {
      throw new AppError(
        400,
        "Người dùng đã là thành viên của nhóm",
        "BAD_REQUEST"
      );
    }

    // Thêm thành viên mới với netBalance = 0
    group.members.push({
      userId: foundUser._id as any,
      netBalance: 0,
    });

    await group.save();

    // Populate lại để trả về dữ liệu hoàn chỉnh
    const updatedGroup = await Group.findById(groupId)
      .populate("members.userId", "name email avatarUrl bankInfo")
      .populate("simplifiedDebts.fromUser", "name email avatarUrl bankInfo")
      .populate("simplifiedDebts.toUser", "name email avatarUrl bankInfo");

    res.status(200).json({
      success: true,
      message: "Thêm thành viên vào nhóm thành công",
      data: {
        group: updatedGroup || group,
      },
    });
  } catch (error) {
    next(error);
  }
};
