import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import apiRouter from "./routes/index.js";
import { errorHandler, AppError } from "./middlewares/error.middleware.js";

dotenv.config();

const app = express();
const PORT = Number(process.env.PORT) || 3000;

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

// Catch-all route 404 cho các endpoint không tồn tại
app.use((req, res, next) => {
  next(
    new AppError(
      404,
      `Đường dẫn ${req.method} ${req.originalUrl} không tồn tại trên hệ thống`,
      "NOT_FOUND"
    )
  );
});

// Middleware xử lý lỗi tập trung (Centralized Error Handler) đặt ở cuối cùng sau tất cả các route
app.use(errorHandler);

// Khởi động server khi không phải chế độ test
if (process.env.NODE_ENV !== "test") {
  connectDB().then(() => {
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`[Server] SmartSplit Backend running at http://0.0.0.0:${PORT}`);
      console.log(`[Server] Health check: http://localhost:${PORT}/api/health`);
    });
  });
}

export { app };
export default app;
