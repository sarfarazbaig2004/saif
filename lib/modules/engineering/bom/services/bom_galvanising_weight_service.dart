class BomGalvanisingWeightService {
  const BomGalvanisingWeightService._();

  static double percentFor({
    required String materialStatus,
    required String coatingSpec,
    required double thicknessMm,
  }) {
    final status = materialStatus.toLowerCase();
    final spec = coatingSpec.toLowerCase();

    if (status.contains('galvalume')) return 0;
    if (status.contains('black')) return 0;
    if (status.contains('gp')) return 0;
    if (status.contains('posmac')) return 0;

    if (status.contains('hdg') && spec.contains('80')) {
      if (thicknessMm <= 2) return 0.07;
      if (thicknessMm <= 3) return 0.06;
      if (thicknessMm <= 4) return 0.05;
      return 0.04;
    }

    if (status.contains('hdg') && spec.contains('100')) {
      return 0.07;
    }

    return 0;
  }

  static double finalWeight({
    required double baseWeight,
    required String materialStatus,
    required String coatingSpec,
    required double thicknessMm,
  }) {
    final percent = percentFor(
      materialStatus: materialStatus,
      coatingSpec: coatingSpec,
      thicknessMm: thicknessMm,
    );

    return baseWeight * (1 + percent);
  }
}