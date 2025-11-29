import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/pet.dart';
import '../models/skill.dart';
import '../services/pet_service.dart';
import '../utils/pet_image_resolver.dart';
import '../services/inventory_service.dart';
import '../services/weather_cycle_service.dart';
import '../services/equipment_service.dart';

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
  final String element; // 属性追加

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
    this.element = 'normal', // デフォルトは無属性
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
  late AnimationController _comboController;

  bool _battleStarted = false;
  bool _petTurn = true;
  bool _petAttacking = false;
  bool _enemyAttacking = false;
  bool _showComboEffect = false;
  int _comboCount = 0; // 連続攻撃のコンボカウント
  List<String> _logHistory = [];

  // 状態異常管理
  String? _petStatus; // poison, paralysis, sleep, burn
  int _petStatusTurns = 0; // 状態異常の残りターン数
  String? _enemyStatus;
  int _enemyStatusTurns = 0;

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
      element: 'water',
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
      element: 'normal',
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
      element: 'normal',
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
      element: 'dark',
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
      element: 'light',
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
      element: 'electric',
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
      element: 'fire',
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
      element: 'normal',
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
      element: 'normal',
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
      element: 'dark',
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
    element: 'dark',
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

    _comboController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    _comboController.dispose();
    super.dispose();
  }

  // タイプ相性計算（ポケモン風）
  double _calculateTypeEffectiveness(String attackerType, String defenderType) {
    // タイプ相性表（2倍有利 / 0.5倍不利 / 0倍無効）
    const typeChart = {
      'fire': {'grass': 2.0, 'water': 0.5, 'fire': 0.5, 'ice': 2.0},
      'water': {'fire': 2.0, 'grass': 0.5, 'water': 0.5, 'electric': 0.5},
      'grass': {'water': 2.0, 'fire': 0.5, 'grass': 0.5, 'ice': 0.5},
      'electric': {'water': 2.0, 'grass': 0.5, 'electric': 0.5},
      'ice': {'grass': 2.0, 'fire': 0.5, 'water': 0.5},
      'dark': {'light': 2.0, 'dark': 0.5},
      'light': {'dark': 2.0, 'light': 0.5},
    };

    if (typeChart.containsKey(attackerType) &&
        typeChart[attackerType]!.containsKey(defenderType)) {
      return typeChart[attackerType]![defenderType]!;
    }
    return 1.0; // 通常倍率
  }

  // ペット種族 → 属性マッピング
  String _getPetElement(String species) {
    const petElementMap = {
      'agumon': 'fire',
      'greymon': 'fire',
      'wargreymon': 'fire',
      'gabumon': 'water',
      'garurumon': 'water',
      'metalgarurumon': 'water',
      'patamon': 'light',
      'angemon': 'light',
      'devimon': 'dark',
      'palmon': 'grass',
      'tentomon': 'electric',
    };
    return petElementMap[species] ?? 'normal';
  }

  // 敵名 → 属性マッピング
  String _getEnemyElement(String name) {
    if (name.contains('ファイア') || name.contains('マグマ')) return 'fire';
    if (name.contains('アイス') || name.contains('氷')) return 'ice';
    if (name.contains('サンダー') || name.contains('雷')) return 'electric';
    if (name.contains('アクア') || name.contains('水')) return 'water';
    if (name.contains('フォレスト') || name.contains('森')) return 'grass';
    if (name.contains('ダーク') || name.contains('影')) return 'dark';
    if (name.contains('ライト') || name.contains('光')) return 'light';
    return 'normal';
  }

  // 属性アイコン
  String _getElementIcon(String element) {
    const icons = {
      'fire': '🔥',
      'water': '💧',
      'grass': '🌿',
      'electric': '⚡',
      'ice': '❄️',
      'dark': '🌑',
      'light': '✨',
      'normal': '⚪',
    };
    return icons[element] ?? '⚪';
  }

  // 属性名
  String _getElementName(String element) {
    const names = {
      'fire': '炎',
      'water': '水',
      'grass': '草',
      'electric': '雷',
      'ice': '氷',
      'dark': '闇',
      'light': '光',
      'normal': '無',
    };
    return names[element] ?? '無';
  }

  void _selectRandomEnemy() {
    final random = Random();
    final petLevel = widget.pet.level;

    // シークレットボス出現条件: Lv50以上、勝利50回以上、1%確率
    if (petLevel >= 50 && widget.pet.wins >= 50 && random.nextInt(100) == 0) {
      _currentEnemy = _createScaledEnemy(_secretBoss, petLevel);
      _addLog('⚠️ シークレットボス出現！！');
      return;
    }

    // ボス出現条件: Lv20以上、10%確率
    if (petLevel >= 20 && random.nextInt(10) == 0) {
      final boss = _bossEnemies[random.nextInt(_bossEnemies.length)];
      _currentEnemy = _createScaledEnemy(boss, petLevel);
      _addLog('🔥 ボス敵が現れた！');
      return;
    }

    // 通常の敵（ペットレベルに近い敵を選択）
    final suitableEnemies =
        _normalEnemies.where((e) => (e.level - petLevel).abs() <= 5).toList();

    final enemy = suitableEnemies.isNotEmpty
        ? suitableEnemies[random.nextInt(suitableEnemies.length)]
        : _normalEnemies[random.nextInt(_normalEnemies.length)];

    _currentEnemy = _createScaledEnemy(enemy, petLevel);
  }

  // 敵をペットレベルに合わせてスケーリング
  Enemy _createScaledEnemy(Enemy baseEnemy, int petLevel) {
    if (baseEnemy.type == 'secret_boss') {
      // シークレットボスはスケーリングなし（常に強敵）
      return Enemy(
        name: baseEnemy.name,
        assetPath: baseEnemy.assetPath,
        attackAssetPath: baseEnemy.attackAssetPath,
        level: baseEnemy.level,
        maxHp: baseEnemy.maxHp,
        attack: baseEnemy.attack,
        defense: baseEnemy.defense,
        speed: baseEnemy.speed,
        type: baseEnemy.type,
        expReward: baseEnemy.expReward,
        itemDrop: baseEnemy.itemDrop,
        element: baseEnemy.element,
      );
    }

    // レベル差に応じたスケーリング係数（±30%）
    final levelDiff = petLevel - baseEnemy.level;
    final scaleFactor = 1.0 + (levelDiff * 0.06); // レベル差1につき6%増減
    final clampedScale = scaleFactor.clamp(0.7, 1.5); // 最小70%、最大150%

    return Enemy(
      name: baseEnemy.name,
      assetPath: baseEnemy.assetPath,
      attackAssetPath: baseEnemy.attackAssetPath,
      level: (baseEnemy.level + levelDiff ~/ 2).clamp(1, 99), // レベルも調整
      maxHp: (baseEnemy.maxHp * clampedScale).round(),
      attack: (baseEnemy.attack * clampedScale).round(),
      defense: (baseEnemy.defense * clampedScale).round(),
      speed: baseEnemy.speed, // 速度は固定
      type: baseEnemy.type,
      expReward: (baseEnemy.expReward * clampedScale).round(),
      itemDrop: baseEnemy.itemDrop,
      element: baseEnemy.element,
    );
  }

  void _addLog(String message) {
    setState(() {
      _logHistory.insert(0, message);
      if (_logHistory.length > 10) _logHistory.removeLast();
    });
  }

  // 状態異常を付与（20%の確率）
  void _tryApplyStatus(String target, String statusType) {
    final random = Random();
    if (random.nextInt(100) < 20) {
      // 20%確率
      if (target == 'pet' && _petStatus == null) {
        setState(() {
          _petStatus = statusType;
          _petStatusTurns = statusType == 'sleep' ? 3 : 5; // 眠りは3ターン、他は5ターン
        });
        _addLog('${widget.pet.name}は${_getStatusName(statusType)}になった！');
      } else if (target == 'enemy' && _enemyStatus == null) {
        setState(() {
          _enemyStatus = statusType;
          _enemyStatusTurns = statusType == 'sleep' ? 3 : 5;
        });
        _addLog('${_currentEnemy.name}は${_getStatusName(statusType)}になった！');
      }
    }
  }

  // 状態異常の効果処理
  Future<bool> _processStatus(String target) async {
    if (target == 'pet' && _petStatus != null) {
      switch (_petStatus) {
        case 'poison':
          final poisonDamage = (widget.pet.hp * 0.08).round(); // HP8%のダメージ
          _petCurrentHp = max(0, _petCurrentHp - poisonDamage);
          _addLog('💀 ${widget.pet.name}は毒のダメージを受けた！(${poisonDamage}ダメージ)');
          await Future.delayed(const Duration(milliseconds: 800));
          break;
        case 'burn':
          final burnDamage = (widget.pet.hp * 0.06).round(); // HP6%のダメージ
          _petCurrentHp = max(0, _petCurrentHp - burnDamage);
          _addLog('🔥 ${widget.pet.name}は火傷のダメージを受けた！(${burnDamage}ダメージ)');
          await Future.delayed(const Duration(milliseconds: 800));
          break;
        case 'paralysis':
          if (Random().nextInt(100) < 25) {
            // 25%で行動不能
            _addLog('⚡ ${widget.pet.name}は痺れて動けない！');
            return false; // 行動不可
          }
          break;
        case 'sleep':
          _addLog('💤 ${widget.pet.name}は眠っている...');
          return false; // 行動不可
      }
      // ターン経過
      _petStatusTurns--;
      if (_petStatusTurns <= 0) {
        _addLog('✨ ${widget.pet.name}の${_getStatusName(_petStatus!)}が治った！');
        setState(() => _petStatus = null);
      }
    } else if (target == 'enemy' && _enemyStatus != null) {
      switch (_enemyStatus) {
        case 'poison':
          final poisonDamage = (_currentEnemy.maxHp * 0.08).round();
          _currentEnemy.currentHp =
              max(0, _currentEnemy.currentHp - poisonDamage);
          _addLog('💀 ${_currentEnemy.name}は毒のダメージを受けた！(${poisonDamage}ダメージ)');
          await Future.delayed(const Duration(milliseconds: 800));
          break;
        case 'burn':
          final burnDamage = (_currentEnemy.maxHp * 0.06).round();
          _currentEnemy.currentHp =
              max(0, _currentEnemy.currentHp - burnDamage);
          _addLog('🔥 ${_currentEnemy.name}は火傷のダメージを受けた！(${burnDamage}ダメージ)');
          await Future.delayed(const Duration(milliseconds: 800));
          break;
        case 'paralysis':
          if (Random().nextInt(100) < 25) {
            _addLog('⚡ ${_currentEnemy.name}は痺れて動けない！');
            return false;
          }
          break;
        case 'sleep':
          _addLog('💤 ${_currentEnemy.name}は眠っている...');
          return false;
      }
      _enemyStatusTurns--;
      if (_enemyStatusTurns <= 0) {
        _addLog(
            '✨ ${_currentEnemy.name}の${_getStatusName(_enemyStatus!)}が治った！');
        setState(() => _enemyStatus = null);
      }
    }
    return true; // 行動可能
  }

  String _getStatusName(String status) {
    const names = {
      'poison': '毒',
      'paralysis': '麻痺',
      'sleep': '眠り',
      'burn': '火傷',
    };
    return names[status] ?? '';
  }

  String _getStatusIcon(String status) {
    const icons = {
      'poison': '💀',
      'paralysis': '⚡',
      'sleep': '💤',
      'burn': '🔥',
    };
    return icons[status] ?? '';
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

    // しつけチェック（言うことを聞かない判定）
    if (widget.pet.discipline < 30 && Random().nextInt(100) < 20) {
      _addLog('${widget.pet.name}は言うことを聞かない！');
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      _enemyAttack();
      return;
    }

    // 状態異常チェック（行動前）
    final canAct = await _processStatus('pet');
    if (!canAct) {
      // 行動不能（麻痺or眠り）
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      _enemyAttack();
      return;
    }

    _addLog('${widget.pet.name}の攻撃！');

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    var baseDamage = widget.pet.attack;

    // 装備ボーナス適用
    final equipmentBonus = EquipmentService.getTotalEquipmentBonus(
      widget.pet.equippedWeapon,
      widget.pet.equippedArmor,
      widget.pet.equippedAccessory,
    );
    if (equipmentBonus['attack'] != null) {
      baseDamage = (baseDamage * equipmentBonus['attack']!).round();
    }

    // 性格ボーナス適用
    final personalityBonus =
        PetService.getPersonalityBonus(widget.pet.truePersonality);
    if (personalityBonus['attack'] != null) {
      baseDamage = (baseDamage * personalityBonus['attack']!).round();
    }

    // 火傷状態なら攻撃力半減
    if (_petStatus == 'burn') {
      baseDamage = (baseDamage * 0.5).round();
    }

    final defense = _currentEnemy.defense;

    // ダメージ計算式改善：防御力の影響を調整
    final defenseFactor = defense / (defense + 100); // 防御力100で50%軽減
    final rawDamage = baseDamage * (1 - defenseFactor);
    int damage =
        (rawDamage + random.nextInt(baseDamage ~/ 5 + 1) - baseDamage ~/ 10)
            .round();
    damage = max(1, damage); // 最低1ダメージ

    // タイプ相性によるダメージ補正（ポケモン風）
    final petElement = _getPetElement(widget.pet.species);
    final enemyElement = _currentEnemy.element; // 敵の実属性を使用
    final typeEffectiveness =
        _calculateTypeEffectiveness(petElement, enemyElement);

    if (typeEffectiveness > 1.0) {
      damage = (damage * typeEffectiveness).round();
      _addLog('🔥 効果はバツグンだ！');
    } else if (typeEffectiveness < 1.0 && typeEffectiveness > 0) {
      damage = (damage * typeEffectiveness).round();
      _addLog('💧 効果はいまひとつだ...');
    } else if (typeEffectiveness == 0) {
      damage = 0;
      _addLog('⛔ 効果がない...');
    }

    // 天候・時間ボーナス（属性ベース）
    final weatherBonus = WeatherCycleService.getTotalBonus();
    final elementBonus = weatherBonus[petElement] ?? 1.0;
    if (elementBonus != 1.0) {
      damage = (damage * elementBonus).round();
      if (elementBonus > 1.0) {
        _addLog('🌤️ 天候の恩恵！(×${elementBonus.toStringAsFixed(1)})');
      } else {
        _addLog('🌧️ 天候が不利...(×${elementBonus.toStringAsFixed(2)})');
      }
    }

    damage = max(1, damage); // 最低1ダメージ保証

    // クリティカル判定（15%）
    final isCritical = random.nextInt(100) < 15;
    if (isCritical) {
      damage = (damage * 1.5).round();
      _addLog('⚡ クリティカルヒット！');
      // 振動エフェクト
      HapticFeedback.heavyImpact();
      _shakeController.repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 400));
      _shakeController.stop();
      _shakeController.reset();
    }

    _currentEnemy.currentHp = max(0, _currentEnemy.currentHp - damage);
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    _addLog('${_currentEnemy.name}に${damage}ダメージ！');

    // 状態異常付与チェック（攻撃属性に応じて）
    if (petElement == 'fire') {
      _tryApplyStatus('enemy', 'burn'); // 炎攻撃で火傷
    } else if (petElement == 'electric') {
      _tryApplyStatus('enemy', 'paralysis'); // 雷攻撃で麻痺
    } else if (petElement == 'grass') {
      _tryApplyStatus('enemy', 'poison'); // 草攻撃で毒
    }

    // コンボ判定（クリティカル時にコンボカウント増加）
    if (isCritical) {
      _comboCount++;
      if (_comboCount >= 3) {
        await _triggerComboEffect();
      }
    } else {
      _comboCount = 0; // コンボリセット
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!_currentEnemy.isAlive) {
      await _victory();
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

    // 状態異常チェック（行動前）
    final canAct = await _processStatus('enemy');
    if (!canAct) {
      // 行動不能
      setState(() {
        _petTurn = true;
        _enemyAttacking = false;
      });
      return;
    }

    _addLog('${_currentEnemy.name}の攻撃！');
    if (_currentEnemy.type == 'secret_boss') {
      _secretBossFrameIndex = (_secretBossFrameIndex + 1) % 3;
    }

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    var baseDamage = _currentEnemy.attack;

    // 火傷状態なら攻撃力半減
    if (_enemyStatus == 'burn') {
      baseDamage = (baseDamage * 0.5).round();
    }

    final defense = widget.pet.defense;

    // 同じダメージ計算式を適用
    final defenseFactor = defense / (defense + 100);
    final rawDamage = baseDamage * (1 - defenseFactor);
    int damage =
        (rawDamage + random.nextInt(baseDamage ~/ 5 + 1) - baseDamage ~/ 10)
            .round();
    damage = max(1, damage);

    _petCurrentHp = max(0, _petCurrentHp - damage);
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    _addLog('${widget.pet.name}に${damage}ダメージ！');

    // 状態異常付与チェック（敵の属性に応じて）
    final enemyElement = _currentEnemy.element;
    if (enemyElement == 'fire') {
      _tryApplyStatus('pet', 'burn');
    } else if (enemyElement == 'electric') {
      _tryApplyStatus('pet', 'paralysis');
    } else if (enemyElement == 'grass') {
      _tryApplyStatus('pet', 'poison');
    }

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

  Future<void> _victory() async {
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

    // 素材ドロップ（30%確率）
    if (Random().nextInt(100) < 30) {
      // 敵タイプに応じた素材ドロップ
      final droppedMaterial = _getEnemyDropMaterial(_currentEnemy);
      await EquipmentService.addMaterial(droppedMaterial, 1);
      _addLog('素材「${EquipmentService.getMaterialName(droppedMaterial)}」を入手！');

      // 1%確率でレア素材（2個）
      if (Random().nextInt(100) == 0) {
        await EquipmentService.addMaterial(droppedMaterial, 1);
        _addLog('✨ レア素材ボーナス！ もう1個入手！');
      }
    }

    _addLog('🎉 ${_currentEnemy.name}を倒した！');
    _addLog('経験値+${_currentEnemy.expReward}');
    _addLog('コイン+$coinReward');

    if (_currentEnemy.itemDrop != null) {
      _addLog('アイテム「${_currentEnemy.itemDrop}」を入手！');
    }

    // データベース更新
    await PetService.incrementWins(widget.pet.id);
    final int oldLevel = widget.pet.level;
    await PetService.addExp(widget.pet.id, _currentEnemy.expReward);

    // スキルポイント獲得（バトル勝利ごとに1～3ポイント）
    final int spGained = 1 +
        (_currentEnemy.type == 'boss'
            ? 2
            : _currentEnemy.type == 'secret_boss'
                ? 5
                : 0);
    await _addSkillPoints(spGained);
    _addLog('スキルポイント+$spGained');

    // レベルアップチェック
    final updatedPet = await PetService.getPetById(widget.pet.id);
    final bool leveledUp = updatedPet?.level != oldLevel;

    // 新スキル習得チェック
    final List<Skill> newSkills = [];
    if (updatedPet != null && leveledUp) {
      newSkills.addAll(await _checkNewSkillsLearned(updatedPet));
    }

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      // レベルアップ時の特別演出
      if (leveledUp && updatedPet != null) {
        await _showLevelUpDialog(updatedPet, oldLevel, newSkills);
      } else {
        // 通常の勝利ダイアログ
        await showDialog(
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
                Text('スキルポイント: +$spGained'),
                if (_currentEnemy.itemDrop != null)
                  Text('アイテム: ${_currentEnemy.itemDrop}'),
                if (newSkills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('🎉 新スキル習得！',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                  ...newSkills.map((s) => Text('  • ${s.name}')),
                ],
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

      if (mounted) {
        Navigator.pop(context); // Return to pet screen
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
        child: Stack(
          children: [
            Column(
              children: [
                // 敵エリア
                Expanded(
                  flex: 2,
                  child: _buildEnemyArea(),
                ),

                // バトルログ
                Container(
                  height: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade700, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _logHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          _logHistory[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
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

            // コンボエフェクトオーバーレイ
            if (_showComboEffect) _buildComboOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildComboOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _comboController,
        builder: (context, child) {
          final progress = _comboController.value;
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final scale = 1.0 + (progress * 0.5);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withOpacity(0.3 * opacity),
                  Colors.orange.withOpacity(0.3 * opacity),
                  Colors.yellow.withOpacity(0.3 * opacity),
                  Colors.green.withOpacity(0.3 * opacity),
                  Colors.blue.withOpacity(0.3 * opacity),
                  Colors.purple.withOpacity(0.3 * opacity),
                ],
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7 * opacity),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.amber.withOpacity(opacity),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5 * opacity),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_comboCount}',
                        style: TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: [
                                Colors.red.withOpacity(opacity),
                                Colors.orange.withOpacity(opacity),
                                Colors.yellow.withOpacity(opacity),
                                Colors.green.withOpacity(opacity),
                                Colors.blue.withOpacity(opacity),
                                Colors.purple.withOpacity(opacity),
                              ],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 120)),
                        ),
                      ),
                      Text(
                        'COMBO!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.withOpacity(opacity),
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
                      const SizedBox(height: 4),
                      // 属性バッジ
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getElementColor(_currentEnemy.element)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _getElementColor(_currentEnemy.element)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getElementIcon(_currentEnemy.element),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getElementName(_currentEnemy.element),
                              style: TextStyle(
                                color: _getElementColor(_currentEnemy.element),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 状態異常アイコン
                      if (_enemyStatus != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getStatusIcon(_enemyStatus!),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusName(_enemyStatus!),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      const SizedBox(height: 4),
                      // ペット属性バッジ
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getElementColor(
                                  _getPetElement(widget.pet.species))
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _getElementColor(
                                  _getPetElement(widget.pet.species))),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getElementIcon(
                                  _getPetElement(widget.pet.species)),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getElementName(
                                  _getPetElement(widget.pet.species)),
                              style: TextStyle(
                                color: _getElementColor(
                                    _getPetElement(widget.pet.species)),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ペット状態異常アイコン
                      if (_petStatus != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getStatusIcon(_petStatus!),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusName(_petStatus!),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
            top: BorderSide(color: Colors.amber.withOpacity(0.3), width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _petTurn && !_petAttacking ? _petAttack : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, size: 28),
                  SizedBox(width: 10),
                  Text('攻撃',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _petTurn && !_petAttacking ? _showSkillMenu : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 28),
                  SizedBox(width: 10),
                  Text('スキル',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSkillMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSkillMenuSheet(),
    );
  }

  Widget _buildSkillMenuSheet() {
    final learnedSkillIds = widget.pet.skills;
    final learnedSkills = learnedSkillIds
        .map((id) => Skill.getSkillById(id))
        .where((skill) => skill != null)
        .cast<Skill>()
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.purple.shade700],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'スキル選択',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // スキルリスト
          Expanded(
            child: learnedSkills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'まだスキルを習得していません',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: learnedSkills.length,
                    itemBuilder: (context, index) {
                      final skill = learnedSkills[index];
                      return _buildSkillCard(skill);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Skill skill) {
    final elementEmoji = _getElementEmoji(skill.element ?? 'normal');
    final elementColor = _getElementColor(skill.element ?? 'normal');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _useSkill(skill);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // スキルアイコン
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: elementColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(elementEmoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // スキル名とタイプ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildSkillTypeBadge(skill.type.name),
                            if (skill.element != null) ...[
                              const SizedBox(width: 8),
                              _buildElementBadge(skill.element!, elementColor),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 威力/効果値
                  if (skill.power > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flash_on,
                              size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            skill.power.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 説明
              Text(
                skill.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillTypeBadge(String type) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case 'attack':
        color = Colors.red;
        icon = Icons.flash_on;
        label = '攻撃';
        break;
      case 'support':
        color = Colors.green;
        icon = Icons.favorite;
        label = '補助';
        break;
      case 'passive':
        color = Colors.purple;
        icon = Icons.shield;
        label = 'パッシブ';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildElementBadge(String element, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        element,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _getElementColor(String element) {
    const colors = {
      'fire': Colors.deepOrange,
      'water': Colors.blue,
      'grass': Colors.green,
      'electric': Colors.yellow,
      'ice': Colors.cyan,
      'dark': Colors.purple,
      'light': Colors.amber,
      'normal': Colors.grey,
    };
    return colors[element] ?? Colors.grey;
  }

  String _getElementEmoji(String? element) {
    if (element == null) return '⚪';

    switch (element.toLowerCase()) {
      case 'fire':
      case '炎':
        return '🔥';
      case 'water':
      case '水':
        return '💧';
      case 'grass':
      case '草':
        return '🌿';
      case 'electric':
      case '雷':
        return '⚡';
      case 'ice':
      case '氷':
        return '❄️';
      case 'dark':
      case '闇':
        return '🌑';
      case 'light':
      case '光':
        return '✨';
      default:
        return '⚪';
    }
  }

  void _useSkill(Skill skill) {
    // スキル使用処理（既存のattack処理を拡張）
    _addLog('${widget.pet.name}は${skill.name}を使った！');

    // スキル習熟度を記録
    _incrementSkillMastery(skill.id);

    // スキルタイプに応じた処理
    if (skill.category == SkillCategory.attack) {
      // 攻撃スキル - 威力を反映
      _petSkillAttack(skill);
    } else if (skill.category == SkillCategory.support) {
      // 補助スキル - 回復・バフ処理
      _useSupportSkill(skill);
    }
  }

  // スキル攻撃（威力反映版）
  Future<void> _petSkillAttack(Skill skill) async {
    if (!_petTurn || _petAttacking) return;

    setState(() => _petAttacking = true);

    // しつけチェック
    if (widget.pet.discipline < 30 && Random().nextInt(100) < 20) {
      _addLog('${widget.pet.name}は言うことを聞かない！');
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      _enemyAttack();
      return;
    }

    // 状態異常チェック
    final canAct = await _processStatus('pet');
    if (!canAct) {
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      _enemyAttack();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();

    // 基礎ダメージ = 攻撃力 × スキル威力倍率
    final skillPowerMultiplier = skill.power / 50.0; // power50が標準倍率1.0
    var baseDamage = (widget.pet.attack * skillPowerMultiplier).round();

    // 装備ボーナス適用
    final equipmentBonus = EquipmentService.getTotalEquipmentBonus(
      widget.pet.equippedWeapon,
      widget.pet.equippedArmor,
      widget.pet.equippedAccessory,
    );
    if (equipmentBonus['attack'] != null) {
      baseDamage = (baseDamage * equipmentBonus['attack']!).round();
    }

    // 性格ボーナス適用
    final personalityBonus =
        PetService.getPersonalityBonus(widget.pet.truePersonality);
    if (personalityBonus['attack'] != null) {
      baseDamage = (baseDamage * personalityBonus['attack']!).round();
    }

    // 火傷状態なら攻撃力半減
    if (_petStatus == 'burn') {
      baseDamage = (baseDamage * 0.5).round();
    }

    final defense = _currentEnemy.defense;
    final defenseFactor = defense / (defense + 100);
    final rawDamage = baseDamage * (1 - defenseFactor);
    int damage =
        (rawDamage + random.nextInt(baseDamage ~/ 5 + 1) - baseDamage ~/ 10)
            .round();
    damage = max(1, damage);

    // タイプ相性（スキル属性 vs 敵属性）
    final skillElement = skill.element ?? 'normal';
    final enemyElement = _currentEnemy.element;
    final typeEffectiveness =
        _calculateTypeEffectiveness(skillElement, enemyElement);

    if (typeEffectiveness > 1.0) {
      damage = (damage * typeEffectiveness).round();
      _addLog('🔥 効果はバツグンだ！');
    } else if (typeEffectiveness < 1.0 && typeEffectiveness > 0) {
      damage = (damage * typeEffectiveness).round();
      _addLog('💧 効果はいまひとつだ...');
    } else if (typeEffectiveness == 0) {
      damage = 0;
      _addLog('⛔ 効果がない...');
    }

    // 天候・時間ボーナス（スキル属性ベース）
    final weatherBonus = WeatherCycleService.getTotalBonus();
    final elementBonus = weatherBonus[skillElement] ?? 1.0;
    if (elementBonus != 1.0) {
      damage = (damage * elementBonus).round();
      if (elementBonus > 1.0) {
        _addLog('🌤️ 天候の恩恵！(×${elementBonus.toStringAsFixed(1)})');
      }
    }

    damage = max(1, damage);

    // クリティカル判定（スキルは20%）
    final isCritical = random.nextInt(100) < 20;
    if (isCritical) {
      damage = (damage * 1.5).round();
      _addLog('⚡ クリティカルヒット！');
      HapticFeedback.heavyImpact();
      _shakeController.repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 400));
      _shakeController.stop();
      _shakeController.reset();
    }

    _currentEnemy.currentHp = max(0, _currentEnemy.currentHp - damage);
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    _addLog('${_currentEnemy.name}に${damage}ダメージ！');

    // スキル固有効果（状態異常付与など）
    if (skill.effects.isNotEmpty) {
      skill.effects.forEach((effect, value) {
        if (effect == 'poison' ||
            effect == 'burn' ||
            effect == 'paralysis' ||
            effect == 'sleep') {
          if (random.nextInt(100) < (value * 100).toInt()) {
            _tryApplyStatus('enemy', effect);
          }
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!_currentEnemy.isAlive) {
      await _victory();
    } else {
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      _enemyAttack();
    }
  }

  // 補助スキル使用
  Future<void> _useSupportSkill(Skill skill) async {
    setState(() => _petAttacking = true);

    await Future.delayed(const Duration(milliseconds: 800));

    // 回復効果
    if (skill.effects.containsKey('heal')) {
      final healAmount = (widget.pet.hp * skill.effects['heal']!).round();
      _petCurrentHp = min(widget.pet.hp, _petCurrentHp + healAmount);
      _addLog('${widget.pet.name}のHPが${healAmount}回復！');
      HapticFeedback.lightImpact();
    }

    // バフ効果（次ターン攻撃力アップなど）
    if (skill.effects.containsKey('buff_attack')) {
      _addLog('${widget.pet.name}の攻撃力が上がった！');
      // TODO: バフ効果の実装（一時的なステータス上昇）
    }

    // 状態異常回復
    if (skill.effects.containsKey('cure')) {
      if (_petStatus != null) {
        _addLog('${widget.pet.name}の${_getStatusName(_petStatus!)}が治った！');
        setState(() => _petStatus = null);
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _petTurn = false;
      _petAttacking = false;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    _enemyAttack();
  }

  // スキルポイント追加
  Future<void> _addSkillPoints(int points) async {
    final pet = await PetService.getPetById(widget.pet.id);
    if (pet == null) return;

    final newSP = pet.skillPoints + points;
    await PetService.updatePet(pet.id, {'skillPoints': newSP});
  }

  // スキル使用回数を記録
  Future<void> _incrementSkillMastery(String skillId) async {
    final pet = await PetService.getPetById(widget.pet.id);
    if (pet == null) return;

    final mastery = Map<String, int>.from(pet.skillMastery);
    mastery[skillId] = (mastery[skillId] ?? 0) + 1;

    await PetService.updatePet(pet.id, {'skillMastery': mastery});

    // マスター判定（20回使用で習熟）
    if (mastery[skillId] == 20) {
      _addLog('💫 ${Skill.getSkillById(skillId)?.name ?? "スキル"}をマスターした！');
    }
  }

  // 新スキル習得チェック（レベルアップ時）
  Future<List<Skill>> _checkNewSkillsLearned(PetModel pet) async {
    final List<Skill> newSkills = [];
    final currentSkillIds = pet.skills.toSet();

    // レベル条件を満たした未習得スキルを検索
    for (final skill in Skill.predefinedSkills) {
      if (skill.requiredLevel <= pet.level &&
          !currentSkillIds.contains(skill.id)) {
        // スキル習得
        await PetService.updatePet(pet.id, {
          'skills': [...pet.skills, skill.id]
        });
        newSkills.add(skill);
        _addLog('🎉 ${skill.name}を習得した！');
      }
    }

    return newSkills;
  }

  Future<void> _triggerComboEffect() async {
    setState(() => _showComboEffect = true);
    _addLog('🌈 ${_comboCount}コンボ！');

    // コンボアニメーション開始
    _comboController.forward(from: 0);

    // 振動フィードバック
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.mediumImpact();

    // 1.5秒後にエフェクト終了
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() => _showComboEffect = false);
    }
  }

  Future<void> _showLevelUpDialog(
      PetModel pet, int oldLevel, List<Skill> newSkills) async {
    final int statGains = (pet.level - oldLevel) * 3;
    final int nextLevelExp = pet.level * 100;

    // レベルアップファンファーレ音（振動で代用）
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.amber.shade100, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン
              const Icon(
                Icons.celebration,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),

              // タイトル
              Text(
                'レベルアップ！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 8),

              // レベル表示
              Text(
                'Lv.$oldLevel → Lv.${pet.level}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // ステータス上昇
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'ステータスアップ！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatUpRow('攻撃力', statGains, Colors.red),
                    const SizedBox(height: 8),
                    _buildStatUpRow('防御力', statGains, Colors.blue),
                    const SizedBox(height: 8),
                    _buildStatUpRow('素早さ', statGains, Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 新スキル習得表示
              if (newSkills.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.purple, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '新スキル習得！',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...newSkills.map((skill) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${_getElementEmoji(skill.element ?? 'normal')} ${skill.name}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 次のレベルまで
              Text(
                '次のレベルまで: ${nextLevelExp - pet.exp}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // ボタン
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatUpRow(String statName, int gain, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          statName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        Row(
          children: [
            Icon(Icons.arrow_upward, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '+$gain',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 敵タイプに応じた素材ドロップ決定
  String _getEnemyDropMaterial(Enemy enemy) {
    // ドラゴン系 → ドラゴン素材
    if (enemy.name.contains('ドラゴン') || enemy.name.contains('竜')) {
      final dragonMats = ['dragon_scale', 'dragon_bone', 'dragon_flame_sac'];
      return dragonMats[Random().nextInt(dragonMats.length)];
    }

    // ゴーレム系・タイタン系 → 鉱石・金属
    if (enemy.name.contains('ゴーレム') || enemy.name.contains('タイタン')) {
      final rockMats = ['iron_ingot', 'ore_rock_fragment', 'rune_stone'];
      return rockMats[Random().nextInt(rockMats.length)];
    }

    // 獣系（ウルフ・ゴブリン） → 獣素材
    if (enemy.name.contains('ウルフ') || enemy.name.contains('ゴブリン')) {
      final beastMats = ['beast_fang', 'beast_claw', 'beast_hide'];
      return beastMats[Random().nextInt(beastMats.length)];
    }

    // フェアリー系・天使系 → 光の欠片
    if (enemy.name.contains('フェアリー') || enemy.name.contains('エンジェル')) {
      return 'ore_light_shard';
    }

    // 闇属性 → 闇の欠片
    if (enemy.element == 'dark' ||
        enemy.name.contains('ダーク') ||
        enemy.name.contains('ゾンビ') ||
        enemy.name.contains('デビル')) {
      return 'ore_dark_shard';
    }

    // エレメンタル系・魔法系 → 魔力核
    if (enemy.name.contains('エレメンタル') || enemy.name.contains('???')) {
      final magicMats = [
        'magic_core_small',
        'magic_core_medium',
        'magic_core_large'
      ];
      return magicMats[Random().nextInt(magicMats.length)];
    }

    // 水属性 → 水の真珠
    if (enemy.element == 'water' || enemy.name.contains('スライム')) {
      return 'ore_water_pearl';
    }

    // 炎属性 → 炎の結晶
    if (enemy.element == 'fire') {
      return 'ore_fire_crystal';
    }

    // 草属性 → 自然の葉石
    if (enemy.element == 'grass') {
      return 'ore_nature_leafstone';
    }

    // デフォルト（共通素材からランダム）
    final commonMats = [
      'wood_plank',
      'iron_ingot',
      'leather_strip',
      'rune_stone'
    ];
    return commonMats[Random().nextInt(commonMats.length)];
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
