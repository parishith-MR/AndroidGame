import 'dart:async';
import 'package:flutter/material.dart';


class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MemoryGameScreen(),
    );
  }
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({Key? key}) : super(key: key);

  @override
  _MemoryGameScreenState createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  // A list of all available icons for the game cards
  final List<IconData> _icons = [
    Icons.star,
    Icons.favorite,
    Icons.cloud,
    Icons.ac_unit,
    Icons.audiotrack,
    Icons.access_alarm,
    Icons.add_photo_alternate,
    Icons.airport_shuttle,
  ];

  // The game board, a list of cards with their values
  late List<Map<String, dynamic>> _gameCards;

  // A list of the indexes of the currently selected cards
  List<int> _selectedCardIndexes = [];

  // A list of the indexes of the cards that have been matched
  List<int> _matchedCardIndexes = [];

  // A boolean to prevent multiple selections while waiting for cards to flip back
  bool _isWaiting = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  // Initializes and shuffles the game cards
  void _initializeGame() {
    _gameCards = [];
    for (var i = 0; i < _icons.length; i++) {
      _gameCards.add({
        'value': _icons[i],
        'isFlipped': false,
      });
      _gameCards.add({
        'value': _icons[i],
        'isFlipped': false,
      });
    }
    _gameCards.shuffle();
    _selectedCardIndexes = [];
    _matchedCardIndexes = [];
    _isWaiting = false;
  }

  // Handles the logic when a card is tapped
  void _onCardTap(int index) {
    // If we are waiting or the card is already matched or flipped, do nothing
    if (_isWaiting || _matchedCardIndexes.contains(index) || _selectedCardIndexes.contains(index)) {
      return;
    }

    // Flip the card
    setState(() {
      _gameCards[index]['isFlipped'] = true;
      _selectedCardIndexes.add(index);
    });

    // Check if two cards are selected
    if (_selectedCardIndexes.length == 2) {
      _isWaiting = true;
      Timer(const Duration(milliseconds: 700), () {
        // Get the values of the two selected cards
        final card1Value = _gameCards[_selectedCardIndexes[0]]['value'];
        final card2Value = _gameCards[_selectedCardIndexes[1]]['value'];

        // If the cards match, add them to the matched list
        if (card1Value == card2Value) {
          setState(() {
            _matchedCardIndexes.addAll(_selectedCardIndexes);
          });
        } else {
          // If they don't match, flip them back
          setState(() {
            _gameCards[_selectedCardIndexes[0]]['isFlipped'] = false;
            _gameCards[_selectedCardIndexes[1]]['isFlipped'] = false;
          });
        }

        // Clear the selected cards and reset the waiting state
        _selectedCardIndexes.clear();
        _isWaiting = false;

        // Check for game completion
        if (_matchedCardIndexes.length == _gameCards.length) {
          _showWinDialog();
        }
      });
    }
  }

  // Displays a dialog when the game is won
  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('You Won!'),
          content: const Text('Congratulations, you matched all the cards!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _initializeGame();
                });
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
        title: const Text('Memory Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _gameCards.length,
          itemBuilder: (context, index) {
            final isFlipped = _gameCards[index]['isFlipped'] as bool;
            final isMatched = _matchedCardIndexes.contains(index);

            return InkWell(
              onTap: () => _onCardTap(index),
              child: Card(
                color: isMatched ? Colors.grey : Colors.blue,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: isFlipped
                        ? Icon(
                      _gameCards[index]['value'] as IconData,
                      key: ValueKey<int>(index),
                      size: 40,
                      color: Colors.white,
                    )
                        : const Icon(
                      Icons.question_mark,
                      key: ValueKey<int>(-1),
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}