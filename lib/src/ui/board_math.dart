import 'package:flame/components.dart';

const int kTrackLen = 64;
const int kSide = 16;

int immuneIndexForPlayer(int p) => p * kSide;
int goalEntranceForPlayer(int p) => (immuneIndexForPlayer(p) - 1) % kTrackLen;

List<Vector2> buildTrackPositions(Vector2 topLeft, double size) {
  final pts = <Vector2>[];
  final step = size / (kSide - 1);
  final left = topLeft.x;
  final top = topLeft.y;
  final right = left + size;
  final bottom = top + size;

  for (int i = 0; i < kSide; i++) pts.add(Vector2(left + step * i, top));
  for (int i = 1; i < kSide; i++) pts.add(Vector2(right, top + step * i));
  for (int i = 1; i < kSide; i++) pts.add(Vector2(right - step * i, bottom));
  for (int i = 1; i < kSide - 1; i++) pts.add(Vector2(left, bottom - step * i));

  return pts;
}

List<Vector2> nestSlots(Vector2 tl, double size, int p) {
  const gap = 26.0;
  final pad = 44.0;
  late Vector2 a;

  switch (p) {
    case 0:
      a = tl + Vector2(pad, pad);
      break;
    case 1:
      a = tl + Vector2(size - pad - gap, pad);
      break;
    case 2:
      a = tl + Vector2(size - pad - gap, size - pad - gap);
      break;
    default:
      a = tl + Vector2(pad, size - pad - gap);
  }

  return [a, a + Vector2(gap, 0), a + Vector2(0, gap), a + Vector2(gap, gap)];
}

List<Vector2> goalSlots(Vector2 tl, double size, int p) {
  final c = tl + Vector2(size / 2, size / 2);
  const step = 24.0;
  const offset = 70.0;

  switch (p) {
    case 0:
      return List.generate(4, (i) => Vector2(c.x, tl.y + offset + i * step));
    case 1:
      return List.generate(4, (i) => Vector2(tl.x + size - offset - i * step, c.y));
    case 2:
      return List.generate(4, (i) => Vector2(c.x, tl.y + size - offset - i * step));
    default:
      return List.generate(4, (i) => Vector2(tl.x + offset + i * step, c.y));
  }
}
