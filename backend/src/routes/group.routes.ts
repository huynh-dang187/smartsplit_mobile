import { Router } from "express";
import {
  createGroup,
  getMyGroups,
  getGroupDetail,
  addMember,
} from "../controllers/group.controller.js";
import {
  createExpense,
  settleDebt,
} from "../controllers/expense.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";

const router = Router();

// Áp dụng middleware requireAuth cho tất cả các endpoint Quản lý Nhóm & Chi tiêu
router.use(requireAuth);

// Các endpoint theo Mục 5 contract.md khi mount tại /api/groups:
router.post("/", createGroup);
router.get("/", getMyGroups);
router.get("/:groupId", getGroupDetail);
router.post("/:groupId/members", addMember);
router.post("/:groupId/expenses", createExpense);
router.post("/:groupId/settle", settleDebt);

// Hỗ trợ thêm khi mount tại /api trực tiếp:
router.post("/groups", createGroup);
router.get("/groups", getMyGroups);
router.get("/groups/:groupId", getGroupDetail);
router.post("/groups/:groupId/members", addMember);
router.post("/groups/:groupId/expenses", createExpense);
router.post("/groups/:groupId/settle", settleDebt);

export { router as groupRouter };
export default router;
