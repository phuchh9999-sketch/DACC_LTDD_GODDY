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
  // Classic isometric camera viewing angle (showing Top, Left, Right faces)
  double _rotX = -0.55;
  double _rotY = 0.65;

  late AnimationController _turnController;
  String _activeMove = '';

  // 6 faces: 0=Up(White), 1=Down(Yellow), 2=Front(Green), 3=Back(Blue), 4=Right(Red), 5=Left(Orange)
  late List<List<Color>> _faces;

  // Official competition Rubik's WCA colors
  static const Color cWhite = Color(0xFFF8FAFC);  // White (Top/Up)
  static const Color cYellow = Color(0xFFFFD500); // Yellow (Down)
  static const Color cGreen = Color(0xFF009B48);  // Vivid Green (Front)
  static const Color cBlue = Color(0xFF0046AD);   // Royal Blue (Back)
  static const Color cRed = Color(0xFFB71234);    // Rubik Red (Right)
  static const Color cOrange = Color(0xFFFF5800); // Vivid Orange (Left)

  @override
  void initState() {
    super.initState();
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
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
        List.filled(9, cWhite),  // 0 Up
        List.filled(9, cYellow), // 1 Down
        List.filled(9, cGreen),  // 2 Front
        List.filled(9, cBlue),   // 3 Back
        List.filled(9, cRed),    // 4 Right
        List.filled(9, cOrange), // 5 Left
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
          _rotX = _rotX.clamp(-1.45, 1.45);
        });
      },
      child: Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ultra-Realistic 3D Solid Rubik Cube Canvas
              CustomPaint(
                size: const Size(280, 280),
                painter: _RealisticRubik3dPainter(
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

class _RealisticRubik3dPainter extends CustomPainter {
  final double rotX;
  final double rotY;
  final List<List<Color>> faces;

  static const double L = 72.0; // Half cube size (total cube width = 144px)
  static const double fov = 460.0;
  static const _Vector3d lightDir = _Vector3d(-0.4, -0.6, 0.69);

  const _RealisticRubik3dPainter({
    required this.rotX,
    required this.rotY,
    required this.faces,
  });

  _Vector3d _transform(_Vector3d v) {
    return v.rotateY(rotY).rotateX(rotX);
  }

  Path _buildRoundedQuad(List<Offset> pts, double r) {
    final path = Path();
    final p0In = Offset.lerp(pts[0], pts[3], r)!;
    final p0Out = Offset.lerp(pts[0], pts[1], r)!;
    final p1In = Offset.lerp(pts[1], pts[0], r)!;
    final p1Out = Offset.lerp(pts[1], pts[2], r)!;
    final p2In = Offset.lerp(pts[2], pts[1], r)!;
    final p2Out = Offset.lerp(pts[2], pts[3], r)!;
    final p3In = Offset.lerp(pts[3], pts[2], r)!;
    final p3Out = Offset.lerp(pts[3], pts[0], r)!;

    path.moveTo(p0Out.dx, p0Out.dy);
    path.lineTo(p1In.dx, p1In.dy);
    path.quadraticBezierTo(pts[1].dx, pts[1].dy, p1Out.dx, p1Out.dy);
    path.lineTo(p2In.dx, p2In.dy);
    path.quadraticBezierTo(pts[2].dx, pts[2].dy, p2Out.dx, p2Out.dy);
    path.lineTo(p3In.dx, p3In.dy);
    path.quadraticBezierTo(pts[3].dx, pts[3].dy, p3Out.dx, p3Out.dy);
    path.lineTo(p0In.dx, p0In.dy);
    path.quadraticBezierTo(pts[0].dx, pts[0].dy, p0Out.dx, p0Out.dy);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 8);

    // 1. Soft 3D ambient shadow on table surface beneath the cube
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.65),
          Colors.black.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(center.dx, center.dy + L * 1.55),
        width: L * 3.4,
        height: L * 0.9,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + L * 1.55),
        width: L * 3.4,
        height: L * 0.9,
      ),
      shadowPaint,
    );

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
      // Face is visible when normal.z > 0 (facing the screen)
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

    // Sort visible faces by Z-depth (furthest first)
    visibleFaces.sort((a, b) => a.centerZ.compareTo(b.centerZ));

    final blackBodyPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;

    final outerChamferPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final stickerBorderPaint = Paint()
      ..color = const Color(0xFF161B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Draw visible faces
    for (final vf in visibleFaces) {
      final fIdx = vf.faceIndex;
      final def = faceDefs[fIdx];
      final fCenter = def.$1;
      final uAxis = def.$2;
      final vAxis = def.$3;

      // 1. Solid Black Plastic Cube Chassis (Zero gap between faces)
      final cTL = _transform(fCenter - uAxis * L - vAxis * L).project(center, fov);
      final cTR = _transform(fCenter + uAxis * L - vAxis * L).project(center, fov);
      final cBR = _transform(fCenter + uAxis * L + vAxis * L).project(center, fov);
      final cBL = _transform(fCenter - uAxis * L + vAxis * L).project(center, fov);

      final faceBaseQuad = _buildRoundedQuad([cTL, cTR, cBR, cBL], 0.05);
      canvas.drawPath(faceBaseQuad, blackBodyPaint);
      canvas.drawPath(faceBaseQuad, outerChamferPaint);

      // 2. Draw 9 Rounded Chamfered Stickers (3x3 grid)
      const double step = (2 * L) / 3.0;
      const double pad = 3.2; // Deep black groove between cubelets

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

          // Build realistic rounded corner sticker polygon in 3D perspective
          final stickerPath = _buildRoundedQuad([p0, p1, p2, p3], 0.16);

          // Realistic 3D shading
          final brightness = 0.76 + 0.24 * vf.diffuse;
          final baseShaded = Color.fromARGB(
            color.a.toInt(),
            (color.r * 255 * brightness).clamp(0, 255).toInt(),
            (color.g * 255 * brightness).clamp(0, 255).toInt(),
            (color.b * 255 * brightness).clamp(0, 255).toInt(),
          );

          // Glossy Plastic / Specular Highlight (matching real physical Speedcube)
          final stickerRect = stickerPath.getBounds();
          final fillPaint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(baseShaded, Colors.white, 0.28)!,
                baseShaded,
                Color.lerp(baseShaded, Colors.black, 0.15)!,
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(stickerRect)
            ..style = PaintingStyle.fill;

          canvas.drawPath(stickerPath, fillPaint);
          canvas.drawPath(stickerPath, stickerBorderPaint);

          // 3. Branded Speedcube Emblem on White Center Sticker (Matching Reference Image 2)
          if (fIdx == 0 && stickerIdx == 4) {
            final centerPoint = Offset(
              (p0.dx + p1.dx + p2.dx + p3.dx) / 4,
              (p0.dy + p1.dy + p2.dy + p3.dy) / 4,
            );
            // Draw Rubik Logo Badge
            final badgePaint = Paint()
              ..color = const Color(0xFF1E293B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4;
            canvas.drawCircle(centerPoint, 8.0, Paint()..color = Colors.white.withValues(alpha: 0.9));
            canvas.drawCircle(centerPoint, 8.0, badgePaint);

            // Mini 3D Logo Cube
            final logoPaint = Paint()..style = PaintingStyle.fill;
            logoPaint.color = RubikCubeWidgetState.cRed;
            canvas.drawCircle(centerPoint + const Offset(-2, -2), 2.0, logoPaint);
            logoPaint.color = RubikCubeWidgetState.cGreen;
            canvas.drawCircle(centerPoint + const Offset(2, -2), 2.0, logoPaint);
            logoPaint.color = RubikCubeWidgetState.cBlue;
            canvas.drawCircle(centerPoint + const Offset(0, 2), 2.0, logoPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticRubik3dPainter oldDelegate) {
    return oldDelegate.rotX != rotX || oldDelegate.rotY != rotY || oldDelegate.faces != faces;
  }
}
