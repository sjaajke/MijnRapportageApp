class SteekproefItem {
  final int? id;
  final int inspectionId;
  final String beschrijving;
  final int omvangPartij;
  final int steekproef;
  final int g;
  final int f;

  const SteekproefItem({
    this.id,
    required this.inspectionId,
    this.beschrijving = '',
    required this.omvangPartij,
    required this.steekproef,
    required this.g,
    required this.f,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inspection_id': inspectionId,
        'beschrijving': beschrijving,
        'omvang_partij': omvangPartij,
        'steekproef': steekproef,
        'g': g,
        'f': f,
      };

  factory SteekproefItem.fromMap(Map<String, dynamic> m) => SteekproefItem(
        id: m['id'] as int?,
        inspectionId: m['inspection_id'] as int,
        beschrijving: m['beschrijving'] as String? ?? '',
        omvangPartij: m['omvang_partij'] as int,
        steekproef: m['steekproef'] as int,
        g: m['g'] as int,
        f: m['f'] as int,
      );

  SteekproefItem copyWith({
    int? id,
    int? inspectionId,
    String? beschrijving,
    int? omvangPartij,
    int? steekproef,
    int? g,
    int? f,
  }) =>
      SteekproefItem(
        id: id ?? this.id,
        inspectionId: inspectionId ?? this.inspectionId,
        beschrijving: beschrijving ?? this.beschrijving,
        omvangPartij: omvangPartij ?? this.omvangPartij,
        steekproef: steekproef ?? this.steekproef,
        g: g ?? this.g,
        f: f ?? this.f,
      );
}
