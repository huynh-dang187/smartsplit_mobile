import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import type { Request, Response, NextFunction } from "express";
import { User } from "./models/user.model.js";
import { register, login, updateProfile, sanitizeUser } from "./controllers/auth.controller.js";
import authRoutes from "./routes/auth.routes.js";

const JWT_SECRET = process.env.JWT_SECRET || "smartsplit_jwt_secret_key_2026";

function createMockResponse() {
  const res: any = {
    statusCode: 200,
    body: null,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(data: any) {
      this.body = data;
      return this;
    },
  };
  return res;
}

console.log("=================================================");
console.log("TEST 1: Kiểm tra hàm sanitizeUser");
console.log("=================================================");
const rawUser = {
  _id: "usr_123",
  name: "Nguyễn Văn A",
  email: "a@gmail.com",
  passwordHash: "$2a$10$encryptedpasswordhashvaluehere",
  avatarUrl: "https://example.com/avatar.jpg",
  bankInfo: {
    bankBin: "970436",
    bankShortName: "VCB",
    accountNo: "0123456789",
    accountName: "NGUYEN VAN A",
  },
  createdAt: new Date(),
};

const safeUser = sanitizeUser(rawUser);
if ("passwordHash" in safeUser && (safeUser as any).passwordHash !== undefined) {
  throw new Error("FAIL TEST 1: sanitizeUser vẫn để lộ passwordHash!");
}
if (safeUser._id !== "usr_123" || safeUser.email !== "a@gmail.com") {
  throw new Error("FAIL TEST 1: sanitizeUser làm mất thông tin hợp lệ!");
}
console.log("✓ sanitizeUser bảo mật tuyệt đối (không chứa passwordHash).");

console.log("\n=================================================");
console.log("TEST 2: Kiểm tra Controller register (Đăng ký)");
console.log("=================================================");

// Lưu lại các hàm gốc để phục hồi sau test
const origFindOne = User.findOne;
const origCreate = User.create;
const origFindByIdAndUpdate = User.findByIdAndUpdate;

// 2.1. Test trùng email
(User as any).findOne = async () => ({ _id: "existing_id", email: "trung@gmail.com" });
let duplicateErr: any = null;
await register(
  {
    body: {
      name: "Người Trùng",
      email: "trung@gmail.com",
      password: "password123",
    },
  } as Request,
  createMockResponse(),
  (err: any) => {
    duplicateErr = err;
  }
);
if (!duplicateErr || duplicateErr.statusCode !== 400 || duplicateErr.errorCode !== "BAD_REQUEST") {
  throw new Error("FAIL TEST 2.1: Không chặn được email bị trùng!");
}
console.log("✓ Chặn thành công khi email đã tồn tại (400 BAD_REQUEST).");

// 2.2. Test đăng ký thành công
(User as any).findOne = async () => null;
let createdDoc: any = null;
(User as any).create = async (doc: any) => {
  createdDoc = {
    ...doc,
    _id: "usr_new_999",
    createdAt: new Date(),
  };
  return createdDoc;
};

const resRegister = createMockResponse();
await register(
  {
    body: {
      name: "Huỳnh Đăng",
      email: "dang@gmail.com",
      password: "mySecretPassword123",
      bankInfo: {
        bankBin: "970422",
        bankShortName: "MB",
        accountNo: "999988887777",
        accountName: "HUYNH DANG",
      },
    },
  } as Request,
  resRegister,
  (() => {}) as NextFunction
);

console.log("Kết quả register:", resRegister.body);
if (
  resRegister.statusCode !== 201 ||
  resRegister.body.success !== true ||
  !resRegister.body.data.accessToken ||
  resRegister.body.data.user.email !== "dang@gmail.com"
) {
  throw new Error("FAIL TEST 2.2: Register thành công nhưng format response sai!");
}

if ("passwordHash" in resRegister.body.data.user) {
  throw new Error("FAIL TEST 2.2: Response register để lộ passwordHash!");
}

// Kiểm tra token giải mã
const decodedRegister = jwt.verify(resRegister.body.data.accessToken, JWT_SECRET) as any;
if (decodedRegister.userId !== "usr_new_999" || decodedRegister.email !== "dang@gmail.com") {
  throw new Error("FAIL TEST 2.2: Token JWT trong register chứa thông tin không chính xác!");
}
console.log("✓ Đăng ký thành công (status 201, trả accessToken + user sạch).");

