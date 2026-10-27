import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class RubikCubeWidget extends StatefulWidget {
  final VoidCallback? onMoveExecuted;
  final Function(String move)? onMoveName;

  const RubikCubeWidget({
    super.key,
    this.onMoveExecuted,
    this.onMoveName,
  });

  @override
  State<RubikCubeWidget> createState() => RubikCubeWidgetState();
}

class RubikCubeWidgetState extends State<RubikCubeWidget> with SingleTickerProviderStateMixin {
  // Spherical rotation angles for 360 degree drag
  double _rotX = -0.55;
  double _rotY = 0.65;

  late AnimationController _turnController;
  String _activeMove = '';

  // 6 faces: 0=Up(White), 1=Down(Yellow), 2=Front(Green), 3=Back(Blue), 4=Right(Red), 5=Left(Orange)
  late List<List<Color>> _faces;

  static const Color cWhite = Color(0xFFF8FAFC);
  static const Color cYellow = Color(0xFFFFD166);
  static const Color cGreen = Color(0xFF06D6A0);
  static const Color cBlue = Color(0xFF118AB2);
  static const Color cRed = Color(0xFFEF476F);
  static const Color cOrange = Color(0xFFF77F00);

  @override
  void initState() {
    super.initState();
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    resetCube();
  }

  @override
  void dispose() {
    _turnController.dispose();
    super.dispose();
  }

  void resetCube() {
    setState(() {
      _faces = [
        List.filled(9, cWhite),  // Up
        List.filled(9, cYellow), // Down
        List.filled(9, cGreen),  // Front
        List.filled(9, cBlue),   // Back
        List.filled(9, cRed),    // Right
        List.filled(9, cOrange), // Left
      ];
    });
  }

  bool isSolved() {
    for (int faceIdx = 0; faceIdx < 6; faceIdx++) {
      final base = _faces[faceIdx][0];
      for (int i = 1; i < 9; i++) {
        if (_faces[faceIdx][i] != base) return false;
      }
    }
    return true;
  }

  void scramble() {
    final rand = Random();
    final moves = ['U', "U'", 'D', "D'", 'R', "R'", 'L', "L'", 'F', "F'", 'B', "B'", 'M', "M'", 'E', "E'"];
    for (int i = 0; i < 20; i++) {
      _applyMoveLogic(moves[rand.nextInt(moves.length)]);
    }
    setState(() {});
  }

  void executeMove(String move, {bool animate = true}) {
    if (animate) {
      _activeMove = move;
      _turnController.forward(from: 0.0).then((_) {
        _applyMoveLogic(move);
        _turnController.reset();
        _activeMove = '';
        widget.onMoveExecuted?.call();
        widget.onMoveName?.call(move);
        setState(() {});
      });
    } else {
      _applyMoveLogic(move);
      widget.onMoveExecuted?.call();
      setState(() {});
    }
  }

