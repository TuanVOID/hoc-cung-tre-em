import 'package:flutter_test/flutter_test.dart';
import 'package:hoc_cung_tre_em/app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HocCungTreEmApp());
    expect(find.text('Xin chào! 👋'), findsOneWidget);
    expect(find.text('Vào Học'), findsOneWidget);
    expect(find.text('Hỏi Gia Sư'), findsOneWidget);
  });
}
