import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import apiRouter from "./routes/index.js";
import { errorHandler } from "./middlewares/error.middleware.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares toàn cục
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Mount toàn bộ RESTful API theo Mục 5 contract.md tại tiền tố /api
app.use("/api", apiRouter);

// Root health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "SmartSplit API is running",
  });
});

// Middleware xử lý lỗi tập trung (Centralized Error Handler) đặt ở cuối cùng
app.use(errorHandler);

// Khởi động server khi không phải chế độ test
if (process.env.NODE_ENV !== "test") {
  connectDB().then(() => {
    app.listen(PORT, () => {
      console.log(`[Server] SmartSplit Backend running at http://localhost:${PORT}`);
      console.log(`[Server] Health check: http://localhost:${PORT}/api/health`);
    });
  });
}

export { app };
export default app;
