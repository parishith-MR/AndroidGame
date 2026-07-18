import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
class SpaceDefenderApp extends StatelessWidget {
  const SpaceDefenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Defender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const GameScreen(),
    );
  }
}

class GameObject {
  double x, y;
  double width, height;
  double velocityX, velocityY;
  bool isDestroyed;

  GameObject({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.velocityX = 0,
    this.velocityY = 0,
    this.isDestroyed = false,
  });

  bool collidesWith(GameObject other) {
    return x < other.x + other.width &&
        x + width > other.x &&
        y < other.y + other.height &&
        y + height > other.y;
  }
}

class Player extends GameObject {
  int health;
  int maxHealth;
  double shootCooldown;
  int weaponLevel;

  Player({required double x, required double y})
      : health = 100,
        maxHealth = 100,
        shootCooldown = 0,
        weaponLevel = 1,
        super(x: x, y: y, width: 40, height: 40);

  void update() {
    if (shootCooldown > 0) shootCooldown -= 0.016;
  }

  bool canShoot() => shootCooldown <= 0;

  void shoot() {
    if (canShoot()) {
      shootCooldown = weaponLevel > 2 ? 0.1 : 0.2;
    }
  }

  void takeDamage(int damage) {
    health = (health - damage).clamp(0, maxHealth);
    if (health <= 0) isDestroyed = true;
  }

  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }

  void upgradeWeapon() {
    weaponLevel = (weaponLevel + 1).clamp(1, 4);
  }
}

class Enemy extends GameObject {
  int health;
  Color color;
  double shootTimer;
  int points;

  Enemy({
    required double x,
    required double y,
    required this.health,
    required this.color,
    required this.points,
    double speed = 50,
  }) : shootTimer = Random().nextDouble() * 3,
        super(x: x, y: y, width: 30, height: 30, velocityY: speed);

  void update(double deltaTime) {
    y += velocityY * deltaTime;
    shootTimer -= deltaTime;
  }

  bool shouldShoot() {
    if (shootTimer <= 0) {
      shootTimer = 2 + Random().nextDouble() * 3;
      return true;
    }
    return false;
  }

  void takeDamage(int damage) {
    health -= damage;
    if (health <= 0) isDestroyed = true;
  }
}

class Bullet extends GameObject {
  bool isPlayerBullet;
  int damage;

  Bullet({
    required double x,
    required double y,
    required this.isPlayerBullet,
    this.damage = 25,
  }) : super(
    x: x,
    y: y,
    width: 4,
    height: 12,
    velocityY: isPlayerBullet ? -300 : 200,
  );

  void update(double deltaTime) {
    y += velocityY * deltaTime;
    if (y < -height || y > 800) isDestroyed = true;
  }
}

class PowerUp extends GameObject {
  String type;
  Color color;

  PowerUp({
    required double x,
    required double y,
    required this.type,
    required this.color,
  }) : super(x: x, y: y, width: 25, height: 25, velocityY: 80);

  void update(double deltaTime) {
    y += velocityY * deltaTime;
    if (y > 800) isDestroyed = true;
  }
}

class Star {
  double x, y, speed, opacity;

  Star({
    required this.x,
    required this.y,
    required this.speed,
    required this.opacity,
  });

  void update(double deltaTime) {
    y += speed * deltaTime;
    if (y > 800) {
      y = -5;
      x = Random().nextDouble() * 400;
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
  late Player player;
  List<Enemy> enemies = [];
  List<Bullet> bullets = [];
  List<PowerUp> powerUps = [];
  List<Star> stars = [];

  int score = 0;
  int wave = 1;
  bool gameOver = false;
  bool paused = false;
  double enemySpawnTimer = 0;
  double powerUpSpawnTimer = 0;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    initializeGame();

    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );

    _gameController.addListener(gameLoop);
    _gameController.repeat();
  }

  void initializeGame() {
    player = Player(x: 180, y: 700);
    enemies.clear();
    bullets.clear();
    powerUps.clear();

    // Initialize starfield
    stars = List.generate(100, (index) => Star(
      x: random.nextDouble() * 400,
      y: random.nextDouble() * 800,
      speed: 20 + random.nextDouble() * 60,
      opacity: 0.3 + random.nextDouble() * 0.7,
    ));

    score = 0;
    wave = 1;
    gameOver = false;
    enemySpawnTimer = 0;
    powerUpSpawnTimer = 0;
  }

