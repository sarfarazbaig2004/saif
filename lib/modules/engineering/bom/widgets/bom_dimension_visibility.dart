class BomDimensionVisibility {
  final bool length;
  final bool width;
  final bool thickness;
  final bool od;
  final bool id;
  final bool height;

  const BomDimensionVisibility({
    this.length = true,
    this.width = false,
    this.thickness = false,
    this.od = false,
    this.id = false,
    this.height = false,
  });

  factory BomDimensionVisibility.forCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'plate':
      case 'roofing sheet':
        return const BomDimensionVisibility(width: true, thickness: true);
      case 'pipe':
        return const BomDimensionVisibility(od: true, thickness: true);
      case 'round bar':
      case 'roundbar':
        return const BomDimensionVisibility(od: true, thickness: true);
      case 'custom':
        return const BomDimensionVisibility(
          width: true,
          thickness: true,
          od: true,
          id: true,
          height: true,
        );
      default:
        return const BomDimensionVisibility();
    }
  }
}