  void _applyMoveLogic(String move) {
    switch (move) {
      // Hàng ngang trên (Top Layer)
      case 'U':
        _rotateFaceClockwise(0);
        _cycleEdges([2, 4, 3, 5], [0, 1, 2], [0, 1, 2], [0, 1, 2], [0, 1, 2]);
        break;
      case "U'":
        _rotateFaceCounterClockwise(0);
        _cycleEdges([5, 3, 4, 2], [0, 1, 2], [0, 1, 2], [0, 1, 2], [0, 1, 2]);
        break;

      // Hàng ngang giữa (Equator Layer)
      case 'E':
        _cycleEdges([2, 5, 3, 4], [3, 4, 5], [3, 4, 5], [3, 4, 5], [3, 4, 5]);
        break;
      case "E'":
        _cycleEdges([2, 4, 3, 5], [3, 4, 5], [3, 4, 5], [3, 4, 5], [3, 4, 5]);
        break;

      // Hàng ngang dưới (Bottom Layer)
      case 'D':
        _rotateFaceClockwise(1);
        _cycleEdges([2, 5, 3, 4], [6, 7, 8], [6, 7, 8], [6, 7, 8], [6, 7, 8]);
        break;
      case "D'":
        _rotateFaceCounterClockwise(1);
        _cycleEdges([4, 3, 5, 2], [6, 7, 8], [6, 7, 8], [6, 7, 8], [6, 7, 8]);
        break;

      // Cột dọc phải (Right Column)
      case 'R':
        _rotateFaceClockwise(4);
        _cycleEdges([0, 3, 1, 2], [2, 5, 8], [6, 3, 0], [2, 5, 8], [2, 5, 8]);
        break;
      case "R'":
        _rotateFaceCounterClockwise(4);
        _cycleEdges([2, 1, 3, 0], [2, 5, 8], [2, 5, 8], [6, 3, 0], [2, 5, 8]);
        break;

      // Cột dọc giữa (Middle Column)
      case 'M':
        _cycleEdges([0, 2, 1, 3], [1, 4, 7], [1, 4, 7], [1, 4, 7], [7, 4, 1]);
        break;
      case "M'":
        _cycleEdges([3, 1, 2, 0], [7, 4, 1], [1, 4, 7], [1, 4, 7], [1, 4, 7]);
        break;

      // Cột dọc trái (Left Column)
      case 'L':
        _rotateFaceClockwise(5);
        _cycleEdges([0, 2, 1, 3], [0, 3, 6], [0, 3, 6], [0, 3, 6], [8, 5, 2]);
        break;
      case "L'":
        _rotateFaceCounterClockwise(5);
        _cycleEdges([3, 1, 2, 0], [8, 5, 2], [0, 3, 6], [0, 3, 6], [0, 3, 6]);
        break;

      // Mặt trước (Front Face)
      case 'F':
        _rotateFaceClockwise(2);
        _cycleEdges([0, 4, 1, 5], [6, 7, 8], [0, 3, 6], [2, 1, 0], [8, 5, 2]);
        break;
      case "F'":
        _rotateFaceCounterClockwise(2);
        _cycleEdges([5, 1, 4, 0], [8, 5, 2], [2, 1, 0], [0, 3, 6], [6, 7, 8]);
        break;

      // Mặt sau (Back Face)
      case 'B':
        _rotateFaceClockwise(3);
        _cycleEdges([0, 5, 1, 4], [2, 1, 0], [0, 3, 6], [6, 7, 8], [8, 5, 2]);
        break;
      case "B'":
        _rotateFaceCounterClockwise(3);
        _cycleEdges([4, 1, 5, 0], [8, 5, 2], [6, 7, 8], [0, 3, 6], [2, 1, 0]);
        break;

      default:
        _rotateFaceClockwise(0);
        break;
    }
  }

  void _rotateFaceClockwise(int faceIdx) {
    final f = List<Color>.from(_faces[faceIdx]);
    _faces[faceIdx][0] = f[6];
    _faces[faceIdx][1] = f[3];
    _faces[faceIdx][2] = f[0];
    _faces[faceIdx][3] = f[7];
    _faces[faceIdx][4] = f[4];
    _faces[faceIdx][5] = f[1];
    _faces[faceIdx][6] = f[8];
    _faces[faceIdx][7] = f[5];
    _faces[faceIdx][8] = f[2];
  }

  void _rotateFaceCounterClockwise(int faceIdx) {
    final f = List<Color>.from(_faces[faceIdx]);
    _faces[faceIdx][0] = f[2];
    _faces[faceIdx][1] = f[5];
    _faces[faceIdx][2] = f[8];
    _faces[faceIdx][3] = f[1];
    _faces[faceIdx][4] = f[4];
    _faces[faceIdx][5] = f[7];
    _faces[faceIdx][6] = f[0];
    _faces[faceIdx][7] = f[3];
    _faces[faceIdx][8] = f[6];
  }

