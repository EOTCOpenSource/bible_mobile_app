import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BibleApp());
    expect(find.byType(BibleApp), findsOneWidget);
  });
}
