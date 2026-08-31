class SessionScanAssets {
  final String? folderPath;

  final String? archLeftPath;
  final String? archRightPath;

  final String? archSectionLeftPath;
  final String? archSectionRightPath;

  final String? foot2dLeftPath;
  final String? foot2dRightPath;

  final String? pronatorLeftPath;
  final String? pronatorRightPath;

  final String? stlLeftPath;
  final String? stlRightPath;

  const SessionScanAssets({
    this.folderPath,
    this.archLeftPath,
    this.archRightPath,
    this.archSectionLeftPath,
    this.archSectionRightPath,
    this.foot2dLeftPath,
    this.foot2dRightPath,
    this.pronatorLeftPath,
    this.pronatorRightPath,
    this.stlLeftPath,
    this.stlRightPath,
  });

  bool get hasAnyAsset =>
      archLeftPath != null ||
      archRightPath != null ||
      archSectionLeftPath != null ||
      archSectionRightPath != null ||
      foot2dLeftPath != null ||
      foot2dRightPath != null ||
      pronatorLeftPath != null ||
      pronatorRightPath != null ||
      stlLeftPath != null ||
      stlRightPath != null;

  int get detectedFileCount {
    final values = [
      archLeftPath,
      archRightPath,
      archSectionLeftPath,
      archSectionRightPath,
      foot2dLeftPath,
      foot2dRightPath,
      pronatorLeftPath,
      pronatorRightPath,
      stlLeftPath,
      stlRightPath,
    ];

    return values.where((e) => e != null && e.trim().isNotEmpty).length;
  }

  SessionScanAssets copyWith({
    String? folderPath,
    String? archLeftPath,
    String? archRightPath,
    String? archSectionLeftPath,
    String? archSectionRightPath,
    String? foot2dLeftPath,
    String? foot2dRightPath,
    String? pronatorLeftPath,
    String? pronatorRightPath,
    String? stlLeftPath,
    String? stlRightPath,
  }) {
    return SessionScanAssets(
      folderPath: folderPath ?? this.folderPath,
      archLeftPath: archLeftPath ?? this.archLeftPath,
      archRightPath: archRightPath ?? this.archRightPath,
      archSectionLeftPath: archSectionLeftPath ?? this.archSectionLeftPath,
      archSectionRightPath:
          archSectionRightPath ?? this.archSectionRightPath,
      foot2dLeftPath: foot2dLeftPath ?? this.foot2dLeftPath,
      foot2dRightPath: foot2dRightPath ?? this.foot2dRightPath,
      pronatorLeftPath: pronatorLeftPath ?? this.pronatorLeftPath,
      pronatorRightPath: pronatorRightPath ?? this.pronatorRightPath,
      stlLeftPath: stlLeftPath ?? this.stlLeftPath,
      stlRightPath: stlRightPath ?? this.stlRightPath,
    );
  }
}