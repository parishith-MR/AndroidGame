import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

class TwoCarsRacingApp extends StatelessWidget {
  const TwoCarsRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two Cars Racing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF415A77),
              Color(0xFF778DA9),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game Title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Text(
                '🏁 TWO CARS RACING 🏁',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Game Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'HOW TO PLAY',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInstruction('🔴 Red Car:', 'Tap LEFT side to avoid obstacles'),
                  _buildInstruction('🔵 Blue Car:', 'Tap RIGHT side to avoid obstacles'),
                  _buildInstruction('🎯 Goal:', 'Survive longer than your opponent!'),
                  _buildInstruction('⚠️ Warning:', 'Hit obstacle = GAME OVER!'),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // Start Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
              ),
              child: const Text(
                'START RACING!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Car {
  double x, y;
  double width, height;
  bool isInLeftLane;
  Color color;
  String name;
  bool isDestroyed;
  double speed;

  Car({
    required this.x,
    required this.y,
    required this.color,
    required this.name,
    this.width = 40,
    this.height = 60,
    this.isInLeftLane = true,
    this.isDestroyed = false,
    this.speed = 0,
  });

  void switchLane(double laneWidth) {
    if (!isDestroyed) {
      isInLeftLane = !isInLeftLane;
      x = isInLeftLane ? 30 : laneWidth - width - 30;
    }
  }

  bool collidesWith(Obstacle obstacle) {
    return x < obstacle.x + obstacle.width &&
        x + width > obstacle.x &&
        y < obstacle.y + obstacle.height &&
        y + height > obstacle.y;
  }
}

class Obstacle {
  double x, y;
  double width, height;
  double speed;
  Color color;
  bool isInLeftLane;

  Obstacle({
    required this.x,
    required this.y,
    required this.isInLeftLane,
    this.width = 35,
    this.height = 35,
    this.speed = 200,
    this.color = Colors.yellow,
  });

  void update(double deltaTime) {
    y += speed * deltaTime;
  }

  bool isOffScreen() => y > 900;
}

class RoadLine {
  double x, y;
  double height;
  double speed;

  RoadLine({required this.x, required this.y})
      : height = 30,
        speed = 300;

