import { Router } from "express";
import { scanReceipt } from "../controllers/expense.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { uploadReceipt } from "../middlewares/upload.middleware.js";

const router = Router();

// Áp dụng requireAuth và uploadReceipt cho API quét hóa đơn
router.post("/scan", requireAuth, uploadReceipt, scanReceipt);
router.post("/receipts/scan", requireAuth, uploadReceipt, scanReceipt);

export { router as receiptRouter };
export default router;
