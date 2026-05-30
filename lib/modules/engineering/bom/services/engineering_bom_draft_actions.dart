import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';

void addStructureBomLine(List<BomLineDraft> lines) {
  lines.add(BomLineDraft());
}

void removeStructureBomLine(List<BomLineDraft> lines, int index) {
  if (lines.length == 1) return;
  lines.removeAt(index).dispose();
}

void addFastenerBomLine(List<FastenerBomLineDraft> fasteners) {
  fasteners.add(FastenerBomLineDraft());
}

void removeFastenerBomLine(List<FastenerBomLineDraft> fasteners, int index) {
  if (fasteners.length == 1) return;
  fasteners.removeAt(index).dispose();
}

void disposeStructureBomLines(List<BomLineDraft> lines) {
  for (final line in lines) {
    line.dispose();
  }
}

void disposeFastenerBomLines(List<FastenerBomLineDraft> fasteners) {
  for (final fastener in fasteners) {
    fastener.dispose();
  }
}
