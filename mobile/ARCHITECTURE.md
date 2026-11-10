# SMARTSPLIT MOBILE — KIẾN TRÚC HỆ THỐNG (ARCHITECTURE SPECIFICATION)

> **Tài liệu quy chuẩn kiến trúc phần mềm cho ứng dụng SmartSplit Mobile (Flutter)**  
> Tuân theo mô hình **4 Trục (`common`, `core`, `features`, `shared`) + Feature-First MVVM + Cubit**.

---

## 1. TỔNG QUAN 4 TRỤC KIẾN TRÚC

```text
mobile/lib/
├── main.dart
└── src/
    ├── common/             # Tài nguyên chung không phụ thuộc logic nghiệp vụ
    │   ├── configs/        # Cấu hình môi trường (baseUrl, timeouts)
    │   ├── constants/      # Design Tokens (AppColors, AppSpacing, AppTheme, BankBins)
    │   ├── extensions/     # Tiện ích mở rộng (context_x, num_x)
    │   └── utils/          # Công cụ hỗ trợ độc lập (currency_formatter, vietqr_helper)
    ├── core/               # Lõi hệ thống dùng chung toàn bộ ứng dụng
    │   ├── domain/         # Thực thể cốt lõi & trạng thái hệ thống
    │   │   ├── entities/   # base_result.dart (BaseResult<T>)
    │   │   └── enums/      # bloc_status.dart (enum BlocStatus)
    │   ├── infrastructure/ # Tầng dữ liệu hạ tầng & Client mạng
    │   │   ├── datasources/
    │   │   │   ├── local/   # secured_storage.dart (SharedPreferences lưu Token, User)
    │   │   │   └── network/
    │   │   │       └── api/ # restful_request.dart (Dio client chuẩn hóa), endpoint_type.dart
    │   │   └── model/       # user_model.dart, bank_info_model.dart (DTO dùng chung)
    │   └── presentation/   # Giao diện và Quản lý trạng thái mức ứng dụng
    │       ├── blocs/       # get_it.dart (Service Locator DI)
    │       ├── cubit/app/   # app_cubit.dart & app_state.dart (Auth toàn cục)
    │       ├── pages/       # app.dart (Root MaterialApp)
    │       └── widgets/     # common_loading.dart, common_button.dart, common_error_view.dart
    ├── features/           # Các phân hệ chức năng nghiệp vụ (Feature-First MVVM)
    │   ├── auth/            # Đăng nhập, Đăng ký, Cập nhật thông tin ngân hàng Napas
    │   ├── groups/          # Quản lý nhóm, Thành viên, Chi tiết số dư nợ, Settle Up
    │   └── expenses/        # Quét hóa đơn AI Gemini, Phân bổ chi phí Pro-rata (SplitWorkspace)
    └── shared/             # Các mô-đun chia sẻ điều hướng
        └── router/          # app_router.dart (Hệ thống điều hướng màn hình)
```

---

## 2. QUY TẮC PHÁT TRIỂN BẮT BUỘC (STRICT CODING RULES)

### 2.1. Quản lý trạng thái Cubit & State
1. **Không dùng `Equatable`, không dùng `sealed class` cho State:**
   - Luôn sử dụng cơ chế `part '<name>_state.dart';` trong file cubit và `part of '<name>_cubit.dart';` trong file state.
   - Mọi State đều là `final class <Name>State` chứa:
     - `final BlocStatus status;`
     - `final String? errorMessage;`
     - Hàm `copyWith(...)`.
2. **An toàn Bất đồng bộ (Async Safety) & Chống rò rỉ bộ nhớ:**
   - Sau mọi lệnh gọi API hoặc I/O bất đồng bộ (`await _repository...`), **bắt buộc** phải có kiểm tra:
     ```dart
     if (isClosed) return;
     ```
     trước khi gọi hàm `emit(...)`.
3. **Xử lý Side Effects (Dialog, SnackBar, Chuyển màn hình):**
   - Các hàm gọi API trong Cubit nhận callback:
     ```dart
     Future<void> submit({
       Function(String error)? onError,
       VoidCallback? onSuccess,
     }) async { ... }
     ```
   - View chủ động kích hoạt Side Effects trong `onSuccess` hoặc `onError`, không lạm dụng `BlocListener`.
4. **Chuẩn mực tại View (Presentation Layer):**
   - Khởi tạo Cubit qua `BlocProvider` trong hàm `build()` của Screen/Page.
   - Dùng `BlocBuilder` lắng nghe và tái dựng giao diện dựa trên `state.status` (`isLoading`, `isError`, `hasData`).
   - Gọi hành động qua `context.read<NameCubit>().action(...)` trong sự kiện `onTap`/`onPressed`.

### 2.2. Chuẩn hóa Tầng Dữ liệu với `BaseResult<T>` và `RestfulRequest`
1. **Chuẩn API Contract:**
   - Mọi API Response từ Express backend trả về theo chuẩn:
     ```json
     { "success": true, "message": "...", "data": { ... } }
     ```
     khi thành công, hoặc:
     ```json
     { "success": false, "message": "...", "errorCode": "...", "errors": [] }
     ```
     khi xảy ra lỗi.
2. **Mọi hàm Repository đều trả về `Future<BaseResult<T>>`:**
   - Không ném Exception ra tầng Cubit. Mọi ngoại lệ HTTP (`DioException`), lỗi mạng, hoặc lỗi timeout đều được `RestfulRequest` bắt và chuyển thành `BaseResult<T>(success: false, message: ..., errorCode: ...)`.
3. **Tự động đính kèm JWT Bearer Token:**
   - `RestfulRequest` đọc token từ `SecuredStorage` và tự động gắn vào Header `Authorization: Bearer <token>`.
   - Hỗ trợ đầy đủ các phương thức `GET`, `POST`, `PUT`, `DELETE` và upload `MultipartFile` (quét bill AI).

---

## 3. QUY CHUẨN THIẾT KẾ UI/UX (FINTECH OPERATE MODE)
- **Bảng màu Semantic Tokens**: Quản lý tập trung trong `AppColors` (Emerald Green cho Creditor, Coral Red cho Debtor, Neutral Slate cho Settled, Amber cho Discrepancy, Indigo cho AI).
- **Độ tương phản WCAG AA**: Tỉ lệ tương phản chữ trên nền luôn $\ge 4.5:1$.
- **Vùng chạm di động**: Mọi tap target $\ge 44 \times 44\,\text{dp}$, nút bấm cao $\ge 48\,\text{dp}$.
- **Hiệu ứng & Cú pháp hiện đại**: Sử dụng `Color.withValues(alpha: ...)` thay cho `.withOpacity()`, rung nhẹ xúc giác `HapticFeedback.lightImpact()` khi thực hiện giao dịch tài chính.
