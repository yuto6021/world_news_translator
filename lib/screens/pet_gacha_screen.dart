import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../services/pet_service.dart';
import '../services/dex_service.dart';
import '../models/pet.dart';
import '../services/inventory_service.dart';
import '../utils/pet_image_resolver.dart';

/// ペットガチャ画面
class PetGachaScreen extends StatefulWidget {
  const PetGachaScreen({super.key});

  @override
  State<PetGachaScreen> createState() => _PetGachaScreenState();
}

class _PetGachaScreenState extends State<PetGachaScreen>
    with TickerProviderStateMixin {
  int _coins = 0;
  bool _isRolling = false;
  String? _resultSpecies;
  String? _resultRarity;
  late AnimationController _capsuleController;
  late AnimationController _resultController;
  late AnimationController _particleController;
  final List<_Particle> _particles = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadCoins();
    _capsuleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _capsuleController.dispose();
    _resultController.dispose();
    _particleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    // 実コイン残高を取得
    final current = await InventoryService.getCoins();
    if (mounted) setState(() => _coins = current);
  }

  Future<void> _rollGacha() async {
    if (_coins < 100 || _isRolling) {
      if (_coins < 100 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white),
                const SizedBox(width: 8),
                Text('コインが不足しています（残り: $_coinsコイン）'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isRolling = true;
      _resultSpecies = null;
      _resultRarity = null;
    });

    // カプセル回転演出
    _capsuleController.forward(from: 0);
    _playRollSfx();
    await Future.delayed(const Duration(milliseconds: 1500));

    // レア度決定（重み付き）
    final rng = math.Random();
    final roll = rng.nextInt(1000); // 0.1%単位に精度向上
    String rarity;
    List<String> speciesPool;

    if (roll < 5) {
      // 0.5% - GOD（配合限定専用）※画像未実装のため一時的にlegendaryから選択
      rarity = 'god';
      speciesPool = [
        // 配合限定キャラ（画像準備中）
        // 'omegamon', 'alphamon', 'imperialdramon_pm'
        // 一時的にlegendaryティアから代用
        'wargreymon',
        'metalgarurumon',
      ];
    } else if (roll < 105) {
      // 10% - レジェンダリー（ultimate段階）
      rarity = 'legendary';
      speciesPool = [
        'wargreymon',
        'metalgarurumon',
        'seraphimon',
        'herculeskabuterimon',
      ];
    } else if (roll < 305) {
      // 20% - エピック（上級adult/初期ultimate）
      rarity = 'epic';
      speciesPool = [
        'metalgreymon',
        'weregarurumon',
        'angewomon',
        'atlurkabuterimon',
        'megakabuterimon'
      ];
    } else if (roll < 605) {
      // 30% - レア（adult段階）
      rarity = 'rare';
      speciesPool = ['greymon', 'garurumon', 'angemon', 'devimon', 'leomon'];
    } else {
      // 39.5% - コモン（baby/child段階）
      rarity = 'common';
      speciesPool = [
        'agumon',
        'gabumon',
        'patamon',
        'tentomon',
        'koromon',
        'tsunomon'
      ];
    }

    final species = speciesPool[rng.nextInt(speciesPool.length)];

    // コイン消費（永続）
    await InventoryService.addCoins(-100);
    await _loadCoins();
    if (mounted) {
      setState(() {
        _resultSpecies = species;
        _resultRarity = rarity;
      });
    }

    // 結果表示演出
    await Future.delayed(const Duration(milliseconds: 300));
    _resultController.forward(from: 0);
    _spawnParticlesForRarity(rarity);
    _playRevealSfx(rarity);

    // 図鑑登録
    final isNew = await DexService.registerPet(species);

    // ペット生成
    await _createPetFromGacha(species, isNew);
    // 連続ガチャを可能にするためロール状態解除
    if (mounted) setState(() => _isRolling = false);
  }

  void _playRollSfx() {
    // 事前に assets/gacha/ に gacha_roll.mp3 などを配置想定
    _safePlay('assets/gacha/gacha_roll.mp3');
  }

  void _playRevealSfx(String rarity) {
    switch (rarity) {
      case 'god':
        _safePlay('assets/gacha/gacha_god.mp3');
        break;
      case 'legendary':
        _safePlay('assets/gacha/gacha_legendary.mp3');
        break;
      case 'epic':
        _safePlay('assets/gacha/gacha_epic.mp3');
        break;
      case 'rare':
        _safePlay('assets/gacha/gacha_rare.mp3');
        break;
      default:
        _safePlay('assets/gacha/gacha_common.mp3');
    }
  }

  Future<void> _safePlay(String assetPath) async {
    try {
      await _audioPlayer
          .play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (_) {
      // 音源未配置でもクラッシュしない
    }
  }

  void _spawnParticlesForRarity(String rarity) {
    _particles.clear();
    int count;
    double sizeMultiplier = 1.0;
    switch (rarity) {
      case 'god':
        count = 150; // 神レアは最多
        sizeMultiplier = 2.0; // 最大
        break;
      case 'legendary':
        count = 80; // より多く
        sizeMultiplier = 1.5; // より大きく
        break;
      case 'epic':
        count = 40;
        sizeMultiplier = 1.2;
        break;
      case 'rare':
        count = 25;
        break;
      default:
        count = 15;
    }
    final rand = math.Random();
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        start: DateTime.now(),
        dx: rand.nextDouble() * 220 - 110,
        dy: rand.nextDouble() * 220 - 110,
        size: (4 + rand.nextDouble() * 8) * sizeMultiplier,
        hue: rarity == 'god'
            ? 0.0 + rand.nextDouble() * 0.05 // 神レアは赤寄り
            : rarity == 'legendary'
                ? 0.12 + rand.nextDouble() * 0.15 // レジェは金色寄り
                : rand.nextDouble(),
        lifeMs: 1600 + rand.nextInt(400),
      ));
    }
    _particleController.forward(from: 0);
  }

  Future<void> _createPetFromGacha(String species, bool isNew) async {
    final newPet = PetModel(
      id: 'pet_${DateTime.now().millisecondsSinceEpoch}',
      name: _getDefaultName(species),
      species: species,
      stage: _getInitialStage(species),
      level: 1,
      exp: 0,
      hp: 100,
      hunger: 80,
      mood: 80,
      dirty: 0,
      stamina: 100,
      intimacy: 50,
      genreStats: {
        'business': 0,
        'tech': 0,
        'entertainment': 0,
        'sports': 0,
        'politics': 0,
      },
      birthDate: DateTime.now(),
      lastFed: DateTime.now(),
      lastPlayed: DateTime.now(),
      lastCleaned: DateTime.now(),
      age: 0,
      isAlive: true,
      isSick: false,
      skills: [],
      attack: _getBaseStats(species)['attack']!,
      defense: _getBaseStats(species)['defense']!,
      speed: _getBaseStats(species)['speed']!,
      wins: 0,
      losses: 0,
      playCount: 0,
      cleanCount: 0,
      battleCount: 0,
      evolutionProgress: const {},
      isActive: true,
      personality: 'neutral',
      trainingStreak: 0,
      lastTrainingDate: null,
      careMistakes: 0,
      careQuality: 100,
      truePersonality: null,
      discipline: 50,
      equippedWeapon: null,
      equippedArmor: null,
      equippedAccessory: null,
    );

    await PetService.init();
    final box = await PetService.getBox();
    await box.put(newPet.id, newPet);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Text(isNew ? '🎉 新発見！' : '✨ ゲット！'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPetImage(species, 100),
              const SizedBox(height: 16),
              Text(
                newPet.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('種族: ${_getSpeciesName(species)}'),
              Text('属性: ${_getElementName(_getElement(species))}'),
              if (isNew)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '図鑑に登録されました！',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _getDefaultName(String species) {
    final names = {
      'agumon': 'アグモン',
      'gabumon': 'ガブモン',
      'patamon': 'パタモン',
      'tentomon': 'テントモン',
      'greymon': 'グレイモン',
      'garurumon': 'ガルルモン',
      'angemon': 'エンジェモン',
      'kabuterimon': 'カブテリモン',
      'metalgreymon': 'メタルグレイモン',
      'weregarurumon': 'ワーガルルモン',
      'angewomon': 'エンジェウーモン',
      'atlurkabuterimon': 'アトラーカブテリモン',
      'wargreymon': 'ウォーグレイモン',
      'metalgarurumon': 'メタルガルルモン',
      'seraphimon': 'セラフィモン',
      'herculeskabuterimon': 'ヘラクレスカブテリモン',
    };
    return names[species] ?? species;
  }

  String _getInitialStage(String species) {
    if (species.contains('war') ||
        species.contains('metal') ||
        species.contains('seraph') ||
        species.contains('hercules')) {
      return 'ultimate';
    } else if (species.contains('grey') ||
        species.contains('garuru') ||
        species.contains('ange') ||
        species.contains('kabu')) {
      return 'adult';
    }
    return 'child';
  }

  Map<String, int> _getBaseStats(String species) {
    final stage = _getInitialStage(species);
    switch (stage) {
      case 'ultimate':
        return {'attack': 80, 'defense': 70, 'speed': 75};
      case 'adult':
        return {'attack': 50, 'defense': 45, 'speed': 48};
      default:
        return {'attack': 30, 'defense': 28, 'speed': 32};
    }
  }

  String _getElement(String species) {
    if (species.contains('grey') || species.contains('agumon')) return 'fire';
    if (species.contains('garu') || species.contains('gabu')) return 'water';
    if (species.contains('ange') || species.contains('pata')) return 'light';
    if (species.contains('kabu') || species.contains('tento')) return 'grass';
    return 'normal';
  }

  String _getSpeciesName(String species) {
    return _getDefaultName(species);
  }

  String _getElementName(String element) {
    const names = {
      'fire': '炎',
      'water': '水',
      'grass': '草',
      'electric': '電気',
      'ice': '氷',
      'rock': '岩',
      'light': '光',
      'dark': '闇',
      'normal': 'ノーマル',
    };
    return names[element] ?? element;
  }

  Widget _buildPetImage(String species, double size) {
    final stage = _getInitialStage(species);
    final imagePath = PetImageResolver.resolveImage(stage, species, 'normal');

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.pets,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  LinearGradient _getRarityGradient(String rarity) {
    switch (rarity) {
      case 'common':
        return const LinearGradient(
            colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]);
      case 'rare':
        return const LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]);
      case 'epic':
        return const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)]);
      case 'legendary':
        return const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFA000)]);
      case 'god':
        return const LinearGradient(
            colors: [Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFD50000)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]);
    }
  }

  String _getCapsuleImage(String rarity) {
    return 'assets/gacha/gacha_capsule_$rarity.png';
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9E9E9E);
      case 'rare':
        return const Color(0xFF1E88E5);
      case 'epic':
        return const Color(0xFF7B1FA2);
      case 'legendary':
        return const Color(0xFFFFA000);
      case 'god':
        return const Color(0xFFFF1744); // 神レア：鮮やかな赤
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ペットガチャ 🎰'),
        backgroundColor: Colors.pink,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/backgrounds/panel_gacha_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // コイン表示
                Card(
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          '$_coinsコイン',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ガチャ説明
                Card(
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          '🎰 ペットガチャ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '100コインで新しいペットが仲間に！',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        _buildRarityInfo('コモン', '39.5%', Colors.grey),
                        _buildRarityInfo('レア', '30%', Colors.blue),
                        _buildRarityInfo('エピック', '20%', Colors.purple),
                        _buildRarityInfo('レジェンダリー', '10%', Colors.amber),
                        _buildRarityInfo('GOD', '0.5%', Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ガチャ演出エリア
                if (_isRolling || _resultSpecies != null)
                  Card(
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          if (_isRolling && _resultSpecies == null)
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // 予兆グロー（レア度確定前は控えめ白光）
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                RotationTransition(
                                  turns: _capsuleController,
                                  child: Image.asset(
                                    'assets/gacha/gacha_capsule_common.png',
                                    width: 120,
                                    height: 120,
                                  ),
                                ),
                              ],
                            ),
                          if (_resultSpecies != null) ...[
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(CurvedAnimation(
                                parent: _resultController,
                                curve: Curves.elasticOut,
                              )),
                              child: Column(
                                children: [
                                  // カプセル演出（レア度別画像を使用）
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // レア度別強化グロー
                                      if (_resultRarity == 'legendary') ...[
                                        Container(
                                          width: 180,
                                          height: 180,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amber
                                                    .withOpacity(0.6),
                                                blurRadius: 40,
                                                spreadRadius: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      Container(
                                        width: 150,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getRarityColor(
                                                      _resultRarity!)
                                                  .withOpacity(0.5),
                                              blurRadius: 25,
                                              spreadRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Image.asset(
                                        _getCapsuleImage(_resultRarity!),
                                        width: _resultRarity == 'legendary'
                                            ? 140
                                            : 120,
                                        height: _resultRarity == 'legendary'
                                            ? 140
                                            : 120,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            gradient: _getRarityGradient(
                                                _resultRarity!),
                                            borderRadius:
                                                BorderRadius.circular(60),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getRarityColor(
                                                        _resultRarity!)
                                                    .withOpacity(0.5),
                                                blurRadius: 20,
                                                spreadRadius: 4,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: _getRarityColor(
                                                  _resultRarity!),
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // パーティクルオーバーレイ
                                      if (_particles.isNotEmpty)
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter:
                                                _ParticlePainter(_particles),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPetImage(_resultSpecies!, 150),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getDefaultName(_resultSpecies!),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // ガチャボタン
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                        (_coins >= 100 && !_isRolling) ? _rollGacha : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isRolling
                          ? '回転中...'
                          : _coins >= 100
                              ? 'ガチャを引く (100コイン)'
                              : 'コイン不足',
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

  Widget _buildRarityInfo(String name, String rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
          Text(
            rate,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final DateTime start;
  final double dx; // 初期 x オフセット
  final double dy; // 初期 y オフセット
  final double size;
  final double hue; // 0..1 で色決定
  final int lifeMs;
  _Particle({
    required this.start,
    required this.dx,
    required this.dy,
    required this.size,
    required this.hue,
    required this.lifeMs,
  });
  double progress() {
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    return (elapsed / lifeMs).clamp(0.0, 1.0);
  }

  bool get alive => progress() < 1.0;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    particles.removeWhere((p) => !p.alive); // ライフ切れ除去
    for (final p in particles) {
      final t = p.progress();
      final fade = (1.0 - t).clamp(0.0, 1.0);
      final angle = t * 6.283 + p.hue * 3.14;
      final radius = 50 + t * 70;
      final pos = center +
          Offset(math.cos(angle), math.sin(angle)) * radius +
          Offset(p.dx * 0.1, p.dy * 0.1);
      final color = HSVColor.fromAHSV(fade, p.hue * 360, 0.8, 1.0).toColor();
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos, p.size * (0.5 + fade), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
