import { Router } from "express";
import {
  createGroup,
  getMyGroups,
  getGroupDetail,
  addMember,
} from "../controllers/group.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";

const router = Router();

// Áp dụng middleware requireAuth cho tất cả các endpoint Quản lý Nhóm
router.use(requireAuth);

// Các endpoint theo Mục 5 contract.md khi mount tại /api/groups:
router.post("/", createGroup);
router.get("/", getMyGroups);
router.get("/:groupId", getGroupDetail);
router.post("/:groupId/members", addMember);

// Hỗ trợ thêm khi mount tại /api trực tiếp:
router.post("/groups", createGroup);
router.get("/groups", getMyGroups);
router.get("/groups/:groupId", getGroupDetail);
router.post("/groups/:groupId/members", addMember);

export { router as groupRouter };
export default router;