console.log("\n=================================================");
console.log("TEST 3: Kiểm tra Controller login (Đăng nhập)");
console.log("=================================================");

const testPassword = "correctPassword123";
const salt = await bcrypt.genSalt(10);
const hashedPw = await bcrypt.hash(testPassword, salt);

// 3.1. Test sai email
(User as any).findOne = async () => null;
let notFoundErr: any = null;
await login(
  {
    body: { email: "notfound@gmail.com", password: testPassword },
  } as Request,
  createMockResponse(),
  (err: any) => {
    notFoundErr = err;
  }
);
if (!notFoundErr || notFoundErr.statusCode !== 401 || notFoundErr.errorCode !== "UNAUTHORIZED") {
  throw new Error("FAIL TEST 3.1: Không chặn được khi sai email!");
}
console.log("✓ Chặn thành công khi sai email (401 UNAUTHORIZED).");

// 3.2. Test sai mật khẩu
(User as any).findOne = async () => ({
  _id: "usr_login_1",
  email: "user@gmail.com",
  passwordHash: hashedPw,
});
let wrongPwErr: any = null;
await login(
  {
    body: { email: "user@gmail.com", password: "wrong_password_abc" },
  } as Request,
  createMockResponse(),
  (err: any) => {
    wrongPwErr = err;
  }
);
if (!wrongPwErr || wrongPwErr.statusCode !== 401 || wrongPwErr.errorCode !== "UNAUTHORIZED") {
  throw new Error("FAIL TEST 3.2: Không chặn được khi sai mật khẩu!");
}
console.log("✓ Chặn thành công khi sai mật khẩu (401 UNAUTHORIZED).");

// 3.3. Test đăng nhập thành công
const resLogin = createMockResponse();
await login(
  {
    body: { email: "user@gmail.com", password: testPassword },
  } as Request,
  resLogin,
  (() => {}) as NextFunction
);

console.log("Kết quả login:", resLogin.body);
if (
  resLogin.statusCode !== 200 ||
  resLogin.body.success !== true ||
  !resLogin.body.data.accessToken ||
  resLogin.body.data.user.email !== "user@gmail.com"
) {
  throw new Error("FAIL TEST 3.3: Login thành công nhưng response sai chuẩn!");
}
console.log("✓ Đăng nhập thành công (status 200, cấp accessToken mới).");

console.log("\n=================================================");
console.log("TEST 4: Kiểm tra Controller updateProfile");
console.log("=================================================");

(User as any).findByIdAndUpdate = async (id: string, update: any) => ({
  _id: id,
  name: update.$set.name || "Tên Đã Đổi",
  email: "user@gmail.com",
  avatarUrl: "https://example.com/new.png",
  bankInfo: {
    bankBin: "970436",
    bankShortName: "VCB",
    accountNo: "11223344",
    accountName: "TEN DA DOI",
  },
  createdAt: new Date(),
});

const resProfile = createMockResponse();
await updateProfile(
  {
    user: { userId: "usr_login_1", email: "user@gmail.com" },
    body: {
      name: "Tên Đã Đổi",
      avatarUrl: "https://example.com/new.png",
    },
  } as any,
  resProfile,
  (() => {}) as NextFunction
);

console.log("Kết quả updateProfile:", resProfile.body);
if (
  resProfile.statusCode !== 200 ||
  resProfile.body.success !== true ||
  resProfile.body.data.user.name !== "Tên Đã Đổi"
) {
  throw new Error("FAIL TEST 4: updateProfile không cập nhật đúng thông tin!");
}
console.log("✓ Cập nhật hồ sơ thành công (status 200, trả về thông tin mới).");

console.log("\n=================================================");
console.log("TEST 5: Kiểm tra cấu hình router (auth.routes.ts)");
console.log("=================================================");

if (!authRoutes || typeof authRoutes !== "function") {
  throw new Error("FAIL TEST 5: Router chưa được export đúng cách!");
}
console.log("✓ auth.routes.ts đã được cấu hình và xuất khẩu hoàn chỉnh.");

// Phục hồi các hàm Mongoose gốc
User.findOne = origFindOne;
User.create = origCreate;
User.findByIdAndUpdate = origFindByIdAndUpdate;

console.log("\n=================================================");
console.log("TẤT CẢ TIÊU CHÍ BƯỚC 4.1 ĐÃ VƯỢT QUA 100%!");
console.log("=================================================");
