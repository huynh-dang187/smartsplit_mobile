import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsplit_mobile/src/common/utils/currency_formatter.dart';
import 'package:smartsplit_mobile/src/common/utils/vietqr_helper.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/pages/app.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await initDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('SmartSplitRootApp khởi chạy và hiển thị màn hình chính', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartSplitRootApp());
    await tester.pumpAndSettle();

    expect(find.text('SmartSplit'), findsWidgets);
    expect(find.text('Chào mừng đến với SmartSplit'), findsOneWidget);
  });

  test('CurrencyFormatter định dạng tiền VNĐ chuẩn số nguyên', () {
    expect(CurrencyFormatter.formatNumberOnly(150000), '150.000');
    expect(CurrencyFormatter.formatSignedVnd(150000), contains('+150.000'));
    expect(CurrencyFormatter.formatSignedVnd(-50000), contains('-50.000'));
    expect(CurrencyFormatter.parseVnd('150.000 đ'), 150000);
  });

  test('VietQrHelper sinh URL ảnh VietQR đúng chuẩn Mục 6 contract.md', () {
    final url = VietQrHelper.generateQrUrl(
      bankBin: '970436',
      accountNo: '123456789',
      amount: 150000,
      accountName: 'NGUYEN VAN A',
      fromUserName: 'An',
      groupName: 'NuongBBQ',
    );

    expect(url, contains('https://img.vietqr.io/image/970436-123456789-compact2.png'));
    expect(url, contains('amount=150000'));
    expect(url, contains('SmartSplit%20An%20thanh%20toan%20NuongBBQ'));
    expect(url, contains('accountName=NGUYEN%20VAN%20A'));
  });
}
