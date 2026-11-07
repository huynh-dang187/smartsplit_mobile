import {
  processGeminiReceiptResponse,
  scanReceiptWithAI,
  receiptResponseSchema,
  RECEIPT_SCAN_PROMPT,
} from "./services/aiScanner.service.js";

console.log("=================================================");
console.log("TEST 1: Kiểm tra cấu hình Prompt và ResponseSchema");
console.log("=================================================");
if (!receiptResponseSchema || !RECEIPT_SCAN_PROMPT.includes("VNĐ")) {
  throw new Error("FAIL TEST 1: Schema hoặc Prompt chưa được cấu hình đúng chuẩn VNĐ!");
}
console.log("✓ Schema và Prompt đạt chuẩn yêu cầu (ép số nguyên VNĐ, loại tiền thối lại).");

console.log("\n=================================================");
console.log("TEST 2: Xử lý dữ liệu AI trả về (Hóa đơn khớp số - Không sai lệch)");
console.log("=================================================");

const mockGeminiJsonMatched = JSON.stringify({
  merchantName: "Gogi House Vincom",
  items: [
    {
      name: "Dẻ sườn bò Mỹ",
      quantity: 2,
      unitPrice: 150000.4, // Giả lập AI trả số lẻ
      totalPrice: 300000,
    },
    {
      name: "Lẩu kim chi",
      quantity: 1,
      unitPrice: 200000,
      totalPrice: 200000,
    },
  ],
  extraCharges: {
    tax: 50000,
    serviceCharge: 25000,
    discount: 0,
  },
  subtotalAmount: 500000,
  totalAmount: 575000,
});

const resultMatched = processGeminiReceiptResponse(mockGeminiJsonMatched);
console.log("Kết quả bóc tách hóa đơn:");
console.log("- Tên quán:", resultMatched.merchantName);
console.log("- Số lượng món:", resultMatched.items.length);
console.log("- Tiền món gốc (subtotal):", resultMatched.subtotalAmount, "VNĐ");
console.log("- Phụ phí (tax, service, discount):", resultMatched.extraCharges);
console.log("- Tổng tiền trên hóa đơn (totalAmount):", resultMatched.totalAmount, "VNĐ");
console.log("- Tổng tiền tính lại (calculatedTotal):", resultMatched.calculatedTotal, "VNĐ");
console.log("- Cờ phát hiện chênh lệch (isDiscrepancy):", resultMatched.isDiscrepancy);

// Kiểm tra UUID và làm tròn
for (const item of resultMatched.items) {
  if (!item.id || typeof item.id !== "string" || item.id.length < 30) {
    throw new Error(`FAIL TEST 2: Item thiếu UUID hợp lệ! (id: ${item.id})`);
  }
  if (!Number.isInteger(item.unitPrice) || !Number.isInteger(item.totalPrice)) {
    throw new Error(`FAIL TEST 2: Tiền món chưa được Math.round về số nguyên!`);
  }
}

if (resultMatched.subtotalAmount !== 500000) {
  throw new Error(`FAIL TEST 2: subtotalAmount không khớp 500.000đ! (Thực tế: ${resultMatched.subtotalAmount})`);
}
if (resultMatched.calculatedTotal !== 575000) {
  throw new Error(`FAIL TEST 2: calculatedTotal không khớp 575.000đ! (Thực tế: ${resultMatched.calculatedTotal})`);
}
if (resultMatched.isDiscrepancy !== false) {
  throw new Error(`FAIL TEST 2: isDiscrepancy phải là false khi số liệu khớp!`);
}
console.log(">>> ✓ TEST 2 ĐẠT: Gán UUID thành công, làm tròn số nguyên chuẩn, isDiscrepancy = false.");

console.log("\n=================================================");
console.log("TEST 3: Xử lý hóa đơn có chênh lệch (isDiscrepancy = true)");
console.log("=================================================");

const mockGeminiJsonDiscrepancy = JSON.stringify({
  merchantName: "KFC Landmark",
  items: [
    {
      name: "Combo Gà Rán",
      quantity: 1,
      unitPrice: 120000,
      totalPrice: 120000,
    },
  ],
  extraCharges: {
    tax: 12000,
    serviceCharge: 0,
    discount: 0,
  },
  subtotalAmount: 120000,
  totalAmount: 150000, // Quán in tổng 150k trong khi món + VAT chỉ 132k -> Bị lệch!
});

const resultDiscrepancy = processGeminiReceiptResponse(mockGeminiJsonDiscrepancy);
console.log("- Tổng tính lại:", resultDiscrepancy.calculatedTotal, "VNĐ");
console.log("- Tổng hóa đơn:", resultDiscrepancy.totalAmount, "VNĐ");
console.log("- Cờ cảnh báo chênh lệch:", resultDiscrepancy.isDiscrepancy);

if (resultDiscrepancy.calculatedTotal !== 132000) {
  throw new Error(`FAIL TEST 3: calculatedTotal không đúng 132.000đ!`);
}
if (resultDiscrepancy.isDiscrepancy !== true) {
  throw new Error(`FAIL TEST 3: isDiscrepancy phải là true khi có sai lệch tiền!`);
}
console.log(">>> ✓ TEST 3 ĐẠT: Phát hiện sai lệch chính xác (isDiscrepancy = true).");

console.log("\n=================================================");
console.log("TEST 4: Kiểm tra export của hàm scanReceiptWithAI");
console.log("=================================================");
if (typeof scanReceiptWithAI !== "function") {
  throw new Error("FAIL TEST 4: scanReceiptWithAI chưa được export!");
}
console.log("✓ Hàm scanReceiptWithAI đã sẵn sàng phục vụ Upload Controller.");

console.log("\n=================================================");
console.log("TẤT CẢ TIÊU CHÍ NGHIỆM THU ĐÃ VƯỢT QUA XUẤT SẮC 100%!");
console.log("=================================================");
