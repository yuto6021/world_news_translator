import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/pet.dart';
import '../models/skill.dart';
import '../models/game_item.dart';
import '../services/pet_service.dart';
import '../utils/pet_image_resolver.dart';
import '../services/inventory_service.dart';
import '../services/weather_cycle_service.dart';
import '../services/equipment_service.dart';
import '../services/achievement_service.dart';
import '../services/bestiary_service.dart';
import '../services/quest_service.dart';
import '../services/stage_service.dart';
import '../widgets/animated_reward.dart';
import '../utils/localization_helper.dart';

class BattleScreen extends StatefulWidget {
  final PetModel pet;
  final int initialStage;

  const BattleScreen({super.key, required this.pet, this.initialStage = 1});

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

/// 敵スキルデータ
class EnemySkill {
  final String name;
  final String icon;
  final double damageMultiplier; // 攻撃力に対する倍率
  final String element; // 属性
  final String? statusEffect; // 付与する状態異常

  const EnemySkill({
    required this.name,
    required this.icon,
    required this.damageMultiplier,
    required this.element,
    this.statusEffect,
  });
}

// 敵スキルデータベース（属性別）
final Map<String, List<EnemySkill>> _enemySkillDatabase = {
  'fire': [
    EnemySkill(
      name: '炎の息',
      icon: '🔥',
      damageMultiplier: 1.5,
      element: 'fire',
      statusEffect: 'burn',
    ),
    EnemySkill(
      name: '爆炎波',
      icon: '💥',
      damageMultiplier: 1.8,
      element: 'fire',
    ),
  ],
  'water': [
    EnemySkill(
      name: '水流弾',
      icon: '💧',
      damageMultiplier: 1.4,
      element: 'water',
    ),
    EnemySkill(
      name: '濁流',
      icon: '🌊',
      damageMultiplier: 1.6,
      element: 'water',
    ),
  ],
  'electric': [
    EnemySkill(
      name: '雷撃',
      icon: '⚡',
      damageMultiplier: 1.5,
      element: 'electric',
      statusEffect: 'paralysis',
    ),
    EnemySkill(
      name: '放電',
      icon: '✨',
      damageMultiplier: 1.3,
      element: 'electric',
    ),
  ],
  'grass': [
    EnemySkill(
      name: '毒の粉',
      icon: '🍃',
      damageMultiplier: 1.2,
      element: 'grass',
      statusEffect: 'poison',
    ),
    EnemySkill(
      name: '蔓縛り',
      icon: '🌿',
      damageMultiplier: 1.5,
      element: 'grass',
    ),
  ],
  'dark': [
    EnemySkill(
      name: '闇の波動',
      icon: '🌑',
      damageMultiplier: 1.7,
      element: 'dark',
    ),
    EnemySkill(
      name: '呪縛',
      icon: '💀',
      damageMultiplier: 1.4,
      element: 'dark',
      statusEffect: 'sleep',
    ),
  ],
  'light': [
    EnemySkill(
      name: '聖光',
      icon: '✨',
      damageMultiplier: 1.6,
      element: 'light',
    ),
  ],
  'normal': [
    EnemySkill(
      name: '怒りの一撃',
      icon: '💢',
      damageMultiplier: 1.5,
      element: 'normal',
    ),
  ],
};

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  // ステージ／ウェーブ管理
  int _currentStage = 1;
  int _currentWave = 1;
  int get _wavesPerStage => _currentStage == 25 ? 7 : 3; // Stage 25は7wave
  int _highestClearedStage = 1; // 選択可能最大ステージ
  int _sessionWinStreak = 0; // セッション内連勝数
  late Enemy _currentEnemy;
  late int _petCurrentHp;
  late int _petCurrentMp; // MPシステム
  late int _petMaxMp; // 最大MP
  late AnimationController _shakeController;
  late AnimationController _flashController;
  late AnimationController _comboController;
  late AnimationController _particleController;
  late AnimationController _damageNumberController;
  late AnimationController _victoryController;
  late AnimationController _defeatController;

  bool _battleStarted = false;
  bool _petTurn = true;
  bool _petAttacking = false;
  bool _enemyAttacking = false;
  bool _showComboEffect = false;
  int _comboCount = 0; // 連続攻撃のコンボカウント
  List<String> _logHistory = [];

  // エフェクト管理
  bool _showParticles = false;
  String _particleType = 'none'; // fire, water, electric, grass, dark, light
  Alignment _particlePosition = const Alignment(0.5, -0.2); // パーティクル表示位置
  bool _showVictoryCutIn = false;
  bool _showDefeatCutIn = false;
  List<_DamageNumber> _damageNumbers = [];

  // 状態異常管理
  String? _petStatus; // poison, paralysis, sleep, burn
  int _petStatusTurns = 0; // 状態異常の残りターン数
  String? _enemyStatus;
  int _enemyStatusTurns = 0;

