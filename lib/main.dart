import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TetrisApp());
}

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Tetris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const TetrisGame(),
    );
  }
}

const Map<String, List<Point<int>>> tetrominoShapes = {
  'I': [Point(-1, 0), Point(0, 0), Point(1, 0), Point(2, 0)],
  'O': [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)],
  'T': [Point(-1, 0), Point(0, 0), Point(1, 0), Point(0, 1)],
  'S': [Point(0, 0), Point(1, 0), Point(-1, 1), Point(0, 1)],
  'Z': [Point(-1, 0), Point(0, 0), Point(0, 1), Point(1, 1)],
  'J': [Point(-1, 0), Point(0, 0), Point(1, 0), Point(1, 1)],
  'L': [Point(-1, 0), Point(0, 0), Point(1, 0), Point(-1, 1)],
};

const Map<String, Color> tetrominoColors = {
  'I': Colors.cyan,
  'O': Colors.yellow,
  'T': Colors.purple,
  'S': Colors.green,
  'Z': Colors.red,
  'J': Colors.blue,
  'L': Colors.orange,
};

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const int rows = 20;
  static const int cols = 10;

  late List<List<Color?>> board;
  late String currentType;
  late List<Point<int>> currentBlocks;
  late Point<int> currentPos;

  Timer? gameTimer;
  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    startNewGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void startNewGame() {
    board = List.generate(rows, (_) => List.filled(cols, null));
    score = 0;
    isGameOver = false;
    isPaused = false;
    spawnPiece();
    startTimer();
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!isPaused && !isGameOver) {
        moveDown();
      }
    });
  }

  void spawnPiece() {
    final keys = tetrominoShapes.keys.toList();
    currentType = keys[Random().nextInt(keys.length)];
    currentBlocks = List.from(tetrominoShapes[currentType]!);
    currentPos = const Point(cols ~/ 2 - 1, 0);

    if (!isValidPosition(currentBlocks, currentPos)) {
      setState(() {
        isGameOver = true;
      });
      gameTimer?.cancel();
    }
  }

  bool isValidPosition(List<Point<int>> blocks, Point<int> pos) {
    for (final b in blocks) {
      final x = pos.x + b.x;
      final y = pos.y + b.y;
      if (x < 0 || x >= cols || y >= rows) return false;
      if (y >= 0 && board[y][x] != null) return false;
    }
    return true;
  }

  void moveLeft() {
    if (isGameOver || isPaused) return;
    final nextPos = Point(currentPos.x - 1, currentPos.y);
    if (isValidPosition(currentBlocks, nextPos)) {
      setState(() => currentPos = nextPos);
    }
  }

  void moveRight() {
    if (isGameOver || isPaused) return;
    final nextPos = Point(currentPos.x + 1, currentPos.y);
    if (isValidPosition(currentBlocks, nextPos)) {
      setState(() => currentPos = nextPos);
    }
  }

  void moveDown() {
    if (isGameOver || isPaused) return;
    final nextPos = Point(currentPos.x, currentPos.y + 1);
    if (isValidPosition(currentBlocks, nextPos)) {
      setState(() => currentPos = nextPos);
    } else {
      lockPiece();
      clearLines();
      setState(() => spawnPiece());
    }
  }

  void dropDown() {
    if (isGameOver || isPaused) return;
    while (isValidPosition(currentBlocks, Point(currentPos.x, currentPos.y + 1))) {
      currentPos = Point(currentPos.x, currentPos.y + 1);
    }
    moveDown();
  }

  void rotatePiece() {
    if (isGameOver || isPaused || currentType == 'O') return;
    final rotated = currentBlocks.map((p) => Point(-p.y, p.x)).toList();
    if (isValidPosition(rotated, currentPos)) {
      setState(() => currentBlocks = rotated);
    }
  }

  void lockPiece() {
    for (final b in currentBlocks) {
      final x = currentPos.x + b.x;
      final y = currentPos.y + b.y;
      if (y >= 0 && y < rows && x >= 0 && x < cols) {
        board[y][x] = tetrominoColors[currentType];
      }
    }
  }

  void clearLines() {
    int linesCleared = 0;
    for (int y = rows - 1; y >= 0; y--) {
      if (board[y].every((cell) => cell != null)) {
        board.removeAt(y);
        board.insert(0, List.filled(cols, null));
        linesCleared++;
        y++;
      }
    }
    if (linesCleared > 0) {
      score += linesCleared * 100 * linesCleared;
    }
  }

  Color? getCellColor(int x, int y) {
    for (final b in currentBlocks) {
      if (currentPos.x + b.x == x && currentPos.y + b.y == y) {
        return tetrominoColors[currentType];
      }
    }
    return board[y][x];
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) moveLeft();
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) moveRight();
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) moveDown();
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) rotatePiece();
          if (event.logicalKey == LogicalKeyboardKey.space) dropDown();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: Text('Счёт: $score'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: () => setState(() => isPaused = !isPaused),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => startNewGame()),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: cols / rows,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2),
                      color: Colors.black,
                    ),
                    child: Stack(
                      children: [
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                          ),
                          itemCount: rows * cols,
                          itemBuilder: (context, index) {
                            final x = index % cols;
                            final y = index ~/ cols;
                            final color = getCellColor(x, y);
                            return Container(
                              margin: const EdgeInsets.all(0.5),
                              decoration: BoxDecoration(
                                color: color ?? Colors.grey[900],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                        ),
                        if (isGameOver)
                          Container(
                            color: Colors.black87,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'ИГРА ОКОНЧЕНА',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => setState(() => startNewGame()),
                                    child: const Text('Играть снова'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlBtn(Icons.arrow_back, moveLeft),
                  _controlBtn(Icons.arrow_downward, moveDown),
                  _controlBtn(Icons.vertical_align_bottom, dropDown),
                  _controlBtn(Icons.rotate_right, rotatePiece),
                  _controlBtn(Icons.arrow_forward, moveRight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      child: Icon(icon, size: 28),
    );
  }
}
