import type { Request, Response, NextFunction } from "express";
import mongoose from "mongoose";
import { Group } from "./models/group.model.js";
import { User } from "./models/user.model.js";
import { Expense } from "./models/expense.model.js";
import {
  createGroup,
  getMyGroups,
  getGroupDetail,
  addMember,
} from "./controllers/group.controller.js";
import groupRoutes from "./routes/group.routes.js";

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

// Lưu lại các hàm gốc của Mongoose Models để phục hồi
const origGroupCreate = Group.create;
const origGroupFind = Group.find;
const origGroupFindById = Group.findById;
const origUserFindOne = User.findOne;
const origExpenseFind = Expense.find;

console.log("=================================================");
console.log("TEST 1: Kiểm tra Controller createGroup (Tạo nhóm)");
console.log("=================================================");

// 1.1 Chặn khi chưa đăng nhập
let unauthErr: any = null;
await createGroup(
  { body: { name: "Nhóm Test" } } as Request,
  createMockResponse(),
  (err: any) => {
    unauthErr = err;
  }
);
if (!unauthErr || unauthErr.statusCode !== 401) {
  throw new Error("FAIL 1.1: createGroup không chặn user chưa đăng nhập!");
}
console.log("✓ Chặn thành công khi chưa xác thực (401 UNAUTHORIZED).");

// 1.2 Tạo nhóm thành công
const mockUserId = new mongoose.Types.ObjectId().toString();
let createdGroupPayload: any = null;

