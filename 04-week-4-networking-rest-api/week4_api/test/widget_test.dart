import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week4_api/paged_post_page.dart';

void main() {
  testWidgets('app shows the post list title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    expect(find.text('Posts API'), findsOneWidget);
  });
}
