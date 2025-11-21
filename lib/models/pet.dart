import 'package:hive/hive.dart';

part 'pet.g.dart';

@HiveType(typeId: 4)
class PetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String species; // "greymon", "garurumon", "angemon", "devimon"等

  @HiveField(3)
  String stage; // "egg", "baby", "child", "adult", "ultimate"

  // ステータス
  @HiveField(4)
  int level;

  @HiveField(5)
  int exp;

  @HiveField(6)
  int hp; // 体力ゲージ（0-100）

  @HiveField(7)
  int hunger; // お腹ゲージ（0-100）

  @HiveField(8)
  int mood; // 機嫌ゲージ（0-100）

  @HiveField(9)
  int dirty; // 汚れゲージ（0-100）

  @HiveField(10)
  int stamina; // 体力ゲージ（0-100）

  @HiveField(11)
  int intimacy; // 親密度（0-100）

  // ジャンル別経験値（5次元）
  @HiveField(12)
  Map<String, int>
      genreStats; // {"business": 50, "tech": 30, "entertainment": 40, "sports": 20, "politics": 60}

  // 生命サイクル
  @HiveField(13)
  DateTime birthDate;

  @HiveField(14)
  DateTime lastFed;

  @HiveField(15)
  DateTime lastPlayed;

  @HiveField(16)
  DateTime lastCleaned;

  @HiveField(17)
  int age; // 日数

  @HiveField(18)
  bool isAlive;

  @HiveField(19)
  bool isSick;

  @HiveField(20)
  String? sickness; // "cold", "stomachache", "fatigue"

  // スキル（最大3つ）
  @HiveField(21)
  List<String> skills;

  // バトルステータス
  @HiveField(22)
  int attack;

  @HiveField(23)
  int defense;

  @HiveField(24)
  int speed;

  @HiveField(25)
  int wins;

  @HiveField(26)
  int losses;

  // その他
  @HiveField(27)
  int playCount;

  @HiveField(28)
  int cleanCount;

  @HiveField(29)
  int battleCount;

  @HiveField(30)
  Map<String, dynamic> evolutionProgress; // 進化条件進捗

  @HiveField(31)
  bool isActive; // 現在メインで育成中か

  @HiveField(32)
  DateTime? lastHealthCheck; // 最終健康チェック時刻

  @HiveField(33)
  String personality; // "genki", "shy", "warrior", "beast", "angel", "demon"

  PetModel({
    required this.id,
    required this.name,
    required this.species,
    required this.stage,
    required this.level,
    required this.exp,
    required this.hp,
    required this.hunger,
    required this.mood,
    required this.dirty,
    required this.stamina,
    required this.intimacy,
    required this.genreStats,
    required this.birthDate,
    required this.lastFed,
    required this.lastPlayed,
    required this.lastCleaned,
    required this.age,
    required this.isAlive,
    required this.isSick,
    this.sickness,
    required this.skills,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.wins,
    required this.losses,
    required this.playCount,
    required this.cleanCount,
    required this.battleCount,
    required this.evolutionProgress,
    required this.isActive,
    this.lastHealthCheck,
    required this.personality,
  });

  // ファクトリーコンストラクタ: 新しいたまごを作成
  factory PetModel.createEgg(String name) {
    final now = DateTime.now();
    return PetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      species: 'egg',
      stage: 'egg',
      level: 0,
      exp: 0,
      hp: 100,
      hunger: 100,
      mood: 100,
      dirty: 0,
      stamina: 100,
      intimacy: 0,
      genreStats: {
        'business': 0,
        'tech': 0,
        'entertainment': 0,
        'sports': 0,
        'politics': 0,
      },
      birthDate: now,
      lastFed: now,
      lastPlayed: now,
      lastCleaned: now,
      age: 0,
      isAlive: true,
      isSick: false,
      sickness: null,
      skills: [],
      attack: 10,
      defense: 10,
      speed: 10,
      wins: 0,
      losses: 0,
      playCount: 0,
      cleanCount: 0,
      battleCount: 0,
      evolutionProgress: {},
      isActive: true,
      lastHealthCheck: now,
      personality: 'neutral',
    );
  }

  // 親密度レベル取得（5段階）
  String get intimacyLevel {
    if (intimacy >= 81) return '運命の仲間';
    if (intimacy >= 61) return '相棒';
    if (intimacy >= 41) return '親友';
    if (intimacy >= 21) return '友達';
    return '知人';
  }

  // 健康状態取得
  String get healthStatus {
    if (isSick) return '病気';
    if (hunger < 20) return '空腹危険';
    if (mood < 20) return '不機嫌';
    if (dirty > 80) return '不衛生';
    if (stamina < 20) return '疲労';
    if (hunger < 50 || mood < 50) return '普通';
    return '元気';
  }

  // 経験値から次レベルまでの必要経験値
  int get expToNextLevel => level * 100 + 50;

  // レベルアップ判定
  bool canLevelUp() => exp >= expToNextLevel;

  // JSONシリアライズ（Hiveに加えてSharedPreferences等でも使用可能）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'stage': stage,
      'level': level,
      'exp': exp,
      'hp': hp,
      'hunger': hunger,
      'mood': mood,
      'dirty': dirty,
      'stamina': stamina,
      'intimacy': intimacy,
      'genreStats': genreStats,
      'birthDate': birthDate.toIso8601String(),
      'lastFed': lastFed.toIso8601String(),
      'lastPlayed': lastPlayed.toIso8601String(),
      'lastCleaned': lastCleaned.toIso8601String(),
      'age': age,
      'isAlive': isAlive,
      'isSick': isSick,
      'sickness': sickness,
      'skills': skills,
      'attack': attack,
      'defense': defense,
      'speed': speed,
      'wins': wins,
      'losses': losses,
      'playCount': playCount,
      'cleanCount': cleanCount,
      'battleCount': battleCount,
      'evolutionProgress': evolutionProgress,
      'isActive': isActive,
      'lastHealthCheck': lastHealthCheck?.toIso8601String(),
      'personality': personality,
    };
  }

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      stage: json['stage'],
      level: json['level'],
      exp: json['exp'],
      hp: json['hp'],
      hunger: json['hunger'],
      mood: json['mood'],
      dirty: json['dirty'],
      stamina: json['stamina'],
      intimacy: json['intimacy'],
      genreStats: Map<String, int>.from(json['genreStats']),
      birthDate: DateTime.parse(json['birthDate']),
      lastFed: DateTime.parse(json['lastFed']),
      lastPlayed: DateTime.parse(json['lastPlayed']),
      lastCleaned: DateTime.parse(json['lastCleaned']),
      age: json['age'],
      isAlive: json['isAlive'],
      isSick: json['isSick'],
      sickness: json['sickness'],
      skills: List<String>.from(json['skills']),
      attack: json['attack'],
      defense: json['defense'],
      speed: json['speed'],
      wins: json['wins'],
      losses: json['losses'],
      playCount: json['playCount'],
      cleanCount: json['cleanCount'],
      battleCount: json['battleCount'],
      evolutionProgress: Map<String, dynamic>.from(json['evolutionProgress']),
      isActive: json['isActive'],
      lastHealthCheck: json['lastHealthCheck'] != null
          ? DateTime.parse(json['lastHealthCheck'])
          : null,
      personality: json['personality'],
    );
  }
}