  void update(double deltaTime) {
    y += speed * deltaTime;
    if (y > 900) {
      y = -height;
    }
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _gameController;
  late AnimationController _countdownController;

  late Car redCar, blueCar;
  List<Obstacle> redLaneObstacles = [];
  List<Obstacle> blueLaneObstacles = [];
  List<RoadLine> roadLines = [];

  bool gameStarted = false;
  bool gameOver = false;
  String winner = '';
  int countdown = 3;
  double gameSpeed = 1.0;
  double obstacleSpawnTimer = 0;
  int score = 0;

  final Random random = Random();
  final double laneWidth = 200;

  @override
  void initState() {
    super.initState();
    initializeGame();
    startCountdown();
  }

  void initializeGame() {
    // Initialize cars
    redCar = Car(
      x: 30,
      y: 700,
      color: Colors.red,
      name: 'Red',
    );

    blueCar = Car(
      x: laneWidth + 30,
      y: 700,
      color: Colors.blue,
      name: 'Blue',
    );

    // Initialize road lines
    roadLines = [];
    for (int i = 0; i < 20; i++) {
      roadLines.add(RoadLine(
        x: laneWidth,
        y: i * 50.0,
      ));
    }

    // Reset game state
    redLaneObstacles.clear();
    blueLaneObstacles.clear();
    gameStarted = false;
    gameOver = false;
    winner = '';
    score = 0;
    gameSpeed = 1.0;
    obstacleSpawnTimer = 0;
  }

  void startCountdown() {
    _countdownController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        setState(() {
          gameStarted = true;
        });
        startGameLoop();
      }
    });
  }

  void startGameLoop() {
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );

    _gameController.addListener(gameLoop);
    _gameController.repeat();
  }

  void gameLoop() {
    if (!gameStarted || gameOver) return;

    const deltaTime = 0.016;

    // Increase game speed over time
    gameSpeed += 0.001;
    score += 1;

    // Update road lines
    for (var line in roadLines) {
      line.speed = 300 * gameSpeed;
      line.update(deltaTime);
    }

    // Spawn obstacles
    obstacleSpawnTimer += deltaTime;
    if (obstacleSpawnTimer > (1.5 / gameSpeed)) {
      spawnObstacles();
      obstacleSpawnTimer = 0;
    }

    // Update red lane obstacles
    redLaneObstacles.removeWhere((obstacle) {
      obstacle.speed = 200 * gameSpeed;
      obstacle.update(deltaTime);
      return obstacle.isOffScreen();
    });

    // Update blue lane obstacles
    blueLaneObstacles.removeWhere((obstacle) {
      obstacle.speed = 200 * gameSpeed;
      obstacle.update(deltaTime);
      return obstacle.isOffScreen();
    });

    // Check collisions
    checkCollisions();

    setState(() {});
  }

  void spawnObstacles() {
    // Randomly spawn obstacles in lanes (not both at the same height)
    bool spawnInRed = random.nextBool();
    bool spawnInBlue = random.nextBool();

    // Ensure at least one lane is safe
    if (spawnInRed && spawnInBlue) {
      if (random.nextBool()) {
        spawnInRed = false;
      } else {
        spawnInBlue = false;
      }
    }

    if (spawnInRed) {
      double x = redCar.isInLeftLane ? 30 : laneWidth - 65;
      redLaneObstacles.add(Obstacle(
        x: x,
        y: -50,
        isInLeftLane: redCar.isInLeftLane,
        color: Colors.orange,
      ));
    }

    if (spawnInBlue) {
      double x = blueCar.isInLeftLane ? laneWidth + 30 : laneWidth * 2 - 65;
      blueLaneObstacles.add(Obstacle(
        x: x,
        y: -50,
        isInLeftLane: blueCar.isInLeftLane,
        color: Colors.purple,
      ));
    }
  }

  void checkCollisions() {
    // Check red car collisions
    for (var obstacle in redLaneObstacles) {
      if (redCar.collidesWith(obstacle)) {
        gameOver = true;
        winner = 'Blue';
        HapticFeedback.heavyImpact();
        showGameOverDialog();
        return;
      }
    }

    // Check blue car collisions
    for (var obstacle in blueLaneObstacles) {
      if (blueCar.collidesWith(obstacle)) {
        gameOver = true;
        winner = 'Red';
        HapticFeedback.heavyImpact();
        showGameOverDialog();
        return;
      }
    }
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          '🏁 Game Over!',
          style: TextStyle(
            color: winner == 'Red' ? Colors.red : Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 $winner Car Wins! 🎉',
              style: TextStyle(
                color: winner == 'Red' ? Colors.red : Colors.blue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Final Score: $score',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Game Speed: ${gameSpeed.toStringAsFixed(1)}x',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to menu
            },
            child: const Text('Back to Menu', style: TextStyle(color: Colors.cyan)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              restartGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void restartGame() {
    _gameController.dispose();
    setState(() {
      initializeGame();
      countdown = 3;
    });
    startCountdown();
  }

  void handleLeftTap() {
    if (gameStarted && !gameOver) {
      redCar.switchLane(laneWidth);
      HapticFeedback.lightImpact();
    }
  }

  void handleRightTap() {
    if (gameStarted && !gameOver) {
      blueCar.switchLane(laneWidth * 2);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _gameController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F3460),
              Color(0xFF16213E),
              Color(0xFF0E4B99),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Game Area
            Row(
              children: [
                // Red Car Lane (Left)
                Expanded(
                  child: GestureDetector(
                    onTap: handleLeftTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800]?.withOpacity(0.3),
                        border: const Border(
                          right: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Red lane road lines
                          ...roadLines.take(10).map((line) => Positioned(
                            left: line.x - laneWidth,
                            top: line.y,
                            child: Container(
                              width: 4,
                              height: line.height,
                              color: Colors.white70,
                            ),
                          )),

                          // Red car
                          if (!redCar.isDestroyed)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              left: redCar.x,
                              top: redCar.y,
                              child: Container(
                                width: redCar.width,
                                height: redCar.height,
                                decoration: BoxDecoration(
                                  color: redCar.color,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: redCar.color.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.directions_car, color: Colors.white, size: 30),
                                ),
                              ),
                            ),

                          // Red lane obstacles
                          ...redLaneObstacles.map((obstacle) => Positioned(
                            left: obstacle.x,
                            top: obstacle.y,
                            child: Container(
                              width: obstacle.width,
                              height: obstacle.height,
                              decoration: BoxDecoration(
                                color: obstacle.color,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: obstacle.color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.warning, color: Colors.white, size: 20),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),

                // Blue Car Lane (Right)
                Expanded(
                  child: GestureDetector(
                    onTap: handleRightTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800]?.withOpacity(0.3),
                      ),
                      child: Stack(
                        children: [
                          // Blue lane road lines
                          ...roadLines.skip(10).map((line) => Positioned(
                            left: line.x - laneWidth,
                            top: line.y,
                            child: Container(
                              width: 4,
                              height: line.height,
                              color: Colors.white70,
                            ),
                          )),

                          // Blue car
                          if (!blueCar.isDestroyed)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              left: blueCar.x - laneWidth,
                              top: blueCar.y,
                              child: Container(
                                width: blueCar.width,
                                height: blueCar.height,
                                decoration: BoxDecoration(
                                  color: blueCar.color,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: blueCar.color.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.directions_car, color: Colors.white, size: 30),
                                ),
                              ),
                            ),

                          // Blue lane obstacles
                          ...blueLaneObstacles.map((obstacle) => Positioned(
                            left: obstacle.x - laneWidth,
                            top: obstacle.y,
                            child: Container(
                              width: obstacle.width,
                              height: obstacle.height,
                              decoration: BoxDecoration(
                                color: obstacle.color,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: obstacle.color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.warning, color: Colors.white, size: 20),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // UI Elements
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Red Car Info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🔴 RED CAR\nTap Left Side',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Score
                  if (gameStarted)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Score: $score',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            'Speed: ${gameSpeed.toStringAsFixed(1)}x',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  // Blue Car Info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🔵 BLUE CAR\nTap Right Side',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Countdown
            if (!gameStarted && countdown > 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countdown.toString(),
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Start message
            if (!gameStarted && countdown == 0)
              const Center(
                child: Text(
                  'GO!',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}