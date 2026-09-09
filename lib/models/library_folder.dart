// models/library_folder.dart
//
// A folder in the Saved Sessions library. Folders only organise sessions — the
// sessions themselves are owned by SavedSessionsService; this layer just stores
// the tree, and each session records which folder it lives in via its own
// `folderId`. Mirrors the looper / ear-training library.

import 'dart:math';

String generateFolderId() =>
    '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';

class LibraryFolder {
  const LibraryFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parentId,
    this.colorValue,
  });

  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  /// Optional user-picked tint (ARGB int), macOS-style. Null = default coral.
  final int? colorValue;

  LibraryFolder copyWith({
    String? name,
    String? parentId,
    bool clearParent = false,
    int? colorValue,
    bool clearColor = false,
  }) =>
      LibraryFolder(
        id: id,
        name: name ?? this.name,
        parentId: clearParent ? null : (parentId ?? this.parentId),
        createdAt: createdAt,
        colorValue: clearColor ? null : (colorValue ?? this.colorValue),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
        'colorValue': colorValue,
      };

  factory LibraryFolder.fromJson(Map<String, dynamic> j) => LibraryFolder(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Folder',
        parentId: j['parentId'] as String?,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        colorValue: (j['colorValue'] as num?)?.toInt(),
      );
}
