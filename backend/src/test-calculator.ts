import { calculateProRataShares, simplifyGroupDebts } from "./services/splitCalculator.service.js";

console.log("=================================================");
console.log("TEST KỊCH BẢN 1: Chia tiền Pro-rata (110.000đ cho 3 người A, B, C)");
console.log("=================================================");

const testPayload = {
  title: "Lẩu Thái Tomyum",
  paidBy: "A",
  items: [
    {
      name: "Lẩu Thái",
      quantity: 1,
      unitPrice: 100000,
      totalPrice: 100000,
      assignedTo: ["A", "B", "C"],
    },
  ],
  extraCharges: {
    tax: 10000,
    serviceCharge: 0,
    discount: 0,
  },
  totalAmount: 110000,
};

const proRataResult = calculateProRataShares(testPayload);
console.log("Subtotal gốc (S):", proRataResult.subtotalAmount);
console.log("Chi tiết phần chia của từng thành viên (memberShares):");
console.table(proRataResult.memberShares);

const totalDistributed = proRataResult.memberShares.reduce((sum, m) => sum + m.finalAmount, 0);
console.log(`\nTổng tiền phân bổ: ${totalDistributed} VNĐ (Kỳ vọng: 110000 VNĐ)`);

const shareA = proRataResult.memberShares.find((m) => m.userId === "A");
const shareB = proRataResult.memberShares.find((m) => m.userId === "B");
const shareC = proRataResult.memberShares.find((m) => m.userId === "C");

console.log(`- Người trả tiền (A) chịu: ${shareA?.finalAmount} VNĐ`);
console.log(`- Thành viên (B) chịu: ${shareB?.finalAmount} VNĐ`);
console.log(`- Thành viên (C) chịu: ${shareC?.finalAmount} VNĐ`);

if (totalDistributed !== 110000) {
  throw new Error(`FAIL KỊCH BẢN 1: Tổng tiền không khớp 110.000đ! (Thực tế: ${totalDistributed})`);
}
if (shareA?.finalAmount !== 36666 || shareB?.finalAmount !== 36667 || shareC?.finalAmount !== 36667) {
  throw new Error(
    `FAIL KỊCH BẢN 1: Sai lệch số tiền từng người! (A: ${shareA?.finalAmount}, B: ${shareB?.finalAmount}, C: ${shareC?.finalAmount})`
  );
}
console.log(">>> ✓ KỊCH BẢN 1 ĐẠT 100% TIÊU CHÍ!");

console.log("\n=================================================");
console.log("TEST KỊCH BẢN 2: Rút gọn nợ bắc cầu A -> B -> C");
console.log("=================================================");

const testMembers = [
  { userId: "A", netBalance: -100000 },
  { userId: "B", netBalance: 0 },
  { userId: "C", netBalance: 100000 },
];

console.log("Danh sách netBalance ban đầu:");
console.table(testMembers);

const debts = simplifyGroupDebts(testMembers);
console.log("\nKết quả giao dịch nợ rút gọn (simplifiedDebts):");
console.table(debts);

if (debts.length !== 1) {
  throw new Error(`FAIL KỊCH BẢN 2: Số giao dịch không phải 1! (Thực tế: ${debts.length})`);
}
if (debts[0]?.fromUser !== "A" || debts[0]?.toUser !== "C" || debts[0]?.amount !== 100000) {
  throw new Error(`FAIL KỊCH BẢN 2: Giao dịch không khớp A -> C 100.000đ!`);
}
console.log(">>> ✓ KỊCH BẢN 2 ĐẠT 100% TIÊU CHÍ!");

console.log("\n=================================================");
console.log("TẤT CẢ TIÊU CHÍ NGHIỆM THU ĐÃ VƯỢT QUA XUẤT SẮC!");
console.log("=================================================");
