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
    final moves = ['U', "U'", 'D', "D'", 'R', "R'", 'L', "L'", 'F', "F'", 'B', "B'"];
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
          _rotX = _rotX.clamp(-1.2, 1.2);
        });
      },
      child: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3D Projected Rubik Cube
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateX(_rotX)
                  ..rotateY(_rotY),
                child: _build3dCube(),
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

  Widget _build3dCube() {
    const double size = 135.0;
    const double half = size / 2;

    return Stack(
      children: [
        // Front Face (Green)
        Transform(
          transform: Matrix4.translationValues(0.0, 0.0, half),
          alignment: Alignment.center,
          child: _buildFace(2, size),
        ),
        // Back Face (Blue)
        Transform(
          transform: Matrix4.translationValues(0.0, 0.0, -half)
            ..rotateY(pi),
          alignment: Alignment.center,
          child: _buildFace(3, size),
        ),
        // Right Face (Red)
        Transform(
          transform: Matrix4.translationValues(half, 0.0, 0.0)
            ..rotateY(pi / 2),
          alignment: Alignment.center,
          child: _buildFace(4, size),
        ),
        // Left Face (Orange)
        Transform(
          transform: Matrix4.translationValues(-half, 0.0, 0.0)
            ..rotateY(-pi / 2),
          alignment: Alignment.center,
          child: _buildFace(5, size),
        ),
        // Top Face (White)
        Transform(
          transform: Matrix4.translationValues(0.0, -half, 0.0)
            ..rotateX(pi / 2),
          alignment: Alignment.center,
          child: _buildFace(0, size),
        ),
        // Bottom Face (Yellow)
        Transform(
          transform: Matrix4.translationValues(0.0, half, 0.0)
            ..rotateX(-pi / 2),
          alignment: Alignment.center,
          child: _buildFace(1, size),
        ),
      ],
    );
  }

  Widget _buildFace(int faceIndex, double faceSize) {
    return Container(
      width: faceSize,
      height: faceSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.5,
          mainAxisSpacing: 2.5,
        ),
        itemBuilder: (context, idx) {
          final color = _faces[faceIndex][idx];
          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black54, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
