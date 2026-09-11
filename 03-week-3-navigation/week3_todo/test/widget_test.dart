import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/main.dart';

void main() {
  testWidgets('menampilkan todo belum selesai dan halaman statistik',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Mouse'), findsOneWidget);
    expect(find.text('Monitor'), findsNothing);

    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();

    expect(find.text('Total tugas: 3'), findsOneWidget);
    expect(find.text('Selesai: 1'), findsOneWidget);
  });
}