  // 戦闘拡張: 速度・防御・ポップアップ
  double _battleSpeed = 1.0; // x1.0 → x1.5 → x2.0
  bool _isGuarding = false; // 次の被ダメ軽減
  int _toastSeq = 0;
  final List<_BattleToast> _toasts = [];
  int _overdrive = 0; // 必殺ゲージ 0-100

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
    // === 敵専用キャラ ===
    Enemy(
      name: 'ドルモン',
      assetPath: 'assets/enemies/enemy_dorumon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_dorumon_attack.png',
      level: 15,
      maxHp: 180,
      attack: 32,
      defense: 28,
      speed: 22,
      expReward: 55,
      itemDrop: 'beast_fang',
      element: 'normal',
    ),
    Enemy(
      name: 'ドルゴラモン',
      assetPath: 'assets/enemies/enemy_dorugoramon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_dorugoramon_attack.png',
      level: 25,
      maxHp: 350,
      attack: 55,
      defense: 45,
      speed: 28,
      expReward: 120,
      itemDrop: 'dragon_scale',
      element: 'normal',
    ),
    Enemy(
      name: 'ガオモン',
      assetPath: 'assets/enemies/enemy_gaomon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_gaomon_attack.png',
      level: 12,
      maxHp: 140,
      attack: 28,
      defense: 22,
      speed: 26,
      expReward: 45,
      itemDrop: 'beast_claw',
      element: 'normal',
    ),
    Enemy(
      name: 'マッハガオガモン',
      assetPath: 'assets/enemies/enemy_machgaogamon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_machgaogamon_attack.png',
      level: 28,
      maxHp: 400,
      attack: 65,
      defense: 50,
      speed: 45,
      expReward: 150,
      itemDrop: 'thunder_fang',
      element: 'electric',
    ),
    Enemy(
      name: 'ミラージュガオガモン',
      assetPath: 'assets/enemies/enemy_miragegaogamon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_miragegaogamon_attack.png',
      level: 32,
      maxHp: 480,
      attack: 72,
      defense: 65,
      speed: 50,
      expReward: 180,
      itemDrop: 'metal_wing',
      element: 'normal',
    ),
    Enemy(
      name: 'バンチョーレオモン',
      assetPath: 'assets/enemies/enemy_bancholeomon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_bancholeomon_attack.png',
      level: 35,
      maxHp: 550,
      attack: 85,
      defense: 70,
      speed: 40,
      expReward: 220,
      itemDrop: 'beast_hide',
      element: 'normal',
    ),
    Enemy(
      name: 'ファントモン',
      assetPath: 'assets/enemies/enemy_phantomon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_phantomon_attack.png',
      level: 30,
      maxHp: 420,
      attack: 68,
      defense: 55,
      speed: 35,
      expReward: 170,
      itemDrop: 'sinigamicore',
      element: 'dark',
    ),
    Enemy(
      name: 'ピエモン',
      assetPath: 'assets/enemies/enemy_piedmon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_piedmon_attack.png',
      level: 38,
      maxHp: 600,
      attack: 90,
      defense: 75,
      speed: 55,
      expReward: 250,
      itemDrop: 'piero_face',
      element: 'dark',
    ),
    Enemy(
      name: 'ヘラクレスカブテリモン',
      assetPath: 'assets/enemies/enemy_herculeskabuterimon_normal.png',
      attackAssetPath: 'assets/enemies/enemy_herculeskabuterimon_attack.png',
      level: 42,
      maxHp: 700,
      attack: 95,
      defense: 85,
      speed: 48,
      expReward: 280,
      itemDrop: 'golden_horn',
      element: 'electric',
    ),
    // === 属性騎士 ===
    Enemy(
      name: '火の騎士',
      assetPath: 'assets/enemies/enemy_fire_knight_normal.png',
      attackAssetPath: 'assets/enemies/enemy_fire_knight_attack.png',
      level: 35,
      maxHp: 520,
      attack: 78,
      defense: 68,
      speed: 42,
      expReward: 200,
      itemDrop: 'firecore',
      element: 'fire',
    ),
    Enemy(
      name: '水の騎士',
      assetPath: 'assets/enemies/enemy_water_knight_normal.png',
      attackAssetPath: 'assets/enemies/enemy_water_knight_attack.png',
      level: 35,
      maxHp: 520,
      attack: 78,
      defense: 68,
      speed: 42,
      expReward: 200,
      itemDrop: 'watercore',
      element: 'water',
    ),
    Enemy(
      name: '木の騎士',
      assetPath: 'assets/enemies/enemy_wood_knight_normal.png',
      attackAssetPath: 'assets/enemies/enemy_wood_knight_attack.png',
      level: 35,
      maxHp: 520,
      attack: 78,
      defense: 68,
      speed: 42,
      expReward: 200,
      itemDrop: 'woodcore',
      element: 'grass',
    ),
    Enemy(
      name: '雷の騎士',
      assetPath: 'assets/enemies/enemy_thunder_knight_normal.png',
      attackAssetPath: 'assets/enemies/enemy_thunder_knight_attack.png',
      level: 35,
      maxHp: 520,
      attack: 78,
      defense: 68,
      speed: 42,
      expReward: 200,
      itemDrop: 'thundercore',
      element: 'electric',
    ),
    Enemy(
      name: '光の騎士',
      assetPath: 'assets/enemies/enemy_light_knight_normal.png',
      attackAssetPath: 'assets/enemies/enemy_light_knight_attack.png',
      level: 35,
      maxHp: 520,
      attack: 78,
      defense: 68,
      speed: 42,
      expReward: 200,
      itemDrop: 'lightcore',
      element: 'light',
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

  static final Enemy _spiritKing = Enemy(
    name: '精霊王',
    assetPath: 'assets/enemies/secret_boss/enemy_spirit_king_normal.png',
    attackAssetPath: 'assets/enemies/secret_boss/enemy_spirit_king_attack.png',
    level: 95,
    maxHp: 12000,
    attack: 180,
    defense: 120,
    speed: 60,
    type: 'secret_boss',
    expReward: 1500,
    itemDrop: 'kingcore',
    element: 'light',
  );

  @override
  void initState() {
    super.initState();
    _currentStage = widget.initialStage;

    // レベルアップコールバックを設定
    PetService.onLevelUp = (level) {
      if (!mounted) return;
      AnimationHelper.showLevelUp(context, level);
    };

    _petCurrentHp = widget.pet.hp;
    _petMaxMp = widget.pet.level * 5 + 50; // Lv×5+50 (例: Lv1=55, Lv20=150)
    _petCurrentMp = _petMaxMp; // 戦闘開始時は満タンMP
    _selectRandomEnemy();
    _loadStageProgress();

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

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _damageNumberController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _victoryController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _defeatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  Future<void> _loadStageProgress() async {
    _highestClearedStage = await StageService.getHighestClearedStage();
    if (mounted) setState(() {});
  }

  // 背景画像決定（属性・ステージで変化）
  String _getBattleBgImage() {
    final element = _currentEnemy.element;
    switch (element) {
      case 'fire':
        return 'assets/ui/backgrounds/bg_battle_fire.png';
      case 'water':
        return 'assets/ui/backgrounds/bg_battle_ocean.png';
      case 'grass':
        return 'assets/ui/backgrounds/bg_battle_forest.png';
      case 'electric':
        return 'assets/ui/backgrounds/bg_battle_sky.png';
      case 'ice':
        return 'assets/ui/backgrounds/bg_battle_snow.png';
      case 'dark':
        return 'assets/ui/backgrounds/bg_battle_ruins.png';
      default:
        return 'assets/ui/backgrounds/bg_battle_field.png';
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    _comboController.dispose();
    _particleController.dispose();
    _damageNumberController.dispose();
    _victoryController.dispose();
    _defeatController.dispose();
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

  // (D) ダイナミックミニイベント
  void _triggerMiniEvent() {
    final random = Random();
    final events = [
      '🌪️ 強風が吹き荒れている！ 速度-20%',
      '☀️ 灼熱の太陽！ 炎属性+30%',
      '🌧️ 豪雨が降り注ぐ！ 水属性+30%',
      '⚡ 雷雲が立ち込める！ 雷属性+30%',
    ];
    final event = events[random.nextInt(events.length)];
    _addLog('🎲 特殊環境: $event');
    // 実際の効果は既存の天候システムと連携可能（将来拡張）
  }

  void _selectRandomEnemy() {
    final random = Random();
    final petLevel = widget.pet.level;

    // (D) ダイナミックミニイベント（5%確率）
    if (_currentStage >= 3 && random.nextInt(100) < 5) {
      _triggerMiniEvent();
    }

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

    // ステージ別の敵フィルタリング（大幅拡張）
    List<Enemy> stageEnemies;
    if (_currentStage == 1) {
      // Stage 1: 初級（スライム、ゴブリン、ウルフ）
      stageEnemies = _normalEnemies
          .where((e) => ['スライム', 'ゴブリン', 'ウルフ'].contains(e.name))
          .toList();
    } else if (_currentStage == 2) {
      // Stage 2: 中級（ウルフ、ゾンビ、フェアリー）
      stageEnemies = _normalEnemies
          .where((e) => ['ウルフ', 'ゾンビ', 'フェアリー'].contains(e.name))
          .toList();
    } else if (_currentStage == 3) {
      // Stage 3: 上級（エレメンタル、ゴーレム、ドラゴン）
      stageEnemies = _normalEnemies
          .where((e) => ['エレメンタル', 'ゴーレム', 'ドラゴン'].contains(e.name))
          .toList();
    } else if (_currentStage == 4) {
      // Stage 4: 獣系特化（ドルモン、ガオモン、バンチョーレオモン）
      stageEnemies = _normalEnemies
          .where((e) => ['ドルモン', 'ガオモン', 'バンチョーレオモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 5) {
      // Stage 5: 炎系（ドラゴン、火の騎士）
      stageEnemies = _normalEnemies
          .where((e) => ['ドラゴン', '火の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 6) {
      // Stage 6: 水系（スライム、水の騎士）
      stageEnemies = _normalEnemies
          .where((e) => ['スライム', '水の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 7) {
      // Stage 7: 草系（フェアリー、木の騎士）
      stageEnemies = _normalEnemies
          .where((e) => ['フェアリー', '木の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 8) {
      // Stage 8: 雷系（エレメンタル、雷の騎士、ヘラクレスカブテリモン）
      stageEnemies = _normalEnemies
          .where((e) => ['エレメンタル', '雷の騎士', 'ヘラクレスカブテリモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 9) {
      // Stage 9: 光系（フェアリー、光の騎士）
      stageEnemies = _normalEnemies
          .where((e) => ['フェアリー', '光の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 10) {
      // Stage 10: 闇系（ゾンビ、ファントモン、ピエモン）
      stageEnemies = _normalEnemies
          .where((e) => ['ゾンビ', 'ファントモン', 'ピエモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 11) {
      // Stage 11: ドラゴン系特化（ドラゴン、ドルゴラモン）
      stageEnemies = _normalEnemies
          .where((e) => ['ドラゴン', 'ドルゴラモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 12) {
      // Stage 12: 機械系（ガオモン、マッハガオガモン、ミラージュガオガモン）
      stageEnemies = _normalEnemies
          .where((e) => ['ガオモン', 'マッハガオガモン', 'ミラージュガオガモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 13) {
      // Stage 13: 五属性騎士混合
      stageEnemies = _normalEnemies
          .where(
              (e) => ['火の騎士', '水の騎士', '木の騎士', '雷の騎士', '光の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 14) {
      // Stage 14: エリート戦（バンチョーレオモン、ヘラクレスカブテリモン、ピエモン）
      stageEnemies = _normalEnemies
          .where((e) => ['バンチョーレオモン', 'ヘラクレスカブテリモン', 'ピエモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 15) {
      // Stage 15: カオス（全敵ランダム）
      stageEnemies = _normalEnemies;
    } else if (_currentStage == 16) {
      // Stage 16: 魔王の城（ボス系とエリート）
      stageEnemies = _normalEnemies.where((e) => e.level >= 30).toList();
      // 精霊王も50%の確率で出現
      if (random.nextInt(2) == 0 && petLevel >= 50) {
        _currentEnemy = _createScaledEnemy(_spiritKing, petLevel);
        _addLog('⚠️ 精霊王が現れた！');
        return;
      }
    } else if (_currentStage == 17) {
      // Stage 17: 紅蓮の地獄（炎系強化版）
      stageEnemies = _normalEnemies
          .where((e) => ['ドラゴン', '火の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 18) {
      // Stage 18: 深淵の海溝（水系強化版）
      stageEnemies = _normalEnemies
          .where((e) => ['スライム', '水の騎士'].contains(e.name))
          .toList();
    } else if (_currentStage == 19) {
      // Stage 19: 世界樹の頂（草系強化版）
      stageEnemies = _normalEnemies
          .where((e) => ['木の騎士', 'フェアリー'].contains(e.name))
          .toList();
    } else if (_currentStage == 20) {
      // Stage 20: 雷帝の宮殿（雷系強化版）
      stageEnemies = _normalEnemies
          .where((e) => ['雷の騎士', 'ヘラクレスカブテリモン'].contains(e.name))
          .toList();
    } else if (_currentStage == 21) {
      // Stage 21: 聖光の大聖堂（光系強化版）
      stageEnemies = _normalEnemies
          .where((e) => ['光の騎士', 'フェアリー'].contains(e.name))
          .toList();
    } else if (_currentStage == 22) {
      // Stage 22: 虚無の暗黒界（闇系強化版）
      stageEnemies = _normalEnemies
          .where((e) => ['ファントモン', 'ピエモン', 'ゾンビ'].contains(e.name))
          .toList();
    } else if (_currentStage == 23) {
      // Stage 23: 五大騎士の試練（全騎士強化版）
      stageEnemies =
          _normalEnemies.where((e) => e.name.contains('騎士')).toList();
    } else if (_currentStage == 24) {
      // Stage 24: 伝説の覇者たち（エリート全員）
      stageEnemies = _normalEnemies
          .where((e) => [
                'バンチョーレオモン',
                'ヘラクレスカブテリモン',
                'ピエモン',
                'ドルゴラモン',
                'マッハガオガモン',
                'ミラージュガオガモン'
              ].contains(e.name))
          .toList();
    } else if (_currentStage == 25) {
      // Stage 25: 終焉の大決戦（裏ボス確定）
      if (_currentWave <= 5) {
        // Wave 1-5: 最強エリート
        stageEnemies = _normalEnemies.where((e) => e.level >= 35).toList();
      } else if (_currentWave == 6) {
        // Wave 6: 精霊王
        _currentEnemy = _createScaledEnemy(_spiritKing, petLevel);
        _addLog('⚠️ 精霊王が立ちはだかる！');
        return;
      } else {
        // Wave 7: 最強裏ボス
        _currentEnemy = _createScaledEnemy(_secretBoss, petLevel);
        _addLog('💀 最強の裏ボスが現れた！！！');
        return;
      }
    } else {
      // Stage 26+: 最高難度（上位敵のみ）
      stageEnemies = _normalEnemies.where((e) => e.level >= 25).toList();
    }

    // フォールバック: 該当敵がいない場合は全敵から選択
    if (stageEnemies.isEmpty) {
      stageEnemies = _normalEnemies;
    }

    // Stage 17以降は色違い（強化版）を50%の確率で出現
    final bool isShiny = _currentStage >= 17 && random.nextInt(2) == 0;

    // ペットレベルに近い敵を選択
    final suitableEnemies =
        stageEnemies.where((e) => (e.level - petLevel).abs() <= 5).toList();

    final enemy = suitableEnemies.isNotEmpty
        ? suitableEnemies[random.nextInt(suitableEnemies.length)]
        : stageEnemies[random.nextInt(stageEnemies.length)];

    _currentEnemy = _createScaledEnemy(enemy, petLevel, isShiny: isShiny);
    if (isShiny) {
      _addLog('✨ 色違いの強敵が現れた！');
    }
  }

  // 敵をペットレベルに合わせてスケーリング
  Enemy _createScaledEnemy(Enemy baseEnemy, int petLevel,
      {bool isShiny = false}) {
    // 色違いボーナス（全ステータス1.5倍）
    final double shinyBonus = isShiny ? 1.5 : 1.0;

    // (B) ボス難易度ランプ: ステージが進むほどボス強化
    final bossStageBonus =
        (baseEnemy.type == 'boss' || baseEnemy.type == 'secret_boss')
            ? 1.0 + (_currentStage * 0.2)
            : 1.0;
    // StageConfig から敵ステータス倍率取得
    final stageConfig = StageService.getConfig(_currentStage);

    final String displayName =
        isShiny ? '${baseEnemy.name}(強)' : baseEnemy.name;

    if (baseEnemy.type == 'secret_boss') {
      // シークレットボスはさらに強化
      return Enemy(
        name: displayName,
        assetPath: baseEnemy.assetPath,
        attackAssetPath: baseEnemy.attackAssetPath,
        level: (baseEnemy.level *
                bossStageBonus *
                stageConfig.enemyStatMultiplier *
                shinyBonus)
            .round(),
        maxHp: (baseEnemy.maxHp *
                bossStageBonus *
                stageConfig.enemyStatMultiplier *
                shinyBonus)
            .round(),
        attack: (baseEnemy.attack *
                bossStageBonus *
                stageConfig.enemyStatMultiplier *
                shinyBonus)
            .round(),
        defense: (baseEnemy.defense *
                bossStageBonus *
                stageConfig.enemyStatMultiplier *
                shinyBonus)
            .round(),
        speed: (baseEnemy.speed * (1 + _currentStage * 0.05) * shinyBonus)
            .round(), // 速度も上昇
        type: baseEnemy.type,
        expReward: (baseEnemy.expReward *
                bossStageBonus *
                stageConfig.enemyStatMultiplier *
                shinyBonus)
            .round(),
        itemDrop: baseEnemy.itemDrop,
        element: baseEnemy.element,
      );
    }

    // レベル差に応じたスケーリング係数（±30%）
    final levelDiff = petLevel - baseEnemy.level;
    final scaleFactor = (1.0 + (levelDiff * 0.06)) *
        bossStageBonus *
        shinyBonus; // (B) ボスボーナス適用
    final clampedScale = scaleFactor.clamp(0.7, 3.0); // 最小70%、最大300%（色違い考慮）

    final statScale = clampedScale * stageConfig.enemyStatMultiplier;
    return Enemy(
      name: displayName,
      assetPath: baseEnemy.assetPath,
      attackAssetPath: baseEnemy.attackAssetPath,
      level: (baseEnemy.level + levelDiff ~/ 2).clamp(1, 99), // レベルも調整
      maxHp: (baseEnemy.maxHp * statScale).round(),
      attack: (baseEnemy.attack * statScale).round(),
      defense: (baseEnemy.defense * statScale).round(),
      speed: (baseEnemy.speed * shinyBonus).round(), // 色違いは速度も上昇
      type: baseEnemy.type,
      expReward: (baseEnemy.expReward * statScale).round(),
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

  // 速度に追従する待機
  Future<void> _wait(int ms) async {
    final scaled = (ms / _battleSpeed).round();
    await Future.delayed(Duration(milliseconds: scaled));
  }

  // ダメージ/回復ポップ
  void _showDamageToast(String text,
      {required Alignment align, Color color = Colors.white}) {
    final id = _toastSeq++;
    setState(() {
      _toasts.add(_BattleToast(id: id, text: text, align: align, color: color));
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _toasts.removeWhere((t) => t.id == id));
    });
  }

  // 強化されたダメージ数値表示
  void _showEnhancedDamageNumber(
    int damage, {
    bool isCritical = false,
    bool isEnemy = true,
  }) {
    final id = _toastSeq++;
    final screenSize = MediaQuery.of(context).size;

    // 敵または味方の位置に応じて表示位置を決定
    final position = isEnemy
        ? Offset(screenSize.width * 0.5, screenSize.height * 0.3)
        : Offset(screenSize.width * 0.5, screenSize.height * 0.65);

    final color =
        isCritical ? Colors.yellow : (isEnemy ? Colors.red : Colors.blue);

    setState(() {
      _damageNumbers.add(_DamageNumber(
        id: id,
        text: damage.toString(),
        position: position,
        color: color,
        isCritical: isCritical,
      ));
    });

    Future.delayed(Duration(milliseconds: isCritical ? 1500 : 1200), () {
      if (!mounted) return;
      setState(() => _damageNumbers.removeWhere((d) => d.id == id));
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
    // 図鑑・クエスト
    BestiaryService.recordEncounter(
      name: _currentEnemy.name,
      element: _currentEnemy.element,
      type: _currentEnemy.type,
    );
    QuestService.trackAction('battle');

    // 速度比較で先攻決定
    final petSpeed = widget.pet.speed;
    final enemySpeed = _currentEnemy.speed;

    if (petSpeed >= enemySpeed) {
      _addLog('${widget.pet.name}の先攻！');
      _petTurn = true;
    } else {
      _addLog('${_currentEnemy.name}の先攻！');
      _petTurn = false;
      await _wait(1500);
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
      await _wait(1500);
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
      await _wait(1000);
      _enemyAttack();
      return;
    }

    _addLog('${widget.pet.name}の攻撃！');

    await _wait(800);

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
      AchievementService.unlock('elementalist');
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
      await _wait(400);
      _shakeController.stop();
      _shakeController.reset();
    }

    _currentEnemy.currentHp = max(0, _currentEnemy.currentHp - damage);
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    // パーティクルエフェクト表示（敵側に表示）
    setState(() {
      _showParticles = true;
      _particleType = petElement;
      _particlePosition = const Alignment(0.5, -0.2); // 敵側（右）
    });
    _particleController.forward(from: 0);

    // ダメージ数値アニメーション
    _showEnhancedDamageNumber(
      damage,
      isCritical: isCritical,
      isEnemy: true,
    );

    // パーティクルを0.8秒後に非表示
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showParticles = false);
      }
    });

    _addLog('${_currentEnemy.name}に${damage}ダメージ！');
    QuestService.trackAction('deal_damage');
    _showDamageToast('-$damage',
        align: const Alignment(0, -0.2), color: Colors.redAccent);
    _gainOverdrive(12);

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

    await _wait(1000);

    if (!_currentEnemy.isAlive) {
      await _victory();
    } else {
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await _wait(800);
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

    // スキル使用判定（35%の確率）
    final random = Random();
    final useSkill = random.nextInt(100) < 35;
    EnemySkill? selectedSkill;

    if (useSkill) {
      // 敵の属性に応じたスキルをランダム選択
      final skills = _enemySkillDatabase[_currentEnemy.element] ??
          _enemySkillDatabase['normal']!;
      if (skills.isNotEmpty) {
        selectedSkill = skills[random.nextInt(skills.length)];
      }
    }

    if (selectedSkill != null) {
      // スキル攻撃
      _addLog(
          '${_currentEnemy.name}が${selectedSkill.icon}${selectedSkill.name}を使った！');
      if (_currentEnemy.type == 'secret_boss') {
        _secretBossFrameIndex = (_secretBossFrameIndex + 1) % 3;
      }

      await _wait(800);

      var baseDamage =
          (_currentEnemy.attack * selectedSkill.damageMultiplier).round();

      // 火傷状態なら攻撃力半減
      if (_enemyStatus == 'burn') {
        baseDamage = (baseDamage * 0.5).round();
      }

      final defense = widget.pet.defense;
      final defenseFactor = defense / (defense + 100);
      final rawDamage = baseDamage * (1 - defenseFactor);
      int damage =
          (rawDamage + random.nextInt(baseDamage ~/ 5 + 1) - baseDamage ~/ 10)
              .round();
      damage = max(1, damage);

      // 防御時ダメージ軽減
      if (_isGuarding) {
        damage = (damage * 0.6).round();
      }
      _petCurrentHp = max(0, _petCurrentHp - damage);
      _shakeController.forward(from: 0);
      _flashController.forward(from: 0);

      // スキルエフェクト（属性パーティクル＋ダメージ数値）- ペット側に表示
      setState(() {
        _showParticles = true;
        _particleType = selectedSkill!.element;
        _particlePosition = const Alignment(-0.5, -0.2); // ペット側（左）
      });
      _showEnhancedDamageNumber(damage, isEnemy: false, isCritical: false);

      // パーティクルを一定時間後に消す
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showParticles = false);
      });

      _addLog('${widget.pet.name}に${damage}ダメージ！');
      _showDamageToast('-$damage',
          align: const Alignment(0, 0.6), color: Colors.orangeAccent);
      _isGuarding = false;
      _gainOverdrive(8);

      // スキル固有の状態異常付与
      if (selectedSkill.statusEffect != null) {
        _tryApplyStatus('pet', selectedSkill.statusEffect!);
      }
    } else {
      // 通常攻撃
      _addLog('${_currentEnemy.name}の攻撃！');
      if (_currentEnemy.type == 'secret_boss') {
        _secretBossFrameIndex = (_secretBossFrameIndex + 1) % 3;
      }

      await _wait(800);

      var baseDamage = _currentEnemy.attack;

      // 火傷状態なら攻撃力半減
      if (_enemyStatus == 'burn') {
        baseDamage = (baseDamage * 0.5).round();
      }

      final defense = widget.pet.defense;
      final defenseFactor = defense / (defense + 100);
      final rawDamage = baseDamage * (1 - defenseFactor);
      int damage =
          (rawDamage + random.nextInt(baseDamage ~/ 5 + 1) - baseDamage ~/ 10)
              .round();
      damage = max(1, damage);

      // 防御時ダメージ軽減
      if (_isGuarding) {
        damage = (damage * 0.6).round();
      }
      _petCurrentHp = max(0, _petCurrentHp - damage);
      _shakeController.forward(from: 0);
      _flashController.forward(from: 0);

      // 敵攻撃エフェクト（属性パーティクル＋ダメージ数値）- ペット側に表示
      final enemyElement = _currentEnemy.element;
      setState(() {
        _showParticles = true;
        _particleType = enemyElement;
        _particlePosition = const Alignment(-0.5, -0.2); // ペット側（左）
      });
      _showEnhancedDamageNumber(damage, isEnemy: false, isCritical: false);

      // パーティクルを一定時間後に消す
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showParticles = false);
      });

      _addLog('${widget.pet.name}に${damage}ダメージ！');
      _showDamageToast('-$damage',
          align: const Alignment(0, 0.6), color: Colors.orangeAccent);
      _isGuarding = false; // 一度きり
      _gainOverdrive(8);

      // 状態異常付与チェック（敵の属性に応じて）
      if (enemyElement == 'fire') {
        _tryApplyStatus('pet', 'burn');
      } else if (enemyElement == 'electric') {
        _tryApplyStatus('pet', 'paralysis');
      } else if (enemyElement == 'grass') {
        _tryApplyStatus('pet', 'poison');
      }
    }

    await _wait(1000);

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
    // 勝利カットインアニメーション表示
    setState(() => _showVictoryCutIn = true);
    _victoryController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() => _showVictoryCutIn = false);
      _victoryController.reset();
    }

    // (C) 連勝ボーナス更新
    _sessionWinStreak++;
    final streakBonus =
        1.0 + (_sessionWinStreak * 0.1).clamp(0.0, 0.5); // 最大+50%
    // StageConfig を用いた新報酬計算
    final stageConfig = StageService.getConfig(_currentStage);
    final coinRewardBase = _currentEnemy.level * 10 + Random().nextInt(50);
    final waveScaling = 1.0 + (_currentWave - 1) * 0.05; // ウェーブ毎+5%
    int coinReward = (coinRewardBase *
            stageConfig.rewardMultiplier *
            waveScaling *
            streakBonus)
        .round();
    // ボス/シークレット補正
    if (_currentEnemy.type == 'boss') coinReward = (coinReward * 1.5).round();
    if (_currentEnemy.type == 'secret_boss')
      coinReward = (coinReward * 3).round();
    InventoryService.addCoins(coinReward);

    // コイン獲得アニメーション
    if (mounted) {
      AnimationHelper.showCoinGain(context, coinReward);
    }

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
    _addLog('ステージ $_currentStage / ウェーブ $_currentWave クリア');
    if (_sessionWinStreak > 1) {
      _addLog(
          '🔥 ${_sessionWinStreak}連勝! (x${streakBonus.toStringAsFixed(2)} ボーナス)');
    }
    _addLog('経験値+${_currentEnemy.expReward}');
    _addLog(
        'コイン+$coinReward (Stage x${stageConfig.rewardMultiplier.toStringAsFixed(2)} / Wave x${waveScaling.toStringAsFixed(2)})');

    if (_currentEnemy.itemDrop != null) {
      final itemName = LocalizationHelper.getItemName(_currentEnemy.itemDrop!);
      _addLog('アイテム「$itemName」を入手！');
    }

    // データベース更新
    await PetService.incrementWins(widget.pet.id);
    final int oldLevel = widget.pet.level;
    await PetService.addExp(widget.pet.id, _currentEnemy.expReward);
    // 図鑑更新
    BestiaryService.recordDefeat(
      name: _currentEnemy.name,
      element: _currentEnemy.element,
      type: _currentEnemy.type,
    );
    // クエスト連動
    QuestService.trackAction('win');
    QuestService.trackAction('win_total');
    if (_currentEnemy.type == 'boss') {
      QuestService.trackAction('boss_defeat');
    }
    if (_currentEnemy.type == 'secret_boss') {
      QuestService.trackAction('secret_boss_defeat');
    }
    // 実績
    AchievementService.unlock('first_blood');
    if (_currentEnemy.type == 'boss') {
      AchievementService.unlock('boss_slayer');
    }
    if (_currentEnemy.type == 'secret_boss') {
      AchievementService.unlock('secret_victor');
    }

    // スキルポイント獲得（StageConfigのspMultiplier適用）
    int spGained = 1 +
        (_currentEnemy.type == 'boss'
            ? 2
            : _currentEnemy.type == 'secret_boss'
                ? 5
                : 0);
    spGained = (spGained * stageConfig.spMultiplier).round();
    await _addSkillPoints(spGained);
    _addLog(
        'スキルポイント+$spGained (Stage x${stageConfig.spMultiplier.toStringAsFixed(2)})');

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
      final bool specialBoss = _currentEnemy.type == 'secret_boss';
      if (_currentWave < _wavesPerStage && !specialBoss) {
        _currentWave++;
        _selectRandomEnemy();
        setState(() {
          _petTurn = true;
          _petAttacking = false;
          _enemyAttacking = false;
        });
        _addLog('次のウェーブが始まる！ ($_currentWave/$_wavesPerStage)');
      } else {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Text('ステージクリア！'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(specialBoss
                    ? 'スペシャルステージを制覇！'
                    : 'ステージ $_currentStage をクリアしました！'),
                const SizedBox(height: 12),
                Text('経験値: +${_currentEnemy.expReward}'),
                Text('コイン: +$coinReward'),
                Text('スキルポイント: +$spGained'),
                if (_currentEnemy.itemDrop != null)
                  Text('アイテム: ${_currentEnemy.itemDrop}'),
                if (specialBoss)
                  const Text('💎 ボーナス報酬: レア素材 + 高経験値',
                      style: TextStyle(
                          color: Colors.purple, fontWeight: FontWeight.bold)),
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
                  _currentStage++;
                  _currentWave = 1;
                  _selectRandomEnemy();
                },
                child: const Text('続ける'),
              ),
            ],
          ),
        );
        // ステージ遷移後の簡易実績
        final pet = await PetService.getPetById(widget.pet.id);
        if (pet != null && pet.wins >= 5) {
          AchievementService.unlock('unstoppable');
        }
      }
    });
  }

  void _defeat() {
    // 敗北カットインアニメーション表示
    setState(() => _showDefeatCutIn = true);
    _defeatController.forward();

    _addLog('💔 ${widget.pet.name}は倒れた...');
    if (_sessionWinStreak > 0) {
      _addLog('連勝記録: $_sessionWinStreak 途切れた...');
    }
    _sessionWinStreak = 0;

    PetService.incrementLosses(widget.pet.id);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showDefeatCutIn = false);
        _defeatController.reset();

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
          if (!_battleStarted)
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'ステージ選択',
              onPressed: _showStageSelect,
            ),
          if (_battleStarted)
            IconButton(
              icon: const Icon(Icons.directions_run),
              onPressed: _runAway,
              tooltip: '逃げる',
            ),
          IconButton(
            icon: Icon(
              _battleSpeed >= 2.0
                  ? Icons.speed
                  : _battleSpeed >= 1.5
                      ? Icons.speed
                      : Icons.speed_outlined,
            ),
            tooltip: '戦闘速度: x${_battleSpeed.toStringAsFixed(1)}',
            onPressed: () {
              setState(() {
                if (_battleSpeed < 1.5) {
                  _battleSpeed = 1.5;
                } else if (_battleSpeed < 2.0) {
                  _battleSpeed = 2.0;
                } else {
                  _battleSpeed = 1.0;
                }
              });
              _addLog('戦闘速度をx${_battleSpeed.toStringAsFixed(1)}に変更');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBattleBgImage()),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _currentEnemy.type == 'secret_boss'
                ? [const Color(0x801a0033), const Color(0x80330066)]
                : _currentEnemy.type == 'boss'
                    ? [const Color(0x804a0000), const Color(0x802a0000)]
                    : isDark
                        ? [const Color(0x801a1a2e), const Color(0x8016213e)]
                        : [const Color(0x80e8f5e9), const Color(0x80c8e6c9)],
          ),
        ),
        child: Stack(
          children: [
            if (_battleStarted)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: SafeArea(
                  child: _buildBattleHud(),
                ),
              ),
            // 背景の上に薄いブラー/カラーオーバーレイ
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
              ),
            ),

            // バトルログ（右下に移動）
            Positioned(
              right: 16,
              bottom: 180,
              child: Container(
                width: 280,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.article, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'バトルログ',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 8, color: Colors.amber),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _logHistory.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logHistory[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
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
                  ],
                ),
              ),
            ),

            Column(
              children: [
                // 上部のHUDスペース確保（重なり防止）
                if (_battleStarted) const SizedBox(height: 130),

                // ポケモン風横並びバトルエリア
                Expanded(
                  child: Row(
                    children: [
                      // ペットエリア（左側）
                      Expanded(
                        child: _buildPetArea(),
                      ),

                      const SizedBox(width: 16),

                      // 敵エリア（右側）
                      Expanded(
                        child: _buildEnemyArea(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // アクションボタン
                if (_battleStarted) _buildActionButtons() else _buildStartCTA(),
              ],
            ),

            // コンボエフェクトオーバーレイ
            if (_showComboEffect) _buildComboOverlay(),

            // パーティクルエフェクト（攻撃対象側に表示）
            if (_showParticles)
              _ParticleEffect(
                type: _particleType,
                position: _particlePosition,
              ),

            // ダメージ数値アニメーション
            ..._damageNumbers.map((dmg) => _AnimatedDamageNumber(
                  text: dmg.text,
                  position: dmg.position,
                  color: dmg.color,
                  isCritical: dmg.isCritical,
                )),

            // ダメージトースト
            _buildToastsOverlay(),

            // 勝利カットイン
            if (_showVictoryCutIn) _buildVictoryCutIn(),

            // 敗北カットイン
            if (_showDefeatCutIn) _buildDefeatCutIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCTA() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ElevatedButton.icon(
        onPressed: _startBattle,
        icon: const Icon(Icons.flash_on),
        label: const Text('バトル開始'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
      ),
    );
  }

  void _showStageSelect() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxSelectable = (_highestClearedStage + 1).clamp(1, 10);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.blueAccent]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('ステージ選択',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.05,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: maxSelectable,
                  itemBuilder: (c, i) {
                    final stageNumber = i + 1;
                    final unlocked = stageNumber <= maxSelectable;
                    final selected = stageNumber == _currentStage;
                    final config = StageService.getConfig(stageNumber);
                    return GestureDetector(
                      onTap: unlocked
                          ? () {
                              setState(() {
                                _currentStage = stageNumber;
                                _currentWave = 1;
                                _selectRandomEnemy();
                              });
                              Navigator.pop(ctx);
                              _addLog(
                                  'ステージ $stageNumber を選択 (報酬x${config.rewardMultiplier.toStringAsFixed(2)})');
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected ? Colors.amber : Colors.grey.shade400,
                            width: selected ? 3 : 1.5,
                          ),
                          color: unlocked
                              ? (selected
                                  ? Colors.amber.withOpacity(0.15)
                                  : Colors.blueGrey.withOpacity(0.12))
                              : Colors.grey.withOpacity(0.25),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Stage $stageNumber',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: unlocked
                                        ? Colors.white
                                        : Colors.white54)),
                            const SizedBox(height: 6),
                            Text(
                                '報酬 x${config.rewardMultiplier.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white70)),
                            Text(
                                '敵 x${config.enemyStatMultiplier.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white54)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // バトルHUD（ステージ/ウェーブ/敵種別/コンボ/装備）
  Widget _buildBattleHud() {
    final bossLabel = _currentEnemy.type == 'secret_boss'
        ? 'SECRET BOSS'
        : _currentEnemy.type == 'boss'
            ? 'BOSS'
            : 'ENEMY';
    final bossColor = _currentEnemy.type == 'secret_boss'
        ? Colors.purple
        : _currentEnemy.type == 'boss'
            ? Colors.red
            : Colors.grey.shade700;

    final weapon = widget.pet.equippedWeapon ?? 'なし';
    final armor = widget.pet.equippedArmor ?? 'なし';
    final accessory = widget.pet.equippedAccessory ?? 'なし';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: Colors.amber.shade400, size: 18),
              const SizedBox(width: 6),
              Text(
                'Stage '
                '$_currentStage  Wave '
                '$_currentWave/$_wavesPerStage',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bossColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bossColor.withOpacity(0.7)),
                ),
                child: Text(
                  bossLabel,
                  style: TextStyle(
                    color: bossColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.cyan.shade300, size: 18),
              const SizedBox(width: 6),
              Text(
                'Combo: $_comboCount',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              // Overdriveゲージ
              Container(
                width: 150,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _overdrive / 100.0,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade700,
                          color:
                              _overdrive >= 100 ? Colors.amber : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${_overdrive}%',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _buildEquipBadge(Icons.construction, weapon),
                  const SizedBox(width: 4),
                  _buildEquipBadge(Icons.shield, armor),
                  const SizedBox(width: 4),
                  _buildEquipBadge(Icons.star, accessory),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (E) 装備効果HUD: 補正値表示
  Widget _buildEquipBadge(IconData icon, String? equipId) {
    String displayText = 'なし';
    if (equipId != null && equipId.isNotEmpty) {
      // 装備名を短縮表示
      displayText = equipId.length > 6 ? equipId.substring(0, 6) : equipId;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.amber.shade300),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
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

  Widget _buildVictoryCutIn() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _victoryController,
        builder: (context, child) {
          final progress = _victoryController.value;
          final slideProgress =
              Curves.easeOutCubic.transform(progress.clamp(0.0, 0.5) * 2);
          final fadeProgress =
              progress < 0.5 ? progress * 2 : (1 - progress) * 2;

          return Stack(
            children: [
              // 背景フラッシュ
              Container(
                color: Colors.amber.withOpacity(0.3 * fadeProgress),
              ),
              // カットイン
              Positioned(
                left: -MediaQuery.of(context).size.width * (1 - slideProgress),
                top: 0,
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.9),
                        Colors.orange.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 120,
                          color: Colors.white.withOpacity(fadeProgress),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'VICTORY!',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(fadeProgress),
                            letterSpacing: 8,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(fadeProgress),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDefeatCutIn() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _defeatController,
        builder: (context, child) {
          final progress = _defeatController.value;
          final slideProgress =
              Curves.easeOutCubic.transform(progress.clamp(0.0, 0.5) * 2);
          final fadeProgress =
              progress < 0.5 ? progress * 2 : (1 - progress) * 2;

          return Stack(
            children: [
              // 背景ダーク化
              Container(
                color: Colors.black.withOpacity(0.5 * fadeProgress),
              ),
              // カットイン
              Positioned(
                right: -MediaQuery.of(context).size.width * (1 - slideProgress),
                top: 0,
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade800.withOpacity(0.95),
                        Colors.black.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sentiment_very_dissatisfied,
                          size: 120,
                          color: Colors.red.withOpacity(fadeProgress),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'DEFEAT...',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.withOpacity(fadeProgress),
                            letterSpacing: 8,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(fadeProgress),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ダメージ/回復のフローティングトースト
  Widget _buildToastsOverlay() {
    if (_toasts.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        children: _toasts
            .map((t) =>
                _FloatingToast(text: t.text, align: t.align, color: t.color))
            .toList(),
      ),
    );
  }

  Widget _buildEnemyArea() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset =
            _enemyAttacking ? 0.0 : sin(_shakeController.value * pi * 4) * 18;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 敵ステータス（コンパクト版）
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                elevation: 2,
                color: _currentEnemy.type == 'secret_boss'
                    ? Colors.purple.withOpacity(0.3)
                    : _currentEnemy.type == 'boss'
                        ? Colors.red.withOpacity(0.3)
                        : Colors.black.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentEnemy.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _currentEnemy.type == 'secret_boss'
                                  ? Colors.purple[200]
                                  : _currentEnemy.type == 'boss'
                                      ? Colors.red[200]
                                      : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lv.${_currentEnemy.level}',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getElementIcon(_currentEnemy.element),
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_enemyStatus != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              _getStatusIcon(_enemyStatus!),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _currentEnemy.hpPercent,
                                minHeight: 10,
                                backgroundColor: Colors.grey[700],
                                color: _currentEnemy.hpPercent > 0.5
                                    ? Colors.green
                                    : _currentEnemy.hpPercent > 0.25
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_currentEnemy.currentHp}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 敵画像
              Expanded(
                child: AnimatedBuilder(
                  animation: _flashController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _enemyAttacking
                          ? 1.0
                          : 1.0 - (_flashController.value * 0.15),
                      child: Image.asset(
                        _enemyAttacking
                            ? (_currentEnemy.type == 'secret_boss'
                                ? _secretBossAttackFrame()
                                : _currentEnemy.attackAssetPath)
                            : _currentEnemy.assetPath,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.error,
                            size: 100,
                            color: Colors.red[300],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetArea() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset =
            _petAttacking ? 0.0 : sin(_shakeController.value * pi * 4) * 18;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ペット画像
              Expanded(
                child: AnimatedBuilder(
                  animation: _flashController,
                  builder: (context, child) {
                    final desiredState = _petAttacking ? 'battle' : 'normal';
                    final petImage = PetImageResolver.resolveFlexible(
                      widget.pet.stage,
                      widget.pet.species,
                      desiredState,
                    );
                    return Opacity(
                      opacity: _petAttacking
                          ? 1.0
                          : 1.0 - (_flashController.value * 0.15),
                      child: Image.asset(
                        petImage,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.pets,
                              size: 100, color: Colors.grey);
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ペットステータス（コンパクト版）
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                elevation: 2,
                color: Colors.blue.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.pet.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lv.${widget.pet.level}',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getElementIcon(_getPetElement(widget.pet.species)),
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_petStatus != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              _getStatusIcon(_petStatus!),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _petCurrentHp / widget.pet.hp,
                                minHeight: 10,
                                backgroundColor: Colors.grey[700],
                                color: _petCurrentHp / widget.pet.hp > 0.5
                                    ? Colors.green
                                    : _petCurrentHp / widget.pet.hp > 0.25
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_petCurrentHp',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _petCurrentMp / _petMaxMp,
                                minHeight: 8,
                                backgroundColor: Colors.grey[700],
                                color: _petCurrentMp / _petMaxMp > 0.5
                                    ? Colors.blue
                                    : _petCurrentMp / _petMaxMp > 0.25
                                        ? Colors.lightBlue
                                        : Colors.blueGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_petCurrentMp/$_petMaxMp',
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
            top: BorderSide(color: Colors.amber.withOpacity(0.3), width: 2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _petTurn && !_petAttacking ? _petAttack : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, size: 24),
                      SizedBox(width: 8),
                      Text('攻撃',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _petTurn && !_petAttacking ? _showSkillMenu : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 24),
                      SizedBox(width: 8),
                      Text('スキル',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _petTurn && !_petAttacking ? _guard : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, size: 24),
                      SizedBox(width: 8),
                      Text('防御',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _petTurn && !_petAttacking ? _showItemMenu : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.backpack, size: 22),
                      SizedBox(width: 8),
                      Text('アイテム',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _petTurn && !_petAttacking && _overdrive >= 100
                      ? _overdriveBurst
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department, size: 22),
                      SizedBox(width: 8),
                      Text('必殺',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _gainOverdrive(int amount) {
    setState(() {
      _overdrive = (_overdrive + amount).clamp(0, 100);
    });
    if (_overdrive >= 100) {
      _addLog('🔥 必殺技が使用可能になった！');
    }
  }

  Future<void> _overdriveBurst() async {
    if (!_petTurn || _petAttacking || _overdrive < 100) return;
    setState(() => _petAttacking = true);
    _addLog('🔥 ${widget.pet.name}の必殺！');
    await _wait(600);

    final random = Random();
    final base = (widget.pet.attack * 2.5).round();
    final defense = (_currentEnemy.defense * 0.5).round();
    final defenseFactor = defense / (defense + 100);
    int damage =
        (base * (1 - defenseFactor) + random.nextInt(base ~/ 6 + 1)).round();

    final petElement = _getPetElement(widget.pet.species);
    final enemyElement = _currentEnemy.element;
    final eff = _calculateTypeEffectiveness(petElement, enemyElement);
    damage = (damage * eff).round();

    damage = max(5, damage);
    _currentEnemy.currentHp = max(0, _currentEnemy.currentHp - damage);
    _showDamageToast('-$damage',
        align: const Alignment(0, -0.2), color: Colors.deepOrangeAccent);

    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    _flashController.forward(from: 0);

    // 必殺技エフェクト（敵側に表示）
    setState(() {
      _showParticles = true;
      _particleType = petElement;
      _particlePosition = const Alignment(0.5, -0.2); // 敵側（右）
      _overdrive = 0;
    });
    _showEnhancedDamageNumber(damage, isEnemy: true, isCritical: true);

    // パーティクルを一定時間後に消す
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showParticles = false);
    });

    await _wait(800);
    if (!_currentEnemy.isAlive) {
      await _victory();
    } else {
      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await _wait(600);
      _enemyAttack();
    }
  }

  void _guard() async {
    setState(() {
      _isGuarding = true;
      _petTurn = false;
    });
    _addLog('🛡️ ${widget.pet.name}は身を固めた！(次の被ダメ軽減)');
    await _wait(600);
    _enemyAttack();
  }

  void _showSkillMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSkillMenuSheet(),
    );
  }

  void _showItemMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemMenuSheet(),
    );
  }

  Widget _buildItemMenuSheet() {
    return FutureBuilder<List<MapEntry<GameItem, int>>>(
      future: InventoryService.getItemsByCategory('consumable'),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final usable = items.where((e) => e.value > 0).toList(growable: false);
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.orange.shade700],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.backpack, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('アイテム',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: usable.isEmpty
                    ? Center(
                        child: Text('使用可能なアイテムがありません',
                            style: TextStyle(color: Colors.grey.shade600)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: usable.length,
                        itemBuilder: (context, i) {
                          final entry = usable[i];
                          final item = entry.key;
                          final count = entry.value;
                          return Card(
                            child: ListTile(
                              leading: Image.asset(item.imagePath,
                                  width: 36,
                                  height: 36,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.inventory)),
                              title: Text(item.name),
                              subtitle: Text('${item.description}  x$count'),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _useBattleItem(item);
                                },
                                child: const Text('使う'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _useBattleItem(GameItem item) async {
    switch (item.effect) {
      case 'stamina_full':
        final healed = widget.pet.hp - _petCurrentHp;
        _petCurrentHp = widget.pet.hp;
        _addLog('🧃 ${widget.pet.name}のHPが全回復！');
        _showDamageToast('+$healed',
            align: const Alignment(0, 0.55), color: Colors.lightGreenAccent);
        await InventoryService.removeItem(item.id);
        break;
      case 'revive':
        if (_petCurrentHp <= 0) {
          _petCurrentHp = (widget.pet.hp * 0.5).round();
          _addLog('💖 ${widget.pet.name}は復活した！');
          _showDamageToast('+${_petCurrentHp}',
              align: const Alignment(0, 0.55), color: Colors.lightGreenAccent);
          await InventoryService.removeItem(item.id);
        } else {
          _addLog('復活の薬は今は使えない…');
        }
        break;
      case 'medicine':
        if (_petStatus != null) {
          _addLog('🩺 ${widget.pet.name}の${_getStatusName(_petStatus!)}が治った！');
          setState(() => _petStatus = null);
          await InventoryService.removeItem(item.id);
        } else {
          _addLog('治す状態異常がない…');
        }
        break;
      default:
        _addLog('このアイテムは戦闘では使えないようだ…');
        return;
    }

    setState(() => _petTurn = false);
    await _wait(600);
    _enemyAttack();
  }

  Widget _buildSkillMenuSheet() {
    return FutureBuilder<PetModel?>(
      future: PetService.getPetById(widget.pet.id),
      builder: (context, snapshot) {
        final pet = snapshot.data ?? widget.pet;
        final learnedSkillIds = pet.skills;
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
                    const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 28),
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
      },
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
    // MPチェック
    final manaCost = skill.manaCost ?? 0;
    if (_petCurrentMp < manaCost) {
      _addLog('⚠️ MPが足りない！');
      return;
    }

    // MP消費
    setState(() {
      _petCurrentMp = max(0, _petCurrentMp - manaCost);
    });

    // スキル使用処理（既存のattack処理を拡張）
    _addLog('${widget.pet.name}は${skill.name}を使った！(-${manaCost}MP)');

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
      await _wait(800);
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

    await _wait(800);

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
      // 最高クリア更新
      StageService.saveHighestClearedStage(_currentStage);
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
      // 遷移後に再読込（新しい最大ステージが解放された可能性）
      _loadStageProgress();
    }

    damage = max(1, damage);

    // 連続攻撃判定（hits効果）
    final int hitCount = skill.effects['hits']?.toInt() ?? 1;
    int totalDamage = 0;

    for (int i = 0; i < hitCount; i++) {
      // 各ヒットでダメージを再計算（ランダム幅を持たせる）
      int hitBaseDamage =
          baseDamage + random.nextInt(baseDamage ~/ 5 + 1) - baseDamage ~/ 10;
      hitBaseDamage = (hitBaseDamage * typeEffectiveness).round();
      hitBaseDamage = (hitBaseDamage * elementBonus).round();
      hitBaseDamage = max(1, hitBaseDamage);

      int hitDamage = hitBaseDamage;

      // クリティカル判定（スキルは各ヒット20%）
      final isCritical = random.nextInt(100) < 20;
      if (isCritical) {
        hitDamage = (hitDamage * 1.5).round();
        _addLog('⚡ クリティカルヒット！');
        HapticFeedback.heavyImpact();
      }

      totalDamage += hitDamage;
      _currentEnemy.currentHp = max(0, _currentEnemy.currentHp - hitDamage);

      _shakeController.forward(from: 0);
      _flashController.forward(from: 0);

      _addLog('HIT ${i + 1}! ${hitDamage}ダメージ！');
      _showDamageToast('-$hitDamage',
          align: const Alignment(0, -0.2), color: Colors.redAccent);

      // 各ヒット間に短い間隔
      if (i < hitCount - 1) {
        await _wait(300);
        if (!_currentEnemy.isAlive) break;
      }
    }

    // 最後に演出リセット
    if (hitCount > 1) {
      _shakeController.repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 400));
      _shakeController.stop();
      _shakeController.reset();
    }

    // スキル発動エフェクト（属性パーティクル＋ダメージ数値）- 敵側に表示
    setState(() {
      _showParticles = true;
      _particleType = skillElement;
      _particlePosition = const Alignment(0.5, -0.2); // 敵側（右）
    });
    _showEnhancedDamageNumber(totalDamage, isEnemy: true, isCritical: false);

    // パーティクルを一定時間後に消す
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showParticles = false);
    });

    if (hitCount > 1) {
      _addLog('${_currentEnemy.name}に合計${totalDamage}ダメージ！($hitCount HIT)');
    } else {
      _addLog('${_currentEnemy.name}に${totalDamage}ダメージ！');
    }
    _gainOverdrive(12 * hitCount);

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

    await _wait(1000);

    if (!_currentEnemy.isAlive) {
      await _victory();
    } else {
      // ターン終了時にMP回復（最大MPの10%）
      final int mpRecover = (_petMaxMp * 0.1).round();
      _petCurrentMp = min(_petMaxMp, _petCurrentMp + mpRecover);
      if (mpRecover > 0) {
        _addLog('💙 MP ${mpRecover}回復！');
      }

      setState(() {
        _petTurn = false;
        _petAttacking = false;
      });
      await _wait(800);
      _enemyAttack();
    }
  }

  // 補助スキル使用
  Future<void> _useSupportSkill(Skill skill) async {
    setState(() => _petAttacking = true);

    await _wait(800);

    // 回復効果
    if (skill.effects.containsKey('heal')) {
      final healAmount = (widget.pet.hp * skill.effects['heal']!).round();
      _petCurrentHp = min(widget.pet.hp, _petCurrentHp + healAmount);
      _addLog('${widget.pet.name}のHPが${healAmount}回復！');
      _showDamageToast('+$healAmount',
          align: const Alignment(0, 0.55), color: Colors.lightGreenAccent);
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

    await _wait(1000);

    // ターン終了時にMP回復（最大MPの10%）
    final int mpRecover = (_petMaxMp * 0.1).round();
    _petCurrentMp = min(_petMaxMp, _petCurrentMp + mpRecover);
    if (mpRecover > 0) {
      _addLog('💙 MP ${mpRecover}回復！');
    }

    setState(() {
      _petTurn = false;
      _petAttacking = false;
    });
    await _wait(800);
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
    setState(() {
      _showComboEffect = true;
      // コンボ時は虹色エフェクト（light属性）
      _showParticles = true;
      _particleType = 'light';
    });
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
      setState(() {
        _showComboEffect = false;
        _showParticles = false;
      });
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

class _BattleToast {
  final int id;
  final String text;
  final Alignment align;
  final Color color;
  _BattleToast(
      {required this.id,
      required this.text,
      required this.align,
      required this.color});
}

class _FloatingToast extends StatefulWidget {
  final String text;
  final Alignment align;
  final Color color;
  const _FloatingToast(
      {required this.text, required this.align, required this.color});

  @override
  State<_FloatingToast> createState() => _FloatingToastState();
}

class _FloatingToastState extends State<_FloatingToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0)),
    );
    _offset = Tween(begin: const Offset(0, 0), end: const Offset(0, -0.5))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.align,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.color,
              shadows: const [
                Shadow(
                    color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ダメージ数値クラス
class _DamageNumber {
  final int id;
  final String text;
  final Offset position;
  final Color color;
  final bool isCritical;

  _DamageNumber({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    this.isCritical = false,
  });
}

// アニメーション付きダメージ数値ウィジェット
class _AnimatedDamageNumber extends StatefulWidget {
  final String text;
  final Offset position;
  final Color color;
  final bool isCritical;

  const _AnimatedDamageNumber({
    required this.text,
    required this.position,
    required this.color,
    this.isCritical = false,
  });

  @override
  State<_AnimatedDamageNumber> createState() => _AnimatedDamageNumberState();
}

class _AnimatedDamageNumberState extends State<_AnimatedDamageNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.isCritical ? 1500 : 1200),
      vsync: this,
    )..forward();

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: widget.isCritical ? 1.5 : 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
          tween: Tween(begin: widget.isCritical ? 1.5 : 1.2, end: 1.0),
          weight: 70),
    ]).animate(_controller);

    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, widget.isCritical ? -1.5 : -1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.isCritical ? 48 : 36,
                fontWeight: FontWeight.bold,
                color: widget.color,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  if (widget.isCritical)
                    Shadow(
                      color: widget.color,
                      offset: Offset.zero,
                      blurRadius: 12,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// パーティクルエフェクトウィジェット
class _ParticleEffect extends StatefulWidget {
  final String type; // fire, water, electric, grass, dark, light
  final Alignment position;

  const _ParticleEffect({
    required this.type,
    this.position = Alignment.center,
  });

  @override
  State<_ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<_ParticleEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    // パーティクル生成
    _generateParticles();
  }

  void _generateParticles() {
    // パーティクル数を大幅増加（2層構造）
    final particleCount = widget.type == 'electric' ? 35 : 40;
    for (int i = 0; i < particleCount; i++) {
      // 内側と外側の2層
      final isInnerLayer = i < particleCount * 0.4;
      _particles.add(_Particle(
        type: widget.type,
        angle: _random.nextDouble() * 2 * pi,
        distance: isInnerLayer
            ? 30 + _random.nextDouble() * 50 // 内側層：30-80
            : 60 + _random.nextDouble() * 90, // 外側層：60-150
        size: widget.type == 'electric'
            ? (isInnerLayer ? 4 : 5) + _random.nextDouble() * 3
            : (isInnerLayer ? 5 : 6) + _random.nextDouble() * 4,
        delay: _random.nextDouble() * 0.25,
        isInner: isInnerLayer,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getParticleColor(String type) {
    switch (type) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.yellow;
      case 'grass':
        return Colors.green;
      case 'dark':
        return Colors.purple;
      case 'light':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.position,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 300, // エリアを拡大
            height: 300,
            child: Stack(
              children: [
                // 背景爆発エフェクト（最初0.2秒間のみ）
                if (_controller.value < 0.2)
                  Positioned.fill(
                    child: Opacity(
                      opacity: (1 - _controller.value / 0.2).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _getParticleColor(widget.type).withOpacity(0.8),
                              _getParticleColor(widget.type).withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                // パーティクル渦巻き
                ..._particles.map((particle) {
                  final progress = ((_controller.value - particle.delay) /
                          (1 - particle.delay))
                      .clamp(0.0, 1.0);
                  final opacity = (1 - progress).clamp(0.0, 1.0);

                  // 渦巻き軌道: 内側層は3回転、外側層は2.5回転
                  final double turns = particle.isInner ? 3.0 : 2.5;
                  final double radius = particle.distance * progress;
                  final double theta =
                      particle.angle + progress * turns * 2 * pi;

                  final dx = cos(theta) * radius;
                  final dy = sin(theta) * radius;

                  return Positioned(
                    left: 150 + dx,
                    top: 150 + dy,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          color: _getParticleColor(widget.type),
                          shape: widget.type == 'electric'
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getParticleColor(widget.type),
                              blurRadius: particle.size * 8, // グロー強化
                              spreadRadius: particle.size * 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final String type;
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final bool isInner; // 内側層/外側層

  _Particle({
    required this.type,
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    this.isInner = false,
  });
}
