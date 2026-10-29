import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

void main() {
  testWidgets('NoteTile menampilkan judul dan badge belum tersinkron',
          (WidgetTester tester) async {
        final dirtyNote = Note(
          id: 1,
          title: 'Catatan Kotor',
          body: 'Isi catatan',
          updatedAt: DateTime(2026, 9, 21),
          dirty: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NoteTile(note: dirtyNote),
            ),
          ),
        );

        expect(find.text('Catatan Kotor'), findsOneWidget);
        expect(find.text('belum tersinkron'), findsOneWidget);
        expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      });

  testWidgets('NoteTile menampilkan ikon cloud_done bila sudah tersinkron',
          (WidgetTester tester) async {
        final cleanNote = Note(
          id: 2,
          title: 'Catatan Bersih',
          body: 'Isi catatan',
          updatedAt: DateTime(2026, 9, 21),
          dirty: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NoteTile(note: cleanNote),
            ),
          ),
        );

        expect(find.text('Catatan Bersih'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      });
}