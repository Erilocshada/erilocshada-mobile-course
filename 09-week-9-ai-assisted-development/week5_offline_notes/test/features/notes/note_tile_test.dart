import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/widgets/note_tile.dart';

/// NoteTile bisa dirender tanpa ProviderScope karena ia murni: input entity,
/// output widget.
void main() {
  Future<void> pumpTile(WidgetTester tester, Note note) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: NoteTile(note: note)),
    ),
  );

  testWidgets('menampilkan judul dan badge belum tersinkron', (tester) async {
    await pumpTile(
      tester,
      Note(
        id: 1,
        title: 'Catatan Kotor',
        body: 'Isi catatan',
        updatedAt: DateTime(2026, 9, 21),
        dirty: true,
      ),
    );

    expect(find.text('Catatan Kotor'), findsOneWidget);
    expect(find.text('belum tersinkron'), findsOneWidget);
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
  });

  testWidgets('menampilkan ikon cloud_done bila sudah tersinkron', (
    tester,
  ) async {
    await pumpTile(
      tester,
      Note(
        id: 2,
        title: 'Catatan Bersih',
        body: 'Isi catatan',
        updatedAt: DateTime(2026, 9, 21),
      ),
    );

    expect(find.text('Catatan Bersih'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });
}
