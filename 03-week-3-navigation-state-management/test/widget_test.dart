import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:week3_navigation_state_management/main.dart';

void main() {
  testWidgets('menampilkan daftar dan navigasi ke statistik', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Riset kebutuhan pengguna'), findsOneWidget);
    expect(find.text('Implementasi halaman utama'), findsNothing);

    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan produktivitas'), findsOneWidget);
    expect(find.text('Total tugas'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('menampilkan error dan dapat mencoba lagi', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    await tester.tap(find.byTooltip('Simulasikan error'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Simulasi gagal terhubung ke server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