(Group as any).create = async (data: any) => {
  createdGroupPayload = {
    ...data,
    _id: new mongoose.Types.ObjectId().toString(),
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  return createdGroupPayload;
};

const resCreate = createMockResponse();
await createGroup(
  {
    body: {
      name: "Chuyến đi Đà Lạt 3N2Đ",
      description: "Tiền ăn uống khách sạn",
    },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  resCreate,
  (err: any) => {
    if (err) throw err;
  }
);

if (resCreate.statusCode !== 201) {
  throw new Error(`FAIL 1.2: Status code kỳ vọng 201, nhận được ${resCreate.statusCode}`);
}
if (!resCreate.body?.success || resCreate.body?.data?.group?.name !== "Chuyến đi Đà Lạt 3N2Đ") {
  throw new Error("FAIL 1.2: Response body không khớp format contract!");
}
if (
  resCreate.body.data.group.members.length !== 1 ||
  resCreate.body.data.group.members[0].userId !== mockUserId ||
  resCreate.body.data.group.members[0].netBalance !== 0
) {
  throw new Error("FAIL 1.2: Người tạo nhóm không được khởi tạo đúng netBalance = 0!");
}
console.log("✓ Tạo nhóm thành công với status 201, khởi tạo members chuẩn.");

console.log("\n=================================================");
console.log("TEST 2: Kiểm tra Controller getMyGroups (Danh sách nhóm)");
console.log("=================================================");

const mockGroups = [
  {
    _id: new mongoose.Types.ObjectId().toString(),
    name: "Nhóm 1",
    members: [{ userId: mockUserId, netBalance: 0 }],
  },
  {
    _id: new mongoose.Types.ObjectId().toString(),
    name: "Nhóm 2",
    members: [{ userId: mockUserId, netBalance: 50000 }],
  },
];

(Group as any).find = (query: any) => {
  return {
    populate: () => ({
      sort: () => Promise.resolve(mockGroups),
    }),
  };
};

const resMyGroups = createMockResponse();
await getMyGroups(
  {
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  resMyGroups,
  (err: any) => {
    if (err) throw err;
  }
);

if (resMyGroups.statusCode !== 200 || resMyGroups.body?.data?.groups?.length !== 2) {
  throw new Error("FAIL TEST 2: Không lấy được danh sách nhóm của user!");
}
console.log("✓ Lấy danh sách nhóm của user thành công (status 200).");

console.log("\n=================================================");
console.log("TEST 3: Kiểm tra Controller getGroupDetail (Chi tiết nhóm)");
console.log("=================================================");

const validGroupId = new mongoose.Types.ObjectId().toString();
const otherUserId = new mongoose.Types.ObjectId().toString();

// 3.1 Nhóm không tồn tại -> 404
(Group as any).findById = (id: any) => ({
  populate: () => ({
    populate: () => ({
      populate: () => Promise.resolve(null),
    }),
  }),
});

let notFoundErr: any = null;
await getGroupDetail(
  {
    params: { groupId: validGroupId },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  createMockResponse(),
  (err: any) => {
    notFoundErr = err;
  }
);
if (!notFoundErr || notFoundErr.statusCode !== 404) {
  throw new Error("FAIL 3.1: Không trả về 404 khi nhóm không tồn tại!");
}
console.log("✓ Trả về 404 NOT_FOUND khi nhóm không tồn tại.");

// 3.2 User không thuộc nhóm -> 403 FORBIDDEN
const mockGroupNotIn = {
  _id: validGroupId,
  name: "Nhóm người khác",
  members: [{ userId: { _id: otherUserId, toString: () => otherUserId } }],
  simplifiedDebts: [],
};

(Group as any).findById = (id: any) => ({
  populate: () => ({
    populate: () => ({
      populate: () => Promise.resolve(mockGroupNotIn),
    }),
  }),
});

let forbiddenErr: any = null;
await getGroupDetail(
  {
    params: { groupId: validGroupId },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  createMockResponse(),
  (err: any) => {
    forbiddenErr = err;
  }
);
if (!forbiddenErr || forbiddenErr.statusCode !== 403) {
  throw new Error("FAIL 3.2: Không chặn người ngoài nhóm (403 FORBIDDEN)!");
}
console.log("✓ Chặn người ngoài nhóm thành công (403 FORBIDDEN).");

// 3.3 User thuộc nhóm -> 200 kèm group và expenses
const mockGroupDetail = {
  _id: validGroupId,
  name: "Nhóm Hợp Lệ",
  members: [
    {
      userId: {
        _id: mockUserId,
        name: "Huỳnh Đăng",
        email: "dang@gmail.com",
        toString: () => mockUserId,
      },
      netBalance: 0,
    },
  ],
  simplifiedDebts: [],
};

(Group as any).findById = (id: any) => ({
  populate: () => ({
    populate: () => ({
      populate: () => Promise.resolve(mockGroupDetail),
    }),
  }),
});

const mockExpenses = [
  {
    _id: new mongoose.Types.ObjectId().toString(),
    title: "Tiền trà sữa",
    totalAmount: 120000,
    paidBy: { name: "Huỳnh Đăng", email: "dang@gmail.com" },
  },
];

(Expense as any).find = (query: any) => ({
  populate: () => ({
    sort: () => Promise.resolve(mockExpenses),
  }),
});

const resDetail = createMockResponse();
await getGroupDetail(
  {
    params: { groupId: validGroupId },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  resDetail,
  (err: any) => {
    if (err) throw err;
  }
);

if (
  resDetail.statusCode !== 200 ||
  !resDetail.body?.data?.group ||
  resDetail.body?.data?.expenses?.length !== 1
) {
  throw new Error("FAIL 3.3: Lấy chi tiết nhóm và expenses thất bại!");
}
console.log("✓ Lấy chi tiết nhóm và danh sách hóa đơn thành công (status 200).");

console.log("\n=================================================");
console.log("TEST 4: Kiểm tra Controller addMember (Thêm thành viên)");
console.log("=================================================");

const mockNewUser = {
  _id: new mongoose.Types.ObjectId().toString(),
  name: "Bình Nguyễn",
  email: "binh@gmail.com",
};

// 4.1 Thêm email không tồn tại trong hệ thống -> 404
let inMemoryGroup: any = {
  _id: validGroupId,
  name: "Nhóm Đang Test",
  members: [
    {
      userId: mockUserId,
      netBalance: 0,
    },
  ],
  simplifiedDebts: [],
  async save() {
    return this;
  },
};

(Group as any).findById = (id: any) => {
  return {
    populate: () => ({
      populate: () => ({
        populate: () => Promise.resolve(inMemoryGroup),
      }),
    }),
    then(onFulfilled: any) {
      return Promise.resolve(onFulfilled(inMemoryGroup));
    },
  };
};

(User as any).findOne = async () => null;

let userNotFoundErr: any = null;
await addMember(
  {
    params: { groupId: validGroupId },
    body: { email: "khongtontai@gmail.com" },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  createMockResponse(),
  (err: any) => {
    userNotFoundErr = err;
  }
);
if (!userNotFoundErr || userNotFoundErr.statusCode !== 404) {
  throw new Error("FAIL 4.1: Không báo lỗi 404 khi email chưa đăng ký!");
}
console.log("✓ Báo lỗi 404 NOT_FOUND khi không tìm thấy email người dùng.");

// 4.2 Thêm user đã có trong nhóm -> 400 BAD_REQUEST
(User as any).findOne = async () => ({
  _id: mockUserId,
  email: "dang@gmail.com",
});

let alreadyMemberErr: any = null;
await addMember(
  {
    params: { groupId: validGroupId },
    body: { email: "dang@gmail.com" },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  createMockResponse(),
  (err: any) => {
    alreadyMemberErr = err;
  }
);
if (!alreadyMemberErr || alreadyMemberErr.statusCode !== 400) {
  throw new Error("FAIL 4.2: Không chặn khi user đã là thành viên (400 BAD_REQUEST)!");
}
console.log("✓ Chặn thành công khi user đã là thành viên (400 BAD_REQUEST).");

// 4.3 Thêm thành viên mới hợp lệ -> 200
(User as any).findOne = async () => mockNewUser;

const resAddMember = createMockResponse();
await addMember(
  {
    params: { groupId: validGroupId },
    body: { email: "binh@gmail.com" },
    user: { userId: mockUserId, email: "dang@gmail.com" },
  } as unknown as Request,
  resAddMember,
  (err: any) => {
    if (err) throw err;
  }
);

if (resAddMember.statusCode !== 200) {
  throw new Error(`FAIL 4.3: Status code kỳ vọng 200, nhận được ${resAddMember.statusCode}`);
}
if (inMemoryGroup.members.length !== 2) {
  throw new Error("FAIL 4.3: Thành viên mới chưa được thêm vào group.members!");
}
const addedMember = inMemoryGroup.members[1];
if (addedMember.userId !== mockNewUser._id || addedMember.netBalance !== 0) {
  throw new Error("FAIL 4.3: Thành viên mới khởi tạo netBalance không bằng 0!");
}
console.log("✓ Thêm thành viên mới thành công (status 200, netBalance = 0).");

console.log("\n=================================================");
console.log("TEST 5: Kiểm tra cấu hình router (group.routes.ts)");
console.log("=================================================");
if (!groupRoutes) {
  throw new Error("FAIL TEST 5: groupRoutes chưa được xuất khẩu!");
}
console.log("✓ group.routes.ts đã được cấu hình và xuất khẩu hoàn chỉnh.");

// Phục hồi lại Mongoose gốc
Group.create = origGroupCreate;
Group.find = origGroupFind;
Group.findById = origGroupFindById;
User.findOne = origUserFindOne;
Expense.find = origExpenseFind;

console.log("\n=================================================");
console.log("TẤT CẢ TIÊU CHÍ BƯỚC 4.2 ĐÃ VƯỢT QUA 100%!");
console.log("=================================================");
