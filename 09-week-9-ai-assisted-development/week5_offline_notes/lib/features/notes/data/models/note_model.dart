import '../../domain/entities/note.dart';

/// Jembatan antara entity domain murni dan bentuk baris tabel `notes`.
///
/// `toMap`/`fromMap` dulu menempel pada entity `Note` itu sendiri, sehingga
/// bentuk row SQLite bocor ke domain. Di sini bentuk itu dikubur: hanya layer
/// data yang tahu kolomnya disebut apa.
class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body,
    required super.updatedAt,
    super.dirty,
  });

  static final _fallbackUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  factory NoteModel.fromEntity(Note note) => NoteModel(
    id: note.id,
    title: note.title,
    body: note.body,
    updatedAt: note.updatedAt,
    dirty: note.dirty,
  );

  factory NoteModel.fromMap(Map<String, Object?> map) => NoteModel(
    id: (map['id'] as num?)?.toInt(),
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(map['updated_at'] as String? ?? '') ??
        _fallbackUpdatedAt,
    dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': updatedAt.toIso8601String(),
    'dirty': dirty ? 1 : 0,
  };
}
