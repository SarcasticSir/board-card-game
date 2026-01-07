import 'package:flame/components.dart';

/// The game track has 64 spots total.
/// There are 16 spots between each player's immune spot.
/// Therefore immune indices are: 0, 16, 32, 48.
const int kTrackLen = 64;
const int kStride = 16;

/// We want 64 perimeter points total.
/// For a square perimeter, total unique points = 4 * (sidePoints - 1).
/// So sidePoints must be 17 => 4 * 16 = 64.
const int kSidePoints = 17;

int immuneIndexForPlayer(int p) => p * kStride;
int goalEntranceForPlayer(int p) => (immuneIndexForPlayer(p) - 1) % kTrackLen;

List<Vector2> buildTrackPositions(Vector2 topLeft, double size) {
  final pts = <Vector2>[];
  final step = size / (kSidePoints - 1);

  final left = topLeft.x;
  final top = topLeft.y;
  final right = left + size;
  final bottom = top + size;

  // Top edge: 17 points (includes both corners)
  for (int i = 0; i < kSidePoints; i++) {
    pts.add(Vector2(left + step * i, top));
  }

  // Right edge: 16 points (exclude top-right corner, include bottom-right)
  for (int i = 1; i < kSidePoints; i++) {
    pts.add(Vector2(right, top + step * i));
  }

  // Bottom edge: 16 points (exclude bottom-right corner, include bottom-left)
  for (int i = 1; i < kSidePoints; i++) {
    pts.add(Vector2(right - step * i, bottom));
  }

  // Left edge: 15 points (exclude bottom-left and top-left corners)
  for (int i = 1; i < kSidePoints - 1; i++) {
    pts.add(Vector2(left, bottom - step * i));
  }

  // Safety: ensure we have exactly 64
  assert(pts.length == kTrackLen, 'Track must be $kTrackLen but was ${pts.length}');
  return pts;
}

List<Vector2> nestSlots(Vector2 tl, double size, int p) {
  const gap = 26.0;
  final pad = 52.0; // slightly more inward so it's visible

  late Vector2 a;

  switch (p) {
    case 0: // top-left
      a = tl + Vector2(pad, pad);
      break;
    case 1: // top-right
      a = tl + Vector2(size - pad - gap, pad);
      break;
    case 2: // bottom-right
      a = tl + Vector2(size - pad - gap, size - pad - gap);
      break;
    default: // bottom-left
      a = tl + Vector2(pad, size - pad - gap);
  }

  return [
    a,
    a + Vector2(gap, 0),
    a + Vector2(0, gap),
    a + Vector2(gap, gap),
  ];
}

List<Vector2> goalSlots(Vector2 tl, double size, int p) {
  final c = tl + Vector2(size / 2, size / 2);
  const step = 24.0;
  const offset = 76.0;

  switch (p) {
    case 0: // towards top
      return List.generate(4, (i) => Vector2(c.x, tl.y + offset + i * step));
    case 1: // towards right
      return List.generate(4, (i) => Vector2(tl.x + size - offset - i * step, c.y));
    case 2: // towards bottom
      return List.generate(4, (i) => Vector2(c.x, tl.y + size - offset - i * step));
    default: // towards left
      return List.generate(4, (i) => Vector2(tl.x + offset + i * step, c.y));
  }
}
