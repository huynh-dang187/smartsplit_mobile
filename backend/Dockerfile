# ==============================================================================
# STAGE 1: Builder - Biên dịch TypeScript sang JavaScript
# ==============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency definitions
COPY package*.json ./

# Cài đặt toàn bộ dependencies (bao gồm devDependencies cho TypeScript compiler)
RUN npm ci

# Copy file cấu hình TypeScript và toàn bộ mã nguồn src/
COPY tsconfig.json ./
COPY src/ ./src/

# Biên dịch mã nguồn sang thư mục dist/
RUN npm run build

# ==============================================================================
# STAGE 2: Runner - Production Image siêu nhẹ chạy trên Google Cloud Run
# ==============================================================================
FROM node:20-alpine AS runner

WORKDIR /app

# Thiết lập môi trường Production
ENV NODE_ENV=production

# Copy dependency definitions
COPY package*.json ./

# Chỉ cài đặt dependencies cần thiết cho runtime, loại bỏ devDependencies
RUN npm ci --omit=dev

# Copy thư mục dist đã biên dịch từ Stage 1
COPY --from=builder /app/dist ./dist

# Cổng mặc định Google Cloud Run (mặc định Cloud Run gán PORT=8080)
EXPOSE 8080

# Khởi chạy ứng dụng
CMD ["node", "dist/index.js"]