  void _cycleEdges(List<int> faces, List<int> p1, List<int> p2, List<int> p3, List<int> p4) {
    final c1 = [for (var i in p1) _faces[faces[0]][i]];
    final c2 = [for (var i in p2) _faces[faces[1]][i]];
    final c3 = [for (var i in p3) _faces[faces[2]][i]];
    final c4 = [for (var i in p4) _faces[faces[3]][i]];

    for (int i = 0; i < 3; i++) {
      _faces[faces[1]][p2[i]] = c1[i];
      _faces[faces[2]][p3[i]] = c2[i];
      _faces[faces[3]][p4[i]] = c3[i];
      _faces[faces[0]][p1[i]] = c4[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotY += details.delta.dx * 0.015;
          _rotX -= details.delta.dy * 0.015;
          _rotX = _rotX.clamp(-1.4, 1.4);
        });
      },
      child: Center(
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3D Solid Rubik Cube Custom Painter with full depth & zero gaps
              CustomPaint(
                size: const Size(260, 260),
                painter: _RubikCube3dPainter(
                  rotX: _rotX,
                  rotY: _rotY,
                  faces: _faces,
                ),
              ),

              // Active move indicator badge
              if (_activeMove.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: GoddyTheme.glowBox(
                      borderColor: GoddyTheme.neonCyan,
                      bgColor: GoddyTheme.bgDark.withValues(alpha: 0.9),
                      radius: 10,
                    ),
                    child: Text(
                      'XOAY: $_activeMove',
                      style: const TextStyle(
                        color: GoddyTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vector3d {
  final double x;
  final double y;
  final double z;

  const _Vector3d(this.x, this.y, this.z);

  _Vector3d operator +(_Vector3d other) => _Vector3d(x + other.x, y + other.y, z + other.z);
  _Vector3d operator -(_Vector3d other) => _Vector3d(x - other.x, y - other.y, z - other.z);
  _Vector3d operator *(double scalar) => _Vector3d(x * scalar, y * scalar, z * scalar);

  double dot(_Vector3d other) => x * other.x + y * other.y + z * other.z;

  _Vector3d rotateY(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return _Vector3d(x * cosA + z * sinA, y, -x * sinA + z * cosA);
  }

  _Vector3d rotateX(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return _Vector3d(x, y * cosA - z * sinA, y * sinA + z * cosA);
  }

  Offset project(Offset center, double fov) {
    final k = fov / (fov - z);
    return Offset(center.dx + x * k, center.dy + y * k);
  }
}

class _VisibleFaceData {
  final int faceIndex;
  final double centerZ;
  final double diffuse;

  _VisibleFaceData({
    required this.faceIndex,
    required this.centerZ,
    required this.diffuse,
  });
}

class _RubikCube3dPainter extends CustomPainter {
  final double rotX;
  final double rotY;
  final List<List<Color>> faces;

  static const double L = 68.0; // Half cube size (total width = 136)
  static const double fov = 420.0;
  static const _Vector3d lightDir = _Vector3d(-0.35, -0.65, 0.67);

  const _RubikCube3dPainter({
    required this.rotX,
    required this.rotY,
    required this.faces,
  });

  _Vector3d _transform(_Vector3d v) {
    return v.rotateY(rotY).rotateX(rotX);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 6 Faces geometric definition: (center, uAxis, vAxis, normal)
    final faceDefs = [
      // 0: Up (White, Y = -L)
      (_Vector3d(0, -L, 0), const _Vector3d(1, 0, 0), const _Vector3d(0, 0, 1), const _Vector3d(0, -1, 0)),
      // 1: Down (Yellow, Y = +L)
      (_Vector3d(0, L, 0), const _Vector3d(1, 0, 0), const _Vector3d(0, 0, -1), const _Vector3d(0, 1, 0)),
      // 2: Front (Green, Z = +L)
      (_Vector3d(0, 0, L), const _Vector3d(1, 0, 0), const _Vector3d(0, 1, 0), const _Vector3d(0, 0, 1)),
      // 3: Back (Blue, Z = -L)
      (_Vector3d(0, 0, -L), const _Vector3d(-1, 0, 0), const _Vector3d(0, 1, 0), const _Vector3d(0, 0, -1)),
      // 4: Right (Red, X = +L)
      (_Vector3d(L, 0, 0), const _Vector3d(0, 0, -1), const _Vector3d(0, 1, 0), const _Vector3d(1, 0, 0)),
      // 5: Left (Orange, X = -L)
      (_Vector3d(-L, 0, 0), const _Vector3d(0, 0, 1), const _Vector3d(0, 1, 0), const _Vector3d(-1, 0, 0)),
    ];

    final visibleFaces = <_VisibleFaceData>[];

    for (int i = 0; i < 6; i++) {
      final normal = _transform(faceDefs[i].$4);
      // Back-face culling: face is visible when normal.z > 0 (facing the screen)
      if (normal.z > 0.001) {
        final faceCenter = _transform(faceDefs[i].$1);
        final diffuse = (normal.dot(lightDir)).clamp(0.0, 1.0);
        visibleFaces.add(_VisibleFaceData(
          faceIndex: i,
          centerZ: faceCenter.z,
          diffuse: diffuse,
        ));
      }
    }

    // Sort visible faces by Z-depth (Painters algorithm: furthest first)
    visibleFaces.sort((a, b) => a.centerZ.compareTo(b.centerZ));

    final blackBodyPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF020617)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final stickerBorderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerDotPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill;

    // Draw visible faces
    for (final vf in visibleFaces) {
      final fIdx = vf.faceIndex;
      final def = faceDefs[fIdx];
      final fCenter = def.$1;
      final uAxis = def.$2;
      final vAxis = def.$3;

      // 1. Draw solid black mechanical face plate (Zero gap)
      final cTL = _transform(fCenter - uAxis * L - vAxis * L).project(center, fov);
      final cTR = _transform(fCenter + uAxis * L - vAxis * L).project(center, fov);
      final cBR = _transform(fCenter + uAxis * L + vAxis * L).project(center, fov);
      final cBL = _transform(fCenter - uAxis * L + vAxis * L).project(center, fov);

      final facePath = Path()
        ..moveTo(cTL.dx, cTL.dy)
        ..lineTo(cTR.dx, cTR.dy)
        ..lineTo(cBR.dx, cBR.dy)
        ..lineTo(cBL.dx, cBL.dy)
        ..close();

      canvas.drawPath(facePath, blackBodyPaint);
      canvas.drawPath(facePath, borderPaint);

      // 2. Draw 9 stickers (row 0..2, col 0..2)
      const double step = (2 * L) / 3.0;
      const double pad = 2.2; // Spacing between stickers showing black frame

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final stickerIdx = row * 3 + col;
          final color = faces[fIdx][stickerIdx];

          final u0 = -L + col * step + pad;
          final u1 = -L + (col + 1) * step - pad;
          final v0 = -L + row * step + pad;
          final v1 = -L + (row + 1) * step - pad;

          final p0 = _transform(fCenter + uAxis * u0 + vAxis * v0).project(center, fov);
          final p1 = _transform(fCenter + uAxis * u1 + vAxis * v0).project(center, fov);
          final p2 = _transform(fCenter + uAxis * u1 + vAxis * v1).project(center, fov);
          final p3 = _transform(fCenter + uAxis * u0 + vAxis * v1).project(center, fov);

          final stickerPath = Path()
            ..moveTo(p0.dx, p0.dy)
            ..lineTo(p1.dx, p1.dy)
            ..lineTo(p2.dx, p2.dy)
            ..lineTo(p3.dx, p3.dy)
            ..close();

          // Lighting shading
          final brightness = 0.75 + 0.25 * vf.diffuse;
          final shadedColor = Color.fromARGB(
            color.a.toInt(),
            (color.r * 255 * brightness).clamp(0, 255).toInt(),
            (color.g * 255 * brightness).clamp(0, 255).toInt(),
            (color.b * 255 * brightness).clamp(0, 255).toInt(),
          );

          final fillPaint = Paint()
            ..color = shadedColor
            ..style = PaintingStyle.fill;

          canvas.drawPath(stickerPath, fillPaint);
          canvas.drawPath(stickerPath, stickerBorderPaint);

          // If this is the CENTER sticker (idx == 4):
          // Draw subtle emblem dot highlighting the center piece
          if (stickerIdx == 4) {
            final centerPoint = Offset(
              (p0.dx + p1.dx + p2.dx + p3.dx) / 4,
              (p0.dy + p1.dy + p2.dy + p3.dy) / 4,
            );
            canvas.drawCircle(centerPoint, 3.5, centerDotPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RubikCube3dPainter oldDelegate) {
    return oldDelegate.rotX != rotX || oldDelegate.rotY != rotY || oldDelegate.faces != faces;
  }
}
