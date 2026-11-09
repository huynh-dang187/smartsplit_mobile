import { Router } from "express";
import authRoutes from "./auth.routes.js";
import groupRoutes from "./group.routes.js";
import receiptRoutes from "./receipt.routes.js";

const apiRouter = Router();

// Health check endpoint: GET /api/health
apiRouter.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "SmartSplit API is running",
  });
});

// 1. Auth & User Profile endpoints:
// POST /api/auth/register, POST /api/auth/login, PUT /api/users/profile
apiRouter.use(authRoutes);

// 2. Receipt AI Scan endpoint:
// POST /api/receipts/scan
apiRouter.use("/receipts", receiptRoutes);
apiRouter.use(receiptRoutes);

// 3. Groups & Expenses & Settlement endpoints:
// POST /api/groups, GET /api/groups, GET /api/groups/:groupId, POST /api/groups/:groupId/members
// POST /api/groups/:groupId/expenses, POST /api/groups/:groupId/settle
apiRouter.use("/groups", groupRoutes);
apiRouter.use(groupRoutes);

export default apiRouter;