  void gameLoop() {
    if (gameOver || paused) return;

    const deltaTime = 0.016;

    // Update game objects
    player.update();

    // Update stars
    for (var star in stars) {
      star.update(deltaTime);
    }

    // Update enemies
    enemies.removeWhere((enemy) {
      enemy.update(deltaTime);
      if (enemy.y > 800) {
        enemy.isDestroyed = true;
        return true;
      }

      // Enemy shooting
      if (enemy.shouldShoot()) {
        bullets.add(Bullet(
          x: enemy.x + enemy.width / 2,
          y: enemy.y + enemy.height,
          isPlayerBullet: false,
          damage: 15,
        ));
      }

      return enemy.isDestroyed;
    });

    // Update bullets
    bullets.removeWhere((bullet) {
      bullet.update(deltaTime);
      return bullet.isDestroyed;
    });

    // Update power-ups
    powerUps.removeWhere((powerUp) {
      powerUp.update(deltaTime);
      return powerUp.isDestroyed;
    });

    // Collision detection
    handleCollisions();

    // Spawn enemies
    enemySpawnTimer += deltaTime;
    if (enemySpawnTimer > (2.5 - wave * 0.2).clamp(0.5, 2.5)) {
      spawnEnemy();
      enemySpawnTimer = 0;
    }

    // Spawn power-ups
    powerUpSpawnTimer += deltaTime;
    if (powerUpSpawnTimer > 15) {
      spawnPowerUp();
      powerUpSpawnTimer = 0;
    }

    // Check wave progression
    if (enemies.isEmpty && score > wave * 500) {
      wave++;
      showWaveMessage();
    }

    // Check game over
    if (player.isDestroyed) {
      gameOver = true;
      showGameOverDialog();
    }

    setState(() {});
  }

  void spawnEnemy() {
    final enemyTypes = [
      {'health': 25, 'color': Colors.red, 'points': 100, 'speed': 50.0},
      {'health': 50, 'color': Colors.orange, 'points': 200, 'speed': 40.0},
      {'health': 75, 'color': Colors.purple, 'points': 300, 'speed': 30.0},
    ];

    final type = enemyTypes[random.nextInt(min(wave, enemyTypes.length))];

    enemies.add(Enemy(
      x: random.nextDouble() * 350,
      y: -40,
      health: type['health'] as int,
      color: type['color'] as Color,
      points: type['points'] as int,
      speed: type['speed'] as double,
    ));
  }

  void spawnPowerUp() {
    final powerUpTypes = ['health', 'weapon', 'shield'];
    final type = powerUpTypes[random.nextInt(powerUpTypes.length)];

    Color color;
    switch (type) {
      case 'health':
        color = Colors.green;
        break;
      case 'weapon':
        color = Colors.yellow;
        break;
      default:
        color = Colors.blue;
    }

    powerUps.add(PowerUp(
      x: random.nextDouble() * 350,
      y: -30,
      type: type,
      color: color,
    ));
  }

  void handleCollisions() {
    // Player bullets vs enemies
    for (var bullet in bullets.where((b) => b.isPlayerBullet)) {
      for (var enemy in enemies) {
        if (bullet.collidesWith(enemy) && !bullet.isDestroyed) {
          enemy.takeDamage(bullet.damage);
          bullet.isDestroyed = true;

          if (enemy.isDestroyed) {
            score += enemy.points;
            // Explosion effect could be added here
          }
          break;
        }
      }
    }

    // Enemy bullets vs player
    for (var bullet in bullets.where((b) => !b.isPlayerBullet)) {
      if (bullet.collidesWith(player) && !bullet.isDestroyed) {
        player.takeDamage(bullet.damage);
        bullet.isDestroyed = true;
        HapticFeedback.mediumImpact();
        break;
      }
    }

    // Player vs enemies (collision damage)
    for (var enemy in enemies) {
      if (player.collidesWith(enemy)) {
        player.takeDamage(30);
        enemy.isDestroyed = true;
        HapticFeedback.heavyImpact();
        break;
      }
    }

    // Player vs power-ups
    for (var powerUp in powerUps) {
      if (player.collidesWith(powerUp)) {
        applyPowerUp(powerUp.type);
        powerUp.isDestroyed = true;
        HapticFeedback.lightImpact();
        break;
      }
    }
  }

