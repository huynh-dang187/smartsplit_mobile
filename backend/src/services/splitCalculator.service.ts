import type { CreateExpensePayload } from "../schemas/expense.schema.js";

export interface IMemberShareResult {
  userId: string;
  baseAmount: number; // Tiền món gốc của người này (VNĐ)
  extraAmount: number; // Phần thuế + phí - giảm giá phân bổ theo tỷ lệ (VNĐ)
  finalAmount: number; // Tổng thực tế người này phải chịu (VNĐ)
}

export interface IProRataResult {
  subtotalAmount: number;
  memberShares: IMemberShareResult[];
}

export interface ISimplifiedDebtResult {
  fromUser: string; // Ref: 'User' (Người phải chuyển tiền)
  toUser: string; // Ref: 'User' (Người nhận tiền)
  amount: number; // Số tiền cần chuyển (VNĐ)
}

export interface IGroupMemberBalance {
  userId: string;
  netBalance: number;
}

/**
 * 4.1. Công thức chia tiền theo tỷ lệ (Pro-rata Calculation)
 * - S = sum(item.totalPrice)
 * - E = tax + serviceCharge - discount
 * - T = payload.totalAmount
 * - Với mỗi thành viên u:
 *   1. Bu = sum(item.totalPrice / k) cho mọi món u tham gia (k là số người ăn món đó)
 *   2. Eu = Math.round(E * (Bu / S)) (hoặc chia đều nếu S === 0)
 *   3. Fu = Math.round(Bu + Eu)
 *   4. Nếu sum(Fu) !== T, phần chênh lệch Delta = T - sum(Fu) được cộng vào F_paidBy.
 */
export function calculateProRataShares(payload: CreateExpensePayload): IProRataResult {
  // 1. Tính tổng tiền món gốc và phần tiền món gốc của từng người (Bu)
  const baseMap: Record<string, number> = {};
  let totalRawSubtotal = 0;

  for (const item of payload.items) {
    totalRawSubtotal += item.totalPrice;
    const k = item.assignedTo.length;
    if (k > 0) {
      const sharePerPerson = item.totalPrice / k;
      for (const userId of item.assignedTo) {
        baseMap[userId] = (baseMap[userId] ?? 0) + sharePerPerson;
      }
    }
  }

  const S = totalRawSubtotal;
  const subtotalAmount = Math.round(S);

  // Phụ phí ròng E = tax + serviceCharge - discount
  const tax = payload.extraCharges.tax ?? 0;
  const serviceCharge = payload.extraCharges.serviceCharge ?? 0;
  const discount = payload.extraCharges.discount ?? 0;
  const E = tax + serviceCharge - discount;

  const T = Math.round(payload.totalAmount);

  // Danh sách các thành viên tham gia vào món ăn
  const memberIds = Object.keys(baseMap);

  const memberShares: IMemberShareResult[] = memberIds.map((userId) => {
    const Bu = baseMap[userId] ?? 0;
    const baseAmount = Math.round(Bu);

    // Tính phần phụ phí phân bổ
    const rawExtra = S > 0 ? (E * Bu) / S : memberIds.length > 0 ? E / memberIds.length : 0;
    const rawTotal = Bu + rawExtra;
    const finalAmount = Math.round(rawTotal);
    const extraAmount = finalAmount - baseAmount;

    return {
      userId,
      baseAmount,
      extraAmount,
      finalAmount,
    };
  });

  // 4. Xử lý sai số làm tròn: Delta = T - sum(Fu) cộng vào F_paidBy
  const sumFinal = memberShares.reduce((acc, m) => acc + m.finalAmount, 0);
  const delta = T - sumFinal;

  if (delta !== 0) {
    const paidMember = memberShares.find((m) => m.userId === payload.paidBy);
    if (paidMember) {
      paidMember.finalAmount += delta;
      paidMember.extraAmount += delta;
    } else {
      // Trường hợp người trả tiền không ăn món nào trong bill
      memberShares.push({
        userId: payload.paidBy,
        baseAmount: 0,
        extraAmount: delta,
        finalAmount: delta,
      });
    }
  }

  return {
    subtotalAmount,
    memberShares,
  };
}

/**
 * 4.2. Thuật toán Rút gọn nợ chéo (Greedy Debt Simplification)
 * - Tách các thành viên có netBalance != 0 thành 2 danh sách:
 *   + Creditors (Chủ nợ: netBalance > 0), sắp xếp giảm dần.
 *   + Debtors (Con nợ: netBalance < 0), sắp xếp tăng dần (số nợ tuyệt đối lớn nhất đứng đầu).
 * - Lặp khi cả 2 danh sách còn phần tử:
 *   + Lấy chủ nợ lớn nhất C và con nợ lớn nhất D.
 *   + Số tiền chuyển M = min(C.balance, |D.balance|).
 *   + Tạo bản ghi { fromUser: D.userId, toUser: C.userId, amount: M }.
 *   + Cập nhật C.balance -= M và D.balance += M. Loại bỏ người nào đã về 0.
 */
export function simplifyGroupDebts(
  members: Array<{ userId: string; netBalance: number }>
): ISimplifiedDebtResult[] {
  const creditors: Array<{ userId: string; balance: number }> = [];
  const debtors: Array<{ userId: string; balance: number }> = [];

  for (const m of members) {
    const bal = Math.round(m.netBalance);
    if (bal > 0) {
      creditors.push({ userId: m.userId, balance: bal });
    } else if (bal < 0) {
      debtors.push({ userId: m.userId, balance: bal });
    }
  }

  // Creditors: Giảm dần theo số dư dương (lớn nhất trước)
  creditors.sort((a, b) => b.balance - a.balance);

  // Debtors: Tăng dần theo giá trị âm (tức số nợ tuyệt đối lớn nhất đứng trước, VD: -100k trước -50k)
  debtors.sort((a, b) => a.balance - b.balance);

  const simplifiedDebts: ISimplifiedDebtResult[] = [];
  let i = 0;
  let j = 0;

  while (i < creditors.length && j < debtors.length) {
    const c = creditors[i]!;
    const d = debtors[j]!;

    const amount = Math.min(c.balance, Math.abs(d.balance));
    if (amount > 0) {
      simplifiedDebts.push({
        fromUser: d.userId,
        toUser: c.userId,
        amount,
      });
    }

    c.balance -= amount;
    d.balance += amount;

    if (Math.round(c.balance) === 0) i++;
    if (Math.round(d.balance) === 0) j++;
  }

  return simplifiedDebts;
}
