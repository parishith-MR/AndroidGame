
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'MemoryGameApp.dart';
import 'SpaceDefenderApp.dart';
import 'TicTacToeApp.dart';
import 'TwoCarsRacingApp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gravity Ball Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class Ball {
  double x;
  double y;
  double velocityX;
  double velocityY;
  final Color color;
  final double radius;

  Ball({
    required this.x,
    required this.y,
    this.velocityX = 0,
    this.velocityY = 0,
    required this.color,
    this.radius = 20,
  });
}

class Hole {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final String label;
  final VoidCallback onEnter;
  bool isActive;

  Hole({
    required this.x,
    required this.y,
    this.radius = 40,
    required this.color,
    required this.label,
    required this.onEnter,
    this.isActive = true,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Ball ball;
  late List<Hole> holes;
  double gravityX = 0;
  double gravityY = 0;
  final double friction = 0.98;
  final double bounce = 0.7;
  Size screenSize = Size.zero;
  bool gameCompleted = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..repeat();

    _animationController.addListener(() {
      updatePhysics();
    });

    accelerometerEvents.listen((event) {
      setState(() {
        // INVERTED GRAVITY - tilt right to go left, tilt forward to go back
        gravityX = (-event.x * 2).clamp(-8, 8);  // Inverted X
        gravityY = (event.y * 2).clamp(-8, 8);   // Inverted Y
      });
    });

    // Initialize ball and holes after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeBallAndHoles();
    });
  }

  void initializeBallAndHoles() {
    if (screenSize == Size.zero) return;

    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    // Single ball starting in the center
    ball = Ball(
      x: centerX,
      y: centerY,
      color: Colors.white,
    );

// Responsive hole positioning based on screen size
    holes = [
      // Top-left hole - Memory Game (Red)
      Hole(
        x: screenSize.width * 0.2,  // 20% from left edge
        y: screenSize.height * 0.25, // 25% from top
        color: Colors.red.withOpacity(0.8),
        label: "Memory Game",
        onEnter: () => navigate(context, const MemoryGameApp()),
      ),

      // Top-right hole - TicTacToe (Green)
      Hole(
        x: screenSize.width * 0.8,  // 80% from left edge (20% from right)
        y: screenSize.height * 0.25, // 25% from top
        color: Colors.green.withOpacity(0.8),
        label: "TicTacToe",
        onEnter: () => navigate(context, const TicTacToeApp()),
      ),

      // Bottom-left hole - Two Cars (Blue)
      Hole(
        x: screenSize.width * 0.2,  // 20% from left edge
        y: screenSize.height * 0.75, // 75% from top (25% from bottom)
        color: Colors.blue.withOpacity(0.8),
        label: "Two Cars",
        onEnter: () => navigate(context, const TwoCarsRacingApp()),
      ),

      // Bottom-right hole - Space Shoot (Purple)
      Hole(
        x: screenSize.width * 0.8,  // 80% from left edge (20% from right)
        y: screenSize.height * 0.75, // 75% from top (25% from bottom)
        color: Colors.purple.withOpacity(0.8),
        label: "Space Shoot",
        onEnter: () => navigate(context, const SpaceDefenderApp()),
      ),
    ];

// Alternative positioning with safe areas for different screen ratios:

// For phones (taller screens):
    if (screenSize.height / screenSize.width > 1.5) {
      holes = [
        // Top-left hole - Memory Game (Red)
        Hole(
          x: screenSize.width * 0.15,
          y: screenSize.height * 0.2,
          color: Colors.red.withOpacity(0.8),
          label: "Memory Game",
          onEnter: () => navigate(context, const MemoryGameApp()),
        ),

        // Top-right hole - TicTacToe (Green)
        Hole(
          x: screenSize.width * 0.85,
          y: screenSize.height * 0.2,
          color: Colors.green.withOpacity(0.8),
          label: "TicTacToe",
          onEnter: () => navigate(context, const TicTacToeApp()),
        ),

        // Bottom-left hole - Two Cars (Blue)
        Hole(
          x: screenSize.width * 0.15,
          y: screenSize.height * 0.8,
          color: Colors.blue.withOpacity(0.8),
          label: "Two Cars",
          onEnter: () => navigate(context, const TwoCarsRacingApp()),
        ),

        // Bottom-right hole - Space Shoot (Purple)
        Hole(
          x: screenSize.width * 0.85,
          y: screenSize.height * 0.8,
          color: Colors.purple.withOpacity(0.8),
          label: "Space Shoot",
          onEnter: () => navigate(context, const SpaceDefenderApp()),
        ),
      ];
    }

// For tablets (wider screens):
    else if (screenSize.height / screenSize.width < 1.3) {
      holes = [
        // Top-left hole - Memory Game (Red)
        Hole(
          x: screenSize.width * 0.25,
          y: screenSize.height * 0.3,
          color: Colors.red.withOpacity(0.8),
          label: "Memory Game",
          onEnter: () => navigate(context, const MemoryGameApp()),
        ),

        // Top-right hole - TicTacToe (Green)
        Hole(
          x: screenSize.width * 0.75,
          y: screenSize.height * 0.3,
          color: Colors.green.withOpacity(0.8),
          label: "TicTacToe",
          onEnter: () => navigate(context, const TicTacToeApp()),
        ),

        // Bottom-left hole - Two Cars (Blue)
        Hole(
          x: screenSize.width * 0.25,
          y: screenSize.height * 0.7,
          color: Colors.blue.withOpacity(0.8),
          label: "Two Cars",
          onEnter: () => navigate(context, const TwoCarsRacingApp()),
        ),

        // Bottom-right hole - Space Shoot (Purple)
        Hole(
          x: screenSize.width * 0.75,
          y: screenSize.height * 0.7,
          color: Colors.purple.withOpacity(0.8),
          label: "Space Shoot",
          onEnter: () => navigate(context, const SpaceDefenderApp()),
        ),
      ];
    }

// Advanced positioning with minimum distances and safe zones:

    void createResponsiveHoles() {
      final double minDistance = 100; // Minimum distance from edges
      final double holeRadius = 30;   // Hole radius for calculations

      // Calculate safe positions
      final double leftX = max(minDistance, screenSize.width * 0.2);
      final double rightX = min(screenSize.width - minDistance, screenSize.width * 0.8);
      final double topY = max(minDistance + 100, screenSize.height * 0.25); // +100 for title
      final double bottomY = min(screenSize.height - minDistance - 100, screenSize.height * 0.75); // -100 for reset button

      holes = [
        // Top-left hole - Memory Game (Red)
        Hole(
          x: leftX,
          y: topY,
          radius: holeRadius,
          color: Colors.red.withOpacity(0.8),
          label: "Memory Game",
          onEnter: () => navigate(context, const MemoryGameApp()),
        ),

        // Top-right hole - TicTacToe (Green)
        Hole(
          x: rightX,
          y: topY,
          radius: holeRadius,
          color: Colors.green.withOpacity(0.8),
          label: "TicTacToe",
          onEnter: () => navigate(context, const TicTacToeApp()),
        ),

        // Bottom-left hole - Two Cars (Blue)
        Hole(
          x: leftX,
          y: bottomY,
          radius: holeRadius,
          color: Colors.blue.withOpacity(0.8),
          label: "Two Cars",
          onEnter: () => navigate(context, const TwoCarsRacingApp()),
        ),

        // Bottom-right hole - Space Shoot (Purple)
        Hole(
          x: rightX,
          y: bottomY,
          radius: holeRadius,
          color: Colors.purple.withOpacity(0.8),
          label: "Space Shoot",
          onEnter: () => navigate(context, const SpaceDefenderApp()),
        ),
      ];
    }

// Ultra-responsive positioning that works on all devices:

    void createUltraResponsiveHoles() {
      // Get usable screen area (excluding system UI)
      final double usableWidth = screenSize.width;
      final double usableHeight = screenSize.height;

      // Define margins based on screen size
      final double horizontalMargin = usableWidth * 0.15; // 15% margin
      final double verticalMargin = usableHeight * 0.15;  // 15% margin
      final double topOffset = 120; // Space for title
      final double bottomOffset = 120; // Space for reset button

      // Calculate positions
      final double leftX = horizontalMargin;
      final double rightX = usableWidth - horizontalMargin;
      final double topY = verticalMargin + topOffset;
      final double bottomY = usableHeight - verticalMargin - bottomOffset;

      // Adjust for very small screens
      final double adjustedTopY = max(topY, 150);
      final double adjustedBottomY = min(bottomY, usableHeight - 150);

      holes = [
        Hole(
          x: leftX,
          y: adjustedTopY,
          color: Colors.red.withOpacity(0.8),
          label: "Memory Game",
          onEnter: () => navigate(context, const MemoryGameApp()),
        ),
        Hole(
          x: rightX,
          y: adjustedTopY,
          color: Colors.green.withOpacity(0.8),
          label: "TicTacToe",
          onEnter: () => navigate(context, const TicTacToeApp()),
        ),
        Hole(
          x: leftX,
          y: adjustedBottomY,
          color: Colors.blue.withOpacity(0.8),
          label: "Two Cars",
          onEnter: () => navigate(context, const TwoCarsRacingApp()),
        ),
        Hole(
          x: rightX,
          y: adjustedBottomY,
          color: Colors.purple.withOpacity(0.8),
          label: "Space Shoot",
          onEnter: () => navigate(context, const SpaceDefenderApp()),
        ),
      ];
    }
  }

  void updatePhysics() {
    if (screenSize == Size.zero || gameCompleted) return;

    setState(() {
      // Apply gravity to the ball
      ball.velocityX += gravityX * 0.1;
      ball.velocityY += gravityY * 0.1;

      // Apply friction
      ball.velocityX *= friction;
      ball.velocityY *= friction;

      // Update position
      ball.x += ball.velocityX;
      ball.y += ball.velocityY;

      // Boundary collision with bounce
      if (ball.x - ball.radius < 0) {
        ball.x = ball.radius;
        ball.velocityX *= -bounce;
      } else if (ball.x + ball.radius > screenSize.width) {
        ball.x = screenSize.width - ball.radius;
        ball.velocityX *= -bounce;
      }

      if (ball.y - ball.radius < 0) {
        ball.y = ball.radius;
        ball.velocityY *= -bounce;
      } else if (ball.y + ball.radius > screenSize.height) {
        ball.y = screenSize.height - ball.radius;
        ball.velocityY *= -bounce;
      }

      // Check collision with holes
      for (var hole in holes) {
        if (!hole.isActive) continue;

        final distance = sqrt(
            pow(ball.x - hole.x, 2) + pow(ball.y - hole.y, 2)
        );

        if (distance < hole.radius - 10) {
          // Ball entered hole
          gameCompleted = true;
          hole.isActive = false;

          // Show success feedback and navigate
          _showSuccessMessage(hole.label);

          Future.delayed(const Duration(milliseconds: 1500), () {
            hole.onEnter();
          });
          break;
        }
      }
    });
  }

  void _showSuccessMessage(String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Great! Navigating to $pageName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void resetGame() {
    setState(() {
      gameCompleted = false;
      for (var hole in holes) {
        hole.isActive = true;
      }
      initializeBallAndHoles();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF24243e),
              Color(0xFF302B63),
              Color(0xFF0F0C29),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            if (ball == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                initializeBallAndHoles();
              });
            }

            return Stack(
              children: [
                // Background pattern
                CustomPaint(
                  size: screenSize,
                  painter: BackgroundPatternPainter(),
                ),

                // Title
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        'Gravity Ball Challenge',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tilt your device to guide the ball into a hole',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gameCompleted ? 'SUCCESS! 🎉' : 'stop only when it is complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: gameCompleted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Render holes
                ...holes.map((hole) => Positioned(
                  left: hole.x - hole.radius,
                  top: hole.y - hole.radius,
                  child: AnimatedOpacity(
                    opacity: hole.isActive ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: hole.radius * 2,
                      height: hole.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          colors: [
                            Colors.black87,
                            hole.color,
                            hole.color.withOpacity(0.3),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: hole.color.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          hole.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )),

                // Render ball
                if (ball != null)
                  Positioned(
                    left: ball.x - ball.radius,
                    top: ball.y - ball.radius,
                    child: AnimatedContainer(
                      duration: gameCompleted
                          ? const Duration(milliseconds: 500)
                          : Duration.zero,
                      width: ball.radius * 2,
                      height: ball.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          colors: [
                            Colors.white,
                            ball.color,
                            ball.color.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: gameCompleted ? 20 : 12,
                            spreadRadius: gameCompleted ? 4 : 2,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Reset button
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: resetGame,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Reset Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 8,
                      ),
                    ),
                  ),
                ),

                // Gravity indicator
                Positioned(
                  top: 120,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Gravity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'X: ${gravityX.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          'Y: ${gravityY.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}