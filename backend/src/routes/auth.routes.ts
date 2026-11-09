import { Router } from "express";
import {
  register,
  login,
  updateProfile,
} from "../controllers/auth.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";

const router = Router();

// Endpoint theo Mục 5 contract.md
// Khi mount tại /api:
router.post("/auth/register", register);
router.post("/auth/login", login);
router.put("/users/profile", requireAuth, updateProfile);

// Hỗ trợ khi mount trực tiếp tại /api/auth:
router.post("/register", register);
router.post("/login", login);

export { router as authRouter };
export default router;
