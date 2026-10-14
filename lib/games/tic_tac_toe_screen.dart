import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

const String _empty = ' ';
const String _human = 'X';
const String _ai = 'O';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> _board = List.filled(9, _empty);
  String _status = 'Your turn (X)';
  bool _gameOver = false;
  bool _humanTurn = true;
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;

  final Random _rng = Random();

  void _reset() {
    setState(() {
      _board = List.filled(9, _empty);
      _status = 'Your turn (X)';
      _gameOver = false;
      _humanTurn = true;
    });
  }

  /// Returns true and records the result if the game has ended.
  bool _finishIfOver() {
    final winner = _winnerOf(_board);
    if (winner == _human) {
      _status = 'You win! 🎉';
      _gameOver = true;
      _wins++;
      return true;
    }
    if (winner == _ai) {
      _status = 'Computer wins';
      _gameOver = true;
      _losses++;
      return true;
    }
    if (!_board.contains(_empty)) {
      _status = "It's a draw";
      _gameOver = true;
      _draws++;
      return true;
    }
    return false;
  }

  Future<void> _onCellTap(int index) async {
    if (_gameOver || !_humanTurn || _board[index] != _empty) return;

    setState(() {
      _board[index] = _human;
      _humanTurn = false;
    });

    if (_finishIfOver()) {
      setState(() {});
      return;
    }

    setState(() => _status = 'Computer thinking…');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final move = _bestAiMove(_board);
    setState(() {
      if (move >= 0) _board[move] = _ai;
      if (!_finishIfOver()) {
        _humanTurn = true;
        _status = 'Your turn (X)';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _topBar(context),
                _scoreBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Center(child: _boardView())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _gameOver ? 'Play Again' : 'Restart',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Tic-Tac-Toe',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreChip('Wins', _wins, AppColors.gold),
          _scoreChip('Draws', _draws, Colors.white),
          _scoreChip('Losses', _losses, AppColors.loss),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _boardView() {
    // Size the board to a square that fits the available space (so it never
    // overflows on short screens).
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return SizedBox(
          width: side,
          height: side,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(10),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < 9; i++) _cell(i),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cell(int index) {
    final value = _board[index];
    return GestureDetector(
      onTap: () => _onCellTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedScale(
            scale: value == _empty ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Text(
              value == _empty ? '' : value,
              style: TextStyle(
                color: value == _human ? AppColors.gold : Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Game logic ---------------------------------------------------------

  static const List<List<int>> _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
    [0, 4, 8], [2, 4, 6], // diagonals
  ];

  String _winnerOf(List<String> board) {
    for (final line in _winLines) {
      final a = board[line[0]];
      if (a != _empty && a == board[line[1]] && a == board[line[2]]) {
        return a;
      }
    }
    return _empty;
  }

  /// Simple but decent AI: win, else block, else center, corner, side.
  int _bestAiMove(List<String> board) {
    final win = _findWinningMove(board, _ai);
    if (win != null) return win;

    final block = _findWinningMove(board, _human);
    if (block != null) return block;

    if (board[4] == _empty) return 4;

    final corners = [0, 2, 6, 8].where((i) => board[i] == _empty).toList();
    if (corners.isNotEmpty) return corners[_rng.nextInt(corners.length)];

    final sides = [1, 3, 5, 7].where((i) => board[i] == _empty).toList();
    if (sides.isNotEmpty) return sides[_rng.nextInt(sides.length)];

    return board.indexOf(_empty);
  }

  int? _findWinningMove(List<String> board, String player) {
    for (int i = 0; i < board.length; i++) {
      if (board[i] == _empty) {
        final test = List<String>.from(board)..[i] = player;
        if (_winnerOf(test) == player) return i;
      }
    }
    return null;
  }
}
