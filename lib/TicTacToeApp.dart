import 'package:flutter/material.dart';

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic-Tac-Toe',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TicTacToeScreen(),
    );
  }
}

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({Key? key}) : super(key: key);

  @override
  _TicTacToeScreenState createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  // Represents the game board: 'X', 'O', or '' for empty
  late List<String> _board;
  // True if it's Player O's turn, false if it's Player X's turn
  late bool _isTurnO;
  // The winner of the game, or '' if no winner yet, or 'Draw' for a tie
  late String _winner;
  // Counter for the number of moves made
  late int _moveCount;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  // Initializes the game state
  void _initializeGame() {
    setState(() {
      _board = List.filled(9, ''); // All 9 squares are empty
      _isTurnO = false; // X goes first
      _winner = ''; // No winner yet
      _moveCount = 0; // No moves made yet
    });
  }

  // Handles a tap on a board square
  void _onSquareTap(int index) {
    // Only allow a move if the square is empty and there's no winner yet
    if (_board[index] == '' && _winner == '') {
      setState(() {
        _board[index] = _isTurnO ? 'O' : 'X'; // Place 'O' or 'X'
        _isTurnO = !_isTurnO; // Switch turns
        _moveCount++; // Increment move count
      });
      _checkWinner(); // Check if there's a winner after the move
    }
  }

  // Checks for a winner or a draw
  void _checkWinner() {
    // Winning combinations (rows, columns, diagonals)
    List<List<int>> winConditions = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6] // Diagonals
    ];

    for (var condition in winConditions) {
      if (_board[condition[0]] != '' &&
          _board[condition[0]] == _board[condition[1]] &&
          _board[condition[0]] == _board[condition[2]]) {
        setState(() {
          _winner = _board[condition[0]]; // Set the winner
        });
        _showGameEndDialog(); // Show dialog for winner
        return; // Exit after finding a winner
      }
    }

    // Check for a draw if all squares are filled and no winner
    if (_moveCount == 9 && _winner == '') {
      setState(() {
        _winner = 'Draw'; // Set draw
      });
      _showGameEndDialog(); // Show dialog for draw
    }
  }

  // Shows a dialog at the end of the game (win or draw)
  void _showGameEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (context) {
        return AlertDialog(
          title: Text(_winner == 'Draw' ? 'Game Over: It\'s a Draw!' : 'Player $_winner Wins!'),
          content: Text(_winner == 'Draw' ? 'No more moves left.' : 'Congratulations to Player $_winner!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _initializeGame(); // Reset the game
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _winner == ''
                    ? (_isTurnO ? 'Turn: Player O' : 'Turn: Player X')
                    : (_winner == 'Draw' ? 'Game Over: Draw!' : 'Winner: Player $_winner!'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            // The Tic-Tac-Toe board
            SizedBox(
              width: 300, // Fixed width for the board
              height: 300, // Fixed height for the board
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 columns
                  crossAxisSpacing: 10, // Spacing between columns
                  mainAxisSpacing: 10, // Spacing between rows
                ),
                itemCount: 9, // 9 squares
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onSquareTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueGrey, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _board[index],
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: _board[index] == 'X' ? Colors.red : Colors.green[800],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _initializeGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                shadowColor: Colors.blueGrey.shade800,
              ),
              child: const Text(
                'Reset Game',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}