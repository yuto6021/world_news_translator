import 'package:flutter/material.dart';
import 'dart:math';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../utils/pet_image_resolver.dart';
import '../services/inventory_service.dart';

class BattleScreen extends StatefulWidget {
  final PetModel pet;

  const BattleScreen({super.key, required this.pet});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class Enemy {
  final String name;
  final String assetPath;
  final String attackAssetPath;
  final int level;
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;
  final String type; // normal, boss, secret_boss
  final int expReward;
  final String? itemDrop;

  int currentHp;

  Enemy({
    required this.name,
    required this.assetPath,
    required this.attackAssetPath,
    required this.level,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    this.type = 'normal',
    required this.expReward,
    this.itemDrop,
  }) : currentHp = maxHp;

  bool get isAlive => currentHp > 0;
  double get hpPercent => currentHp / maxHp;
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  late Enemy _currentEnemy;
  late int _petCurrentHp;
  late AnimationController _shakeController;
  late AnimationController _flashController;

  bool _battleStarted = false;
  bool _petTurn = true;
  bool _petAttacking = false;
  bool _enemyAttacking = false;
  List<String> _logHistory = [];

  static final List<Enemy> _normalEnemies = [
    Enemy(
      name: 'スライム',
      assetPath: 'assets/enemies/enemy_slime_normal.png',
      attackAssetPath: 'assets/enemies/enemy_slime_attack.png',
      level: 1,
      maxHp: 50,
      attack: 10,
      defense: 5,
      speed: 5,
      expReward: 10,
      itemDrop: 'slime_jelly',
    ),
    Enemy(
      name: 'ゴブリン',
      assetPath: 'assets/enemies/enemy_goblin_normal.png',
      attackAssetPath: 'assets/enemies/enemy_goblin_attack.png',
      level: 5,
      maxHp: 80,
      attack: 15,
      defense: 10,
      speed: 12,
      expReward: 20,
      itemDrop: 'goblin_sword',
    ),
    Enemy(
      name: 'ウルフ',
      assetPath: 'assets/enemies/enemy_wolf_normal.png',
      attackAssetPath: 'assets/enemies/enemy_wolf_attack.png',
      level: 8,
      maxHp: 100,
      attack: 20,
      defense: 12,
      speed: 25,
      expReward: 30,
      itemDrop: 'wolf_fang',
    ),
    Enemy(
      name: 'ゾンビ',
      assetPath: 'assets/enemies/enemy_zombie_normal.png',
      attackAssetPath: 'assets/enemies/enemy_zombie_attack.png',
      level: 10,
      maxHp: 120,
      attack: 18,
      defense: 20,
      speed: 8,
      expReward: 35,
      itemDrop: 'zombie_bone',
    ),
    Enemy(
      name: 'フェアリー',
      assetPath: 'assets/enemies/enemy_fairy_normal.png',
      attackAssetPath: 'assets/enemies/enemy_fairy_attack.png',
      level: 12,
      maxHp: 90,
      attack: 25,
      defense: 15,
      speed: 30,
      expReward: 40,
      itemDrop: 'fairy_dust',
    ),
    Enemy(
      name: 'エレメンタル',
      assetPath: 'assets/enemies/enemy_elemental_normal.png',
      attackAssetPath: 'assets/enemies/enemy_elemental_attack.png',
      level: 15,
      maxHp: 150,
      attack: 30,
      defense: 25,
      speed: 20,
      expReward: 50,
      itemDrop: 'elemental_crystal',
    ),
    Enemy(
      name: 'ドラゴン',
      assetPath: 'assets/enemies/enemy_dragon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_dragon_attack.png',
      level: 20,
      maxHp: 200,
      attack: 40,
      defense: 35,
      speed: 18,
      expReward: 80,
      itemDrop: 'dragon_scale',
    ),
    Enemy(
      name: 'ゴーレム',
      assetPath: 'assets/enemies/enemy_golem_normal.png',
      attackAssetPath: 'assets/enemies/enemy_golem_attack.png',
      level: 18,
      maxHp: 250,
      attack: 35,
      defense: 50,
      speed: 10,
      expReward: 70,
      itemDrop: 'golem_core',
    ),
  ];

  static final List<Enemy> _bossEnemies = [
    Enemy(
      name: 'タイタン',
      assetPath: 'assets/enemies/boss/enemy_boss_titan_normal.png',
      attackAssetPath: 'assets/enemies/boss/enemy_boss_titan_attack.png',
      level: 30,
      maxHp: 500,
      attack: 60,
      defense: 60,
      speed: 15,
      type: 'boss',
      expReward: 200,
      itemDrop: 'titan_hammer',
    ),
    Enemy(
      name: 'ダークロード',
      assetPath: 'assets/enemies/boss/enemy_boss_darklord_normal.png',
      attackAssetPath: 'assets/enemies/boss/enemy_boss_darklord_attack.png',
      level: 40,
      maxHp: 800,
      attack: 80,
      defense: 70,
      speed: 25,
      type: 'boss',
      expReward: 300,
      itemDrop: 'dark_sword',
    ),
  ];

  static final Enemy _secretBoss = Enemy(
    name: '???',
    assetPath: 'assets/enemies/secret_boss/enemy_secret_boss_normal.png',
    attackAssetPath:
        'assets/enemies/secret_boss/enemy_secret_boss_attack1.png', // 初期フレーム
    level: 99,
    maxHp: 9999,
    attack: 150,
    defense: 100,
    speed: 50,
    type: 'secret_boss',
    expReward: 1000,
    itemDrop: 'ultimate_crystal',
  );

  @override
  void initState() {
    super.initState();
    _petCurrentHp = widget.pet.hp;
    _selectRandomEnemy();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _selectRandomEnemy() {
    final random = Random();

    // シークレットボス出現条件: Lv50以上、勝利50回以上、1%確率
    if (widget.pet.level >= 50 &&
        widget.pet.wins >= 50 &&
        random.nextInt(100) == 0) {
      _currentEnemy = Enemy(
        name: _secretBoss.name,
        assetPath: _secretBoss.assetPath,
        attackAssetPath: _secretBoss.attackAssetPath,
        level: _secretBoss.level,
        maxHp: _secretBoss.maxHp,
        attack: _secretBoss.attack,
        defense: _secretBoss.defense,
        speed: _secretBoss.speed,
        type: _secretBoss.type,
        expReward: _secretBoss.expReward,
        itemDrop: _secretBoss.itemDrop,
      );
      _addLog('⚠️ シークレットボス出現！！');
      return;
    }

    // ボス出現条件: Lv20以上、10%確率
    if (widget.pet.level >= 20 && random.nextInt(10) == 0) {
      final boss = _bossEnemies[random.nextInt(_bossEnemies.length)];
      _currentEnemy = Enemy(
        name: boss.name,
        assetPath: boss.assetPath,
        attackAssetPath: boss.attackAssetPath,
        level: boss.level,
        maxHp: boss.maxHp,
        attack: boss.attack,
        defense: boss.defense,
        speed: boss.speed,
        type: boss.type,
        expReward: boss.expReward,
        itemDrop: boss.itemDrop,
      );
      _addLog('🔥 ボス敵が現れた！');
      return;
    }

    // 通常の敵
    final enemy = _normalEnemies[random.nextInt(_normalEnemies.length)];
    _currentEnemy = Enemy(
      name: enemy.name,
      assetPath: enemy.assetPath,
      attackAssetPath: enemy.attackAssetPath,
      level: enemy.level,
      maxHp: enemy.maxHp,
      attack: enemy.attack,
      defense: enemy.defense,
      speed: enemy.speed,
      type: enemy.type,
      expReward: enemy.expReward,
      itemDrop: enemy.itemDrop,
    );
  }

  void _addLog(String message) {
    setState(() {
      _logHistory.insert(0, message);
      if (_logHistory.length > 10) _logHistory.removeLast();
    });
  }

  Future<void> _startBattle() async {
    setState(() => _battleStarted = true);
    _addLog('${_currentEnemy.name} Lv.${_currentEnemy.level}が現れた！');

    // 速度比較で先攻決定
    final petSpeed = widget.pet.speed;
    final enemySpeed = _currentEnemy.speed;

    if (petSpeed >= enemySpeed) {
      _addLog('${widget.pet.name}の先攻！');
      _petTurn = true;
    } else {
      _addLog('${_currentEnemy.name}の先攻！');
      _petTurn = false;
      await Future.delayed(const Duration(milliseconds: 1500));
      _enemyAttack();
    }
  }

  Future<void> _petAttack() async {
    if (!_petTurn || _petAttacking) return;

    setState(() => _petAttacking = true);
    _addLog('${widget.pet.name}の攻撃！');

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    final baseDamage = widget.pet.attack;
    final defense = _currentEnemy.defense;
    final damage = max(1, baseDamage - (defense ~/ 2) + random.nextInt(10) - 5);

    _currentEnemy.currentHp = max(0, _currentEnemy.currentHp - damage);
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    _addLog('${_currentEnemy.name}に${damage}ダメージ！');

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!_currentEnemy.isAlive) {
      _victory();
    } else {
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      _enemyAttack();
    }
  }

  int _secretBossFrameIndex = 0; // シークレットボス攻撃アニメ用

  Future<void> _enemyAttack() async {
    if (_petTurn || _enemyAttacking) return;

    setState(() => _enemyAttacking = true);
    _addLog('${_currentEnemy.name}の攻撃！');
    if (_currentEnemy.type == 'secret_boss') {
      _secretBossFrameIndex = (_secretBossFrameIndex + 1) % 3;
    }

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    final baseDamage = _currentEnemy.attack;
    final defense = widget.pet.defense;
    final damage = max(1, baseDamage - (defense ~/ 2) + random.nextInt(10) - 5);

    _petCurrentHp = max(0, _petCurrentHp - damage);
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    _addLog('${widget.pet.name}に${damage}ダメージ！');

    await Future.delayed(const Duration(milliseconds: 1000));

    if (_petCurrentHp <= 0) {
      _defeat();
    } else {
      setState(() {
        _petTurn = true;
        _enemyAttacking = false;
      });
    }
  }

  void _victory() {
    // コイン報酬計算（ボス/シークレット補正）
    int coinReward = _currentEnemy.level * 10 + Random().nextInt(50);
    if (_currentEnemy.type == 'boss') coinReward = (coinReward * 1.5).round();
    if (_currentEnemy.type == 'secret_boss')
      coinReward = (coinReward * 3).round();
    InventoryService.addCoins(coinReward);

    // アイテムドロップ処理
    if (_currentEnemy.itemDrop != null && Random().nextInt(100) < 30) {
      InventoryService.addItem(_currentEnemy.itemDrop!);
    }

    _addLog('🎉 ${_currentEnemy.name}を倒した！');
    _addLog('経験値+${_currentEnemy.expReward}');
    _addLog('コイン+$coinReward');

    if (_currentEnemy.itemDrop != null) {
      _addLog('アイテム「${_currentEnemy.itemDrop}」を入手！');
    }

    // データベース更新
    PetService.incrementWins(widget.pet.id);
    PetService.addExp(widget.pet.id, _currentEnemy.expReward);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Text('勝利！'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_currentEnemy.name} Lv.${_currentEnemy.level}を倒しました！'),
                const SizedBox(height: 12),
                Text('経験値: +${_currentEnemy.expReward}'),
                Text('コイン: +$coinReward'),
                if (_currentEnemy.itemDrop != null)
                  Text('アイテム: ${_currentEnemy.itemDrop}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to pet screen
                },
                child: const Text('戻る'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _defeat() {
    _addLog('💔 ${widget.pet.name}は倒れた...');

    PetService.incrementLosses(widget.pet.id);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.sentiment_very_dissatisfied,
                    color: Colors.grey, size: 32),
                SizedBox(width: 12),
                Text('敗北...'),
              ],
            ),
            content: Text('${_currentEnemy.name}に敗北しました...'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('戻る'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _runAway() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('逃げますか？'),
        content: const Text('経験値は獲得できません'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('逃げる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('バトル - ${widget.pet.name}'),
        actions: [
          if (_battleStarted)
            IconButton(
              icon: const Icon(Icons.directions_run),
              onPressed: _runAway,
              tooltip: '逃げる',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _currentEnemy.type == 'secret_boss'
                ? [const Color(0xFF1a0033), const Color(0xFF330066)]
                : _currentEnemy.type == 'boss'
                    ? [const Color(0xFF4a0000), const Color(0xFF2a0000)]
                    : isDark
                        ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                        : [const Color(0xFFe8f5e9), const Color(0xFFc8e6c9)],
          ),
        ),
        child: Column(
          children: [
            // 敵エリア
            Expanded(
              flex: 2,
              child: _buildEnemyArea(),
            ),

            // バトルログ
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _logHistory.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logHistory[index],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ペットエリア
            Expanded(
              flex: 2,
              child: _buildPetArea(),
            ),

            // アクションボタン
            if (_battleStarted) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemyArea() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset =
            _enemyAttacking ? 0.0 : sin(_shakeController.value * pi * 4) * 10;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 敵ステータス
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: _currentEnemy.type == 'secret_boss'
                    ? Colors.purple.withOpacity(0.3)
                    : _currentEnemy.type == 'boss'
                        ? Colors.red.withOpacity(0.3)
                        : Colors.black.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        _currentEnemy.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _currentEnemy.type == 'secret_boss'
                              ? Colors.purple[200]
                              : _currentEnemy.type == 'boss'
                                  ? Colors.red[200]
                                  : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lv.${_currentEnemy.level}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _currentEnemy.hpPercent,
                                minHeight: 16,
                                backgroundColor: Colors.grey[700],
                                color: _currentEnemy.hpPercent > 0.5
                                    ? Colors.green
                                    : _currentEnemy.hpPercent > 0.25
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentEnemy.currentHp}/${_currentEnemy.maxHp}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 敵画像
              AnimatedBuilder(
                animation: _flashController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _enemyAttacking
                        ? 1.0
                        : 1.0 - (_flashController.value * 0.7),
                    child: Image.asset(
                      _enemyAttacking
                          ? (_currentEnemy.type == 'secret_boss'
                              ? _secretBossAttackFrame()
                              : _currentEnemy.attackAssetPath)
                          : _currentEnemy.assetPath,
                      height: 180,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.error,
                          size: 180,
                          color: Colors.red[300],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetArea() {
    final petImage = PetImageResolver.resolveImage(
      widget.pet.stage,
      widget.pet.species,
      'normal',
    );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset =
            _petAttacking ? 0.0 : sin(_shakeController.value * pi * 4) * 10;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ペット画像
              AnimatedBuilder(
                animation: _flashController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _petAttacking
                        ? 1.0
                        : 1.0 - (_flashController.value * 0.7),
                    child: Image.asset(
                      petImage,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.pets,
                            size: 150, color: Colors.grey);
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ペットステータス
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.blue.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        widget.pet.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lv.${widget.pet.level}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _petCurrentHp / widget.pet.hp,
                                minHeight: 16,
                                backgroundColor: Colors.grey[700],
                                color: _petCurrentHp / widget.pet.hp > 0.5
                                    ? Colors.green
                                    : _petCurrentHp / widget.pet.hp > 0.25
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_petCurrentHp/${widget.pet.hp}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _petTurn && !_petAttacking ? _petAttack : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, size: 24),
                  SizedBox(width: 8),
                  Text('攻撃',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _secretBossAttackFrame() {
    switch (_secretBossFrameIndex) {
      case 0:
        return 'assets/enemies/secret_boss/enemy_secret_boss_attack1.png';
      case 1:
        return 'assets/enemies/secret_boss/enemy_secret_boss_attack2.png';
      case 2:
        return 'assets/enemies/secret_boss/enemy_secret_boss_attack3.png';
      default:
        return 'assets/enemies/secret_boss/enemy_secret_boss_attack1.png';
    }
  }
}