  void applyPowerUp(String type) {
    switch (type) {
      case 'health':
        player.heal(30);
        showMessage('Health Restored!', Colors.green);
        break;
      case 'weapon':
        player.upgradeWeapon();
        showMessage('Weapon Upgraded!', Colors.yellow);
        break;
      case 'shield':
        player.health = player.maxHealth;
        showMessage('Full Shield!', Colors.blue);
        break;
    }
  }

  void showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showWaveMessage() {
    showMessage('Wave $wave!', Colors.cyan);
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Game Over', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $score', style: const TextStyle(color: Colors.white)),
            Text('Wave Reached: $wave', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              restartGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  void restartGame() {
    setState(() {
      initializeGame();
    });
  }

  void togglePause() {
    setState(() {
      paused = !paused;
    });
  }

  void handlePanUpdate(DragUpdateDetails details) {
    if (!gameOver && !paused) {
      setState(() {
        player.x = (player.x + details.delta.dx).clamp(0, 360);
        player.y = (player.y + details.delta.dy).clamp(0, 760);
      });
    }
  }

  void handleTap() {
    if (!gameOver && !paused && player.canShoot()) {
      player.shoot();

      // Multi-shot based on weapon level
      if (player.weaponLevel == 1) {
        bullets.add(Bullet(
          x: player.x + player.width / 2,
          y: player.y,
          isPlayerBullet: true,
        ));
      } else if (player.weaponLevel == 2) {
        bullets.addAll([
          Bullet(x: player.x + 5, y: player.y, isPlayerBullet: true),
          Bullet(x: player.x + player.width - 5, y: player.y, isPlayerBullet: true),
        ]);
      } else if (player.weaponLevel >= 3) {
        bullets.addAll([
          Bullet(x: player.x, y: player.y, isPlayerBullet: true),
          Bullet(x: player.x + player.width / 2, y: player.y, isPlayerBullet: true),
          Bullet(x: player.x + player.width, y: player.y, isPlayerBullet: true),
        ]);
      }

      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _gameController.dispose();
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
            colors: [Color(0xFF000814), Color(0xFF001D3D), Color(0xFF003566)],
          ),
        ),
        child: GestureDetector(
          onPanUpdate: handlePanUpdate,
          onTap: handleTap,
          child: Stack(
            children: [
              // Stars
              ...stars.map((star) => Positioned(
                left: star.x,
                top: star.y,
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(star.opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              )),

              // Player
              if (!player.isDestroyed)
                Positioned(
                  left: player.x,
                  top: player.y,
                  child: Container(
                    width: player.width,
                    height: player.height,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan, Colors.blue],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flight, color: Colors.white, size: 24),
                  ),
                ),

              // Enemies
              ...enemies.map((enemy) => Positioned(
                left: enemy.x,
                top: enemy.y,
                child: Container(
                  width: enemy.width,
                  height: enemy.height,
                  decoration: BoxDecoration(
                    color: enemy.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: enemy.color.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              )),

              // Bullets
              ...bullets.map((bullet) => Positioned(
                left: bullet.x,
                top: bullet.y,
                child: Container(
                  width: bullet.width,
                  height: bullet.height,
                  decoration: BoxDecoration(
                    color: bullet.isPlayerBullet ? Colors.cyan : Colors.red,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: (bullet.isPlayerBullet ? Colors.cyan : Colors.red)
                            .withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              )),

              // Power-ups
              ...powerUps.map((powerUp) => Positioned(
                left: powerUp.x,
                top: powerUp.y,
                child: Container(
                  width: powerUp.width,
                  height: powerUp.height,
                  decoration: BoxDecoration(
                    color: powerUp.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: powerUp.color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    powerUp.type == 'health' ? Icons.favorite :
                    powerUp.type == 'weapon' ? Icons.flash_on : Icons.security,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              )),

              // UI
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score: $score', style: const TextStyle(color: Colors.white, fontSize: 18)),
                        Text('Wave: $wave', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Weapon: Lv${player.weaponLevel}',
                            style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                        Container(
                          width: 100,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: player.health / player.maxHealth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: player.health > 30 ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pause button
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  onPressed: togglePause,
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  color: Colors.white,
                  iconSize: 30,
                ),
              ),

              // Pause overlay
              if (paused)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54,
                  child: const Center(
                    child: Text(
                      'PAUSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
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