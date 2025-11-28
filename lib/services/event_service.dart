/// イベント管理サービス
class EventService {
  /// 現在開催中のイベントを取得
  static List<GameEvent> getCurrentEvents() {
    final now = DateTime.now();
    final events = <GameEvent>[];

    // 季節イベント
    final seasonalEvent = _getSeasonalEvent(now);
    if (seasonalEvent != null) events.add(seasonalEvent);

    // 曜日イベント
    final weekdayEvent = _getWeekdayEvent(now);
    if (weekdayEvent != null) events.add(weekdayEvent);

    // 週末イベント
    if (_isWeekend(now)) {
      events.add(_getWeekendEvent());
    }

    // 特定時間イベント
    final hourlyEvent = _getHourlyEvent(now);
    if (hourlyEvent != null) events.add(hourlyEvent);

    return events;
  }

  /// 季節イベント取得
  static GameEvent? _getSeasonalEvent(DateTime date) {
    final month = date.month;
    final day = date.day;

    // 1月: 新年イベント
    if (month == 1 && day <= 7) {
      return GameEvent(
        id: 'newyear',
        name: '🎍 お正月イベント',
        description: 'ボーナスコイン2倍！進化成功率UP！',
        bonuses: {'coins': 2.0, 'evolveSuccess': 1.3},
        startDate: DateTime(date.year, 1, 1),
        endDate: DateTime(date.year, 1, 7, 23, 59),
      );
    }

    // 2月: バレンタイン
    if (month == 2 && day >= 10 && day <= 14) {
      return GameEvent(
        id: 'valentine',
        name: '💝 バレンタインイベント',
        description: '親密度獲得2倍！キャンディドロップ率UP！',
        bonuses: {'intimacy': 2.0, 'candyDrop': 3.0},
        startDate: DateTime(date.year, 2, 10),
        endDate: DateTime(date.year, 2, 14, 23, 59),
      );
    }

    // 3-5月: 春イベント
    if (month >= 3 && month <= 5) {
      return GameEvent(
        id: 'spring',
        name: '🌸 春の育成キャンペーン',
        description: '経験値1.5倍！成長速度UP！',
        bonuses: {'exp': 1.5, 'growthSpeed': 1.3},
        startDate: DateTime(date.year, 3, 1),
        endDate: DateTime(date.year, 5, 31, 23, 59),
      );
    }

    // 6-8月: 夏イベント
    if (month >= 6 && month <= 8) {
      return GameEvent(
        id: 'summer',
        name: '☀️ 夏のバトルフェス',
        description: 'バトル報酬2倍！ボス出現率UP！',
        bonuses: {'battleReward': 2.0, 'bossSpawn': 1.5},
        startDate: DateTime(date.year, 6, 1),
        endDate: DateTime(date.year, 8, 31, 23, 59),
      );
    }

    // 9-11月: 秋イベント
    if (month >= 9 && month <= 11) {
      return GameEvent(
        id: 'autumn',
        name: '🍂 秋の収穫祭',
        description: 'アイテムドロップ率2倍！レアアイテム出やすい！',
        bonuses: {'dropRate': 2.0, 'rareItemRate': 1.8},
        startDate: DateTime(date.year, 9, 1),
        endDate: DateTime(date.year, 11, 30, 23, 59),
      );
    }

    // 10月: ハロウィン
    if (month == 10 && day >= 25 && day <= 31) {
      return GameEvent(
        id: 'halloween',
        name: '🎃 ハロウィンナイト',
        description: 'レア敵大量出現！闇系ペット強化！',
        bonuses: {'rareEnemy': 3.0, 'darkPower': 1.5},
        startDate: DateTime(date.year, 10, 25),
        endDate: DateTime(date.year, 10, 31, 23, 59),
      );
    }

    // 12月: クリスマス & 冬
    if (month == 12) {
      if (day >= 20 && day <= 26) {
        return GameEvent(
          id: 'christmas',
          name: '🎄 クリスマスイベント',
          description: 'プレゼントドロップ！全ボーナス1.5倍！',
          bonuses: {'all': 1.5, 'giftDrop': 5.0},
          startDate: DateTime(date.year, 12, 20),
          endDate: DateTime(date.year, 12, 26, 23, 59),
        );
      } else {
        return GameEvent(
          id: 'winter',
          name: '❄️ 冬のスペシャル',
          description: 'コイン獲得1.3倍！',
          bonuses: {'coins': 1.3},
          startDate: DateTime(date.year, 12, 1),
          endDate: DateTime(date.year, 12, 31, 23, 59),
        );
      }
    }

    return null;
  }

  /// 曜日別イベント
  static GameEvent? _getWeekdayEvent(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return GameEvent(
          id: 'monday',
          name: '💪 月曜強化デー',
          description: 'ペット攻撃力+20%',
          bonuses: {'attack': 1.2},
        );
      case DateTime.tuesday:
        return GameEvent(
          id: 'tuesday',
          name: '🛡️ 火曜防御デー',
          description: 'ペット防御力+20%',
          bonuses: {'defense': 1.2},
        );
      case DateTime.wednesday:
        return GameEvent(
          id: 'wednesday',
          name: '⚡ 水曜スピードデー',
          description: 'ペット速度+20%',
          bonuses: {'speed': 1.2},
        );
      case DateTime.thursday:
        return GameEvent(
          id: 'thursday',
          name: '📚 木曜経験デー',
          description: '経験値+30%',
          bonuses: {'exp': 1.3},
        );
      case DateTime.friday:
        return GameEvent(
          id: 'friday',
          name: '💰 金曜コインデー',
          description: 'コイン獲得+50%',
          bonuses: {'coins': 1.5},
        );
      default:
        return null;
    }
  }

  /// 週末イベント
  static GameEvent _getWeekendEvent() {
    return GameEvent(
      id: 'weekend',
      name: '🎉 週末ボーナス',
      description: '全報酬1.5倍！レアドロップ率UP！',
      bonuses: {'all': 1.5, 'rareItemRate': 2.0},
    );
  }

  /// 時間帯イベント
  static GameEvent? _getHourlyEvent(DateTime date) {
    final hour = date.hour;

    // ゴールデンタイム (19-21時)
    if (hour >= 19 && hour < 21) {
      return GameEvent(
        id: 'golden_time',
        name: '⭐ ゴールデンタイム',
        description: '全報酬2倍！レア確率大幅UP！',
        bonuses: {'all': 2.0, 'rareRate': 3.0},
      );
    }

    // ミッドナイトボーナス (0-2時)
    if (hour >= 0 && hour < 2) {
      return GameEvent(
        id: 'midnight_bonus',
        name: '🌙 ミッドナイトボーナス',
        description: 'シークレットボス出現率UP！',
        bonuses: {'secretBoss': 3.0, 'rareEnemy': 2.0},
      );
    }

    return null;
  }

  /// 週末判定
  static bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// 総合ボーナス倍率計算
  static Map<String, double> getTotalEventBonus() {
    final events = getCurrentEvents();
    final Map<String, double> totalBonus = {};

    for (final event in events) {
      event.bonuses.forEach((key, value) {
        if (key == 'all') {
          // 全ボーナスは既存の各項目に乗算
          totalBonus.forEach((k, v) {
            totalBonus[k] = v * value;
          });
        } else {
          totalBonus[key] = (totalBonus[key] ?? 1.0) * value;
        }
      });
    }

    return totalBonus;
  }

  /// イベント説明文生成
  static String getEventSummary() {
    final events = getCurrentEvents();

    if (events.isEmpty) {
      return '現在イベントはありません';
    }

    return events.map((e) => e.name).join('\n');
  }
}

/// ゲームイベント
class GameEvent {
  final String id;
  final String name;
  final String description;
  final Map<String, double> bonuses;
  final DateTime? startDate;
  final DateTime? endDate;

  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.bonuses,
    this.startDate,
    this.endDate,
  });

  bool isActive() {
    if (startDate == null || endDate == null) return true;

    final now = DateTime.now();
    return now.isAfter(startDate!) && now.isBefore(endDate!);
  }
}
