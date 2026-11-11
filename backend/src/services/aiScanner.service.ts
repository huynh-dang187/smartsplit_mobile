import { GoogleGenAI, Type, type Schema } from "@google/genai";
import { v4 as uuidv4 } from "uuid";
import dotenv from "dotenv";
import { ParsedReceiptSchema, type ParsedReceipt } from "../schemas/expense.schema.js";

dotenv.config();

const apiKey = process.env.GEMINI_API_KEY || "";
const ai = new GoogleGenAI({ apiKey });

/** Model name: mặc định sử dụng gemini-3.6-flash (hoặc linh hoạt cấu hình qua biến môi trường GEMINI_MODEL) */
const MODEL_NAME = process.env.GEMINI_MODEL || "gemini-3.6-flash";

/**
 * Cấu trúc JSON Schema ép Gemini trả về dữ liệu chuẩn
 */
export const receiptResponseSchema: Schema = {
  type: Type.OBJECT,
  properties: {
    merchantName: {
      type: Type.STRING,
      description: "Tên nhà hàng, quán ăn, quán cà phê hoặc cửa hàng trên hóa đơn.",
    },
    items: {
      type: Type.ARRAY,
      description: "Danh sách các món ăn, đồ uống hoặc dịch vụ thực tế được mua.",
      items: {
        type: Type.OBJECT,
        properties: {
          name: {
            type: Type.STRING,
            description: "Tên món hoặc dịch vụ",
          },
          quantity: {
            type: Type.NUMBER,
            description: "Số lượng món (mặc định 1 nếu không ghi)",
          },
          unitPrice: {
            type: Type.NUMBER,
            description: "Đơn giá của món tính bằng số nguyên VNĐ",
          },
          totalPrice: {
            type: Type.NUMBER,
            description: "Thành tiền của món (quantity * unitPrice) tính bằng số nguyên VNĐ",
          },
        },
        required: ["name", "quantity", "unitPrice", "totalPrice"],
      },
    },
    extraCharges: {
      type: Type.OBJECT,
      description: "Các phụ phí hoặc giảm giá ngoài tiền món",
      properties: {
        tax: {
          type: Type.NUMBER,
          description: "Thuế VAT tính bằng số nguyên VNĐ (mặc định 0 nếu không có)",
        },
        serviceCharge: {
          type: Type.NUMBER,
          description: "Phí phục vụ tính bằng số nguyên VNĐ (mặc định 0 nếu không có)",
        },
        discount: {
          type: Type.NUMBER,
          description: "Giảm giá, voucher, khuyến mại dạng số dương bằng số nguyên VNĐ (mặc định 0)",
        },
      },
      required: ["tax", "serviceCharge", "discount"],
    },
    subtotalAmount: {
      type: Type.NUMBER,
      description: "Tổng tiền các món gốc cộng lại (chưa gồm thuế, phí, giảm giá) bằng số nguyên VNĐ",
    },
    totalAmount: {
      type: Type.NUMBER,
      description: "Tổng số tiền thực tế khách phải trả cuối cùng trên hóa đơn bằng số nguyên VNĐ",
    },
  },
  required: ["merchantName", "items", "extraCharges", "subtotalAmount", "totalAmount"],
};

/**
 * Prompt chỉ thị tiếng Việt gửi kèm ảnh hóa đơn
 */
export const RECEIPT_SCAN_PROMPT = `
Bạn là chuyên gia AI bóc tách hóa đơn ăn uống, tiêu dùng tại Việt Nam cho ứng dụng SmartSplit.
Nhiệm vụ của bạn là đọc hình ảnh hóa đơn và trích xuất dữ liệu thành cấu trúc JSON.

QUY TẮC BẮT BUỘC:
1. Quy đổi TOÀN BỘ số tiền về số nguyên VNĐ (Integer, không dùng số thập phân).
   - Ví dụ: '150.000', '150k', '150.000đ' đều quy đổi thành 150000.
2. KHÔNG LẤY các dòng thông tin thanh toán vào danh sách items:
   - Các dòng như 'Tiền khách đưa', 'Tiền mặt', 'Chuyển khoản', 'Tiền thối lại', 'Tiền thừa', 'Trả lại', 'Thẻ ngân hàng', 'Quẹt thẻ' KHÔNG PHẢI là món ăn/hàng hóa.
   - Items CHỈ chứa danh sách món ăn, đồ uống hoặc dịch vụ thực sự được mua.
3. Nếu có Thuế VAT: ghi vào extraCharges.tax (số nguyên VNĐ).
4. Nếu có Phí dịch vụ (Service Charge): ghi vào extraCharges.serviceCharge (số nguyên VNĐ).
5. Nếu có Giảm giá / Khuyến mãi / Voucher: ghi vào extraCharges.discount dạng số DƯƠNG (số nguyên VNĐ).
6. subtotalAmount là tổng tiền hàng gốc trước thuế/phí/giảm giá.
7. totalAmount là tổng tiền thực tế khách cần thanh toán cuối cùng.
8. Trả về đúng cấu trúc JSON theo responseSchema.
`;

/**
 * Hàm xử lý chuẩn hóa dữ liệu JSON nhận được từ Gemini:
 * - Làm tròn các số tiền (Math.round)
 * - Gắn id uuidv4() cho từng item
 * - Tính subtotalAmount = sum(items.totalPrice)
 * - Tính calculatedTotal = subtotal + tax + serviceCharge - discount
 * - Đặt cờ isDiscrepancy = (calculatedTotal !== totalAmount)
 * - Validate bằng ParsedReceiptSchema
 */
export function processGeminiReceiptResponse(rawText: string): ParsedReceipt {
  let parsed: any;
  try {
    parsed = JSON.parse(rawText);
  } catch (err) {
    throw new Error(`AI_PARSE_FAILED: Dữ liệu AI trả về không phải định dạng JSON hợp lệ: ${err}`);
  }

  // 1. Chuẩn hóa danh sách items và gán uuid
  const rawItems = Array.isArray(parsed.items) ? parsed.items : [];
  if (rawItems.length === 0) {
    throw new Error("AI_PARSE_FAILED: Không nhận diện được món ăn nào trên hóa đơn");
  }

  const items = rawItems.map((item: any) => {
    const quantity = Math.max(1, Math.round(Number(item.quantity) || 1));
    const unitPrice = Math.max(0, Math.round(Number(item.unitPrice) || 0));
    const totalPrice = Math.max(
      0,
      Math.round(Number(item.totalPrice) || quantity * unitPrice)
    );

    return {
      id: uuidv4(),
      name: String(item.name || "").trim() || "Món ăn",
      quantity,
      unitPrice,
      totalPrice,
    };
  });

  // 2. Chuẩn hóa phụ phí (extraCharges)
  const tax = Math.max(0, Math.round(Number(parsed.extraCharges?.tax) || 0));
  const serviceCharge = Math.max(
    0,
    Math.round(Number(parsed.extraCharges?.serviceCharge) || 0)
  );
  const discount = Math.max(
    0,
    Math.round(Number(parsed.extraCharges?.discount) || 0)
  );

  const extraCharges = {
    tax,
    serviceCharge,
    discount,
  };

  // 3. Tính subtotalAmount = tổng tiền các món gốc
  const subtotalAmount = items.reduce((sum: number, it: any) => sum + it.totalPrice, 0);

  // 4. Lấy totalAmount ghi trên hóa đơn (làm tròn số nguyên)
  const rawTotal = Number(parsed.totalAmount);
  const totalAmount =
    !isNaN(rawTotal) && rawTotal > 0
      ? Math.round(rawTotal)
      : Math.round(subtotalAmount + tax + serviceCharge - discount);

  // 5. Tính calculatedTotal và cờ isDiscrepancy
  const calculatedTotal = Math.round(subtotalAmount + tax + serviceCharge - discount);
  const isDiscrepancy = calculatedTotal !== totalAmount;

  // 6. Tên cửa hàng / hóa đơn
  const merchantName =
    String(parsed.merchantName || "").trim() || "Hóa đơn mới";

  const resultPayload = {
    merchantName,
    items,
    extraCharges,
    subtotalAmount,
    totalAmount,
    calculatedTotal,
    isDiscrepancy,
  };

  // 7. Validate nghiêm ngặt bằng ParsedReceiptSchema khớp 100% contract
  return ParsedReceiptSchema.parse(resultPayload);
}

/**
 * Quét ảnh hóa đơn bằng Gemini Vision AI và trả về dữ liệu ParsedReceipt chuẩn
 * @param imageBuffer Buffer chứa dữ liệu nhị phân của ảnh hóa đơn
 * @param mimeType Định dạng file ảnh (image/jpeg, image/png, image/webp...)
 */
export async function scanReceiptWithAI(
  imageBuffer: Buffer,
  mimeType: string = "image/jpeg"
): Promise<ParsedReceipt> {
  if (!apiKey) {
    throw new Error("AI_PARSE_FAILED: Chưa cấu hình GEMINI_API_KEY trong biến môi trường (.env)");
  }

  const base64Data = imageBuffer.toString("base64");

  try {
    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: [
        {
          inlineData: {
            data: base64Data,
            mimeType: mimeType || "image/jpeg",
          },
        },
        {
          text: RECEIPT_SCAN_PROMPT,
        },
      ],
      config: {
        responseMimeType: "application/json",
        responseSchema: receiptResponseSchema,
      },
    });

    const responseText = response.text;
    if (!responseText) {
      throw new Error("AI_PARSE_FAILED: Gemini không trả về dữ liệu văn bản");
    }

    return processGeminiReceiptResponse(responseText);
  } catch (error: any) {
    if (error.message?.startsWith("AI_PARSE_FAILED")) {
      throw error;
    }
    throw new Error(`AI_PARSE_FAILED: Lỗi khi gọi Gemini Vision AI: ${error.message || error}`);
  }
}

export const aiScannerService = {
  scanReceiptWithAI,
};

