// models/chord_model.dart
//
// Mirrors the dictionaries app's chord data model so the bundled
// restructured_chordlibrary.json parses identically. A chord has a [root]
// (e.g. "C", "Csharp"), a [tonality] (e.g. "Major", "m7"), and a list of
// [variations] — each a playable shape.

class ChordModel {
  final String root;
  final String tonality;
  final List<ChordVariation> variations;

  ChordModel({
    required this.root,
    required this.tonality,
    required this.variations,
  });

  factory ChordModel.fromMap(Map<String, dynamic> json) {
    return ChordModel(
      root: json['root'] as String,
      tonality: json['tonality'] as String,
      variations: (json['variations'] as List)
          .map((v) => ChordVariation.fromMap(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChordVariation {
  /// Comma-separated fret positions for strings 6→1 (low-E → high-e), where a
  /// number is a fretted/open position and "x" is a muted string.
  final String positions;

  /// Optional fingering hint (unused by the trainer, kept for parity).
  final String fingering;

  ChordVariation({this.positions = '', this.fingering = ''});

  factory ChordVariation.fromMap(Map<String, dynamic> json) {
    return ChordVariation(
      positions: json['p'] as String? ?? '',
      fingering: json['f'] as String? ?? '',
    );
  }
}
