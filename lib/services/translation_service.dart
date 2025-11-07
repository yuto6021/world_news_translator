import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_settings_service.dart';

class TranslationService {
  static const String deeplKey = '0d528a61-d312-4a5e-9096-cbbddbb17eb0:fx';
  static const String deeplUrl = 'https://api-free.deepl.com/v2/translate';

  // simple in-memory cache to avoid duplicate DeepL calls within a session
  static final Map<String, String> _cache = {};

  // small dictionary for a simple local fallback translation (English -> Japanese)
  static final Map<String, String> _tinyDict = {
    'president': '大統領',
    'election': '選挙',
    'economy': '経済',
    'market': '市場',
    'stock': '株価',
    'attack': '攻撃',
    'crash': '墜落',
    'earthquake': '地震',
    'death': '死亡',
    'dies': '死亡',
    'dead': '死亡',
    'protest': '抗議',
    'conflict': '紛争',
    'covid': 'コロナ',
    'pandemic': 'パンデミック',
    'report': '報告',
    'breaking': '速報',
    'investigation': '捜査',
    'government': '政府',
    'inflation': 'インフレ',
    'rate': '金利',
    'unemployment': '失業率',
    'hospital': '病院',
    'health': '医療',
    'fire': '火災',
    'police': '警察',
    'law': '法律',
    'court': '裁判所',
    'deal': '合意',
    'trade': '貿易',
    'climate': '気候',
    'change': '変化',
    'minister': '大臣',
    'ministerial': '閣僚の',
    // 追加語彙（重複を避けつつ幅広く補完）
    'recovery': '回復',
    'growth': '成長',
    'loss': '損失',
    'losses': '損失',
    'victim': '被害者',
    'victims': '被害者',
    'hospitalized': '入院',
    'injured': '負傷',
    'decline': '減少',
    'rise': '上昇',
    'surge': '急増',
    'prime': '首相',
    'prime minister': '首相',
    'presidential': '大統領の',
    'terror': 'テロ',
    'attackers': '加害者',
    'military': '軍',
    'troops': '部隊',
    'border': '国境',
    'sanctions': '制裁',
    'agreement reached': '合意に達した',
    'investment': '投資',
    'investors': '投資家',
    'technology': '技術',
    'tech': 'テクノロジー',
    'startup': 'スタートアップ',
    'company': '企業',
    'companies': '企業',
    'stock market': '株式市場',
    'shares': '株式',
    'bitcoin': 'ビットコイン',
    'cryptocurrency': '暗号通貨',
    'data': 'データ',
    'privacy': 'プライバシー',
    'scandal': 'スキャンダル',
    'judge': '判事',
    'verdict': '評決',
    'trial': '裁判',
    'lawsuit': '訴訟',
    'lawmakers': '議員',
    'evidence': '証拠',
    'probe': '調査',
    'committee': '委員会',
    'budget': '予算',
    'spending': '支出',
    'tax': '税',
    'policy': '政策',
    'policies': '政策',
    'emissions': '排出量',
    'storm': '嵐',
    'flood': '洪水',
    'evacuated': '避難',
    'wildfire': '山火事',
    'rescue': '救助',
    'residents': '住民',
    'community': 'コミュニティ',
    'education': '教育',
    'school': '学校',
    'teacher': '教師',
    'students': '学生',
    'healthcare': '医療',
    'vaccine': 'ワクチン',
    'unrest': '不安',
    'protests': '抗議',
    'protester': '抗議者',
    'violence': '暴力',
    'crisis': '危機',
    'emergency': '緊急事態',
    'exclusive': '独占',
    'analysis': '分析',
    'opinion': '意見',
    'editorial': '社説',
    'interview': 'インタビュー',
    'said': 'と述べた',
    'says': 'と述べている',
    'announced': '発表した',
    'warned': '警告した',
    'confirmed': '確認した',
    'released': '公開した',
    // さらに語彙を追加（政治・経済・技術・災害・スポーツ等）
    'senate': '上院',
    'congress': '議会',
    'house': '下院',
    'representative': '議員',
    'governor': '知事',
    'mayor': '市長',
    'cabinet': '内閣',
    'immigration': '移民',
    'refugee': '難民',
    'asylum': '庇護',
    'billion': '10億',
    'million': '100万',
    'trillion': '兆',
    'deficit': '赤字',
    'surplus': '黒字',
    'fiscal': '財政の',
    'federal': '連邦の',
    'state': '州',
    'local': '地方',
    'currency': '通貨',
    'dollar': 'ドル',
    'yen': '円',
    'pound': 'ポンド',
    'euro': 'ユーロ',
    'export': '輸出',
    'import': '輸入',
    'embargo': '禁輸',
    'negotiation': '交渉',
    'negotiations': '交渉',
    'merger': '合併',
    'acquisition': '買収',
    'layoff': '解雇',
    'strike': 'ストライキ',
    'union': '労働組合',
    'CEO': '最高経営責任者',
    'chairman': '会長',
    'resign': '辞任する',
    'resignation': '辞任',
    'leak': 'リーク',
    'whistleblower': '内部告発者',
    'cyber': 'サイバー',
    'hacker': 'ハッカー',
    'virus': 'ウイルス',
    'outbreak': '発生',
    'variant': '変異株',
    'case': '症例',
    'cases': '症例',
    'satellite': '衛星',
    'missile': 'ミサイル',
    'nuclear': '核の',
    'weapon': '武器',
    'terrorism': 'テロリズム',
    'peace': '平和',
    'accord': '協定',
    'clash': '衝突',
    'solution': '解決策',
    'summit': '首脳会議',
    'diplomacy': '外交',
    'ambassador': '大使',
    'consulate': '領事館',
    'visa': 'ビザ',
    'border patrol': '国境警備',
    'criminal': '犯罪の',
    'crime': '犯罪',
    'arrest': '逮捕',
    'indictment': '起訴',
    'corruption': '汚職',
    'fraud': '詐欺',
    'bankruptcy': '破産',
    'loan': 'ローン',
    'mortgage': '抵当',
    'ai': 'AI',
    'artificial intelligence': '人工知能',
    'machine learning': '機械学習',
    'algorithm': 'アルゴリズム',
    'goal': 'ゴール',
    'match': '試合',
    'championship': '選手権',
    'tournament': 'トーナメント',
    'coach': '監督',
    'player': '選手',
    'transfer': '移籍',
    'season': 'シーズン',
    'temperature': '気温',
    'forecast': '予報',
    'heatwave': '猛暑',
    'cold wave': '寒波',
    // 大量語彙追加（ユーザーの要望で拡張）
    'america': 'アメリカ',
    'united states': 'アメリカ合衆国',
    'usa': '米国',
    'uk': '英国',
    'britain': '英国',
    'england': 'イングランド',
    'scotland': 'スコットランド',
    'wales': 'ウェールズ',
    'ireland': 'アイルランド',
    'china': '中国',
    'japan': '日本',
    'india': 'インド',
    'germany': 'ドイツ',
    'france': 'フランス',
    'italy': 'イタリア',
    'spain': 'スペイン',
    'portugal': 'ポルトガル',
    'russia': 'ロシア',
    'ukraine': 'ウクライナ',
    'canada': 'カナダ',
    'brazil': 'ブラジル',
    'mexico': 'メキシコ',
    'australia': 'オーストラリア',
    'new zealand': 'ニュージーランド',
    'south korea': '韓国',
    'north korea': '北朝鮮',
    'turkey': 'トルコ',
    'iran': 'イラン',
    'iraq': 'イラク',
    'syria': 'シリア',
    'egypt': 'エジプト',
    'south africa': '南アフリカ',
    'nigeria': 'ナイジェリア',
    'kenya': 'ケニア',
    'saudi': 'サウジ',
    'saudi arabia': 'サウジアラビア',
    'israel': 'イスラエル',
    'palestine': 'パレスチナ',
    'afghanistan': 'アフガニスタン',
    'pakistan': 'パキスタン',
    'bangladesh': 'バングラデシュ',
    'philippines': 'フィリピン',
    'indonesia': 'インドネシア',
    'vietnam': 'ベトナム',
    'thailand': 'タイ',
    'singapore': 'シンガポール',
    'malaysia': 'マレーシア',
    'china trade': '中国貿易',
    'gdp': '国内総生産',
    'growth rate': '成長率',
    'inflation rate': 'インフレ率',
    'interest rate': '金利',
    'bank': '銀行',
    'central bank': '中央銀行',
    'stock exchange': '証券取引所',
    'nasdaq': 'ナスダック',
    'dow jones': 'ダウ',
    'ftse': 'FTSE',
    'nikkei': '日経',
    'economist': '経済学者',
    'analyst': 'アナリスト',
    'reporter': '記者',
    'editor': '編集者',
    'column': 'コラム',
    'commentary': '解説',
    'op-ed': '社説',
    'press': '報道',
    'media': 'メディア',
    'broadcast': '放送',
    'television': 'テレビ',
    'radio': 'ラジオ',
    'internet': 'インターネット',
    'social media': 'ソーシャルメディア',
    'twitter': 'ツイッター',
    'facebook': 'フェイスブック',
    'instagram': 'インスタグラム',
    'youtube': 'ユーチューブ',
    'influencer': 'インフルエンサー',
    'campaign': 'キャンペーン',
    'candidate': '候補者',
    'vote': '投票',
    'voter': '有権者',
    'ballot': '投票用紙',
    'poll': '世論調査',
    'turnout': '投票率',
    'margin': '差',
    'wins': '勝利',
    'loses': '敗北',
    'recount': '再集計',
    'survey': '調査',
    'policy maker': '政策決定者',
    'lawmaker': '立法者',
    'ministerial meeting': '閣僚会議',
    'parliament': '議会',
    'cabinet meeting': '閣議',
    'coalition': '連立',
    'opposition': '野党',
    'majority': '多数派',
    'minority': '少数派',
    'senator': '上院議員',
    'congressman': '下院議員',
    'representatives': '代表者',
    'legislation': '法案',
    'bill': '法案',
    'amendment': '修正案',
    'veto': '拒否権',
    'ratify': '批准する',
    'treaty': '条約',
    'sanctioned': '制裁された',
    'embassy': '大使館',
    'consul': '領事',
    'diplomat': '外交官',
    'intelligence': '情報機関',
    'espionage': '諜報活動',
    'classified': '機密',
    'court ruling': '裁判所の判決',
    'appeal': '上訴',
    'sentence': '判決',
    'convicted': '有罪判決',
    'acquitted': '無罪判決',
    'lawsuit filed': '訴訟提起',
    'settlement': '和解',
    'trial begins': '裁判開始',
    'jury': '陪審',
    'forensic': '法医学の',
    'investigate': '調査する',
    'raid': '手入れ',
    'arrested': '逮捕された',
    'detained': '拘束された',

    'charged': '起訴された',
    'plea': '罪状認否',
    'guilty plea': '有罪答弁',
    'not guilty': '無罪',
    'judiciary': '司法制度',
    'supreme court': '最高裁判所',
    'appeals court': '控訴裁判所',
    'district court': '地方裁判所',
    'laws': '法律',
    'regulation': '規制',
    'statute': '法令',
    'ordinance': '条例',
    'compliance': '遵守',
    'violation': '違反',
    'fine': '罰金',
    'penalty': '罰則',
    'prosecute': '起訴する',
    'defense': '弁護',
    'attorney': '弁護士',

    'bail': '保釈',
    'sentence length': '刑期',
    'parole': '仮釈放',
    'appeals process': '上訴手続き',
  };

  static bool _dictLoadedFromAsset = false;

  static Future<void> _loadDictFromAsset() async {
    if (_dictLoadedFromAsset) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/translation_dict.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      // Merge, but keep existing keys (inline) as defaults; asset can override if desired
      data.forEach((k, v) {
        if (v != null) {
          _tinyDict[k] = v.toString();
        }
      });
      _dictLoadedFromAsset = true;
      debugPrint(
          '[TranslationService] Loaded translation_dict.json (${data.length} entries)');
    } catch (e) {
      debugPrint(
          '[TranslationService] No asset dict loaded or parse error: $e');
      // Not fatal — keep inline dictionary
    }
  }

  static Future<String> translateToJapanese(String text) async {
    // Try to load external dictionary (if present) once on first use
    await _loadDictFromAsset();
    if (text.trim().isEmpty) return '（本文なし）';
    if (_cache.containsKey(text)) return _cache[text]!;
    // Web (ブラウザ) では DeepL API への直接呼び出しは CORS により失敗することが多い。
    // ブラウザ実行時は自動的に簡易翻訳にフォールバックして安定させる。
    if (kIsWeb) {
      debugPrint(
          '[TranslationService] Running on web: skipping DeepL (use proxy to enable)');
      final fallback = _pseudoTranslate(text);
      _cache[text] = fallback;
      return fallback;
    }

    // ユーザーが DeepL を優先しない設定の場合、簡易翻訳をすぐ返す
    final snippet = text.length > 120 ? '${text.substring(0, 120)}...' : text;
    debugPrint('[TranslationService] translateToJapanese: text="$snippet"');
    if (!AppSettingsService.instance.preferDeepl.value) {
      debugPrint(
          '[TranslationService] preferDeepl is false: using pseudo-translation');
      final fallback = _pseudoTranslate(text);
      _cache[text] = fallback;
      return fallback;
    }

    try {
      // Use throttled DeepL caller to avoid too many concurrent requests from list views
      final result = await _callDeepLWithThrottle(text);
      _cache[text] = result;
      return result;
    } catch (e) {
      debugPrint('[TranslationService] Exception while calling DeepL: $e');
      final fallback = _pseudoTranslate(text);
      _cache[text] = fallback;
      return fallback;
    }
  }

  // --- Throttling implementation ------------------------------------------------
  static const int _maxConcurrent = 3;
  static int _activeRequests = 0;
  static final List<_QueuedCall> _queue = [];

  static Future<String> _callDeepLWithThrottle(String text) {
    final completer = Completer<String>();

    void start() async {
      _activeRequests++;
      try {
        debugPrint('[TranslationService] Calling DeepL API (throttled)...');
        final proxy = dotenv.env['DEEPL_PROXY'];
        final urlToUse = (proxy != null && proxy.isNotEmpty) ? proxy : deeplUrl;
        final response = await http.post(
          Uri.parse(urlToUse),
          body: {
            'auth_key': deeplKey,
            'text': text,
            'target_lang': 'JA',
          },
        );

        debugPrint(
            '[TranslationService] DeepL response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final res =
              (data['translations'] != null && data['translations'].isNotEmpty)
                  ? data['translations'][0]['text']
                  : '（翻訳結果なし）';
          completer.complete(res);
        } else if (response.statusCode == 429 || response.statusCode == 403) {
          debugPrint(
              '[TranslationService] DeepL rate/auth error, body=${response.body}');
          completer.completeError(
              HttpException('DeepL rate/auth ${response.statusCode}'));
        } else {
          debugPrint(
              '[TranslationService] DeepL unexpected status ${response.statusCode}');
          completer.completeError(
              HttpException('DeepL error ${response.statusCode}'));
        }
      } catch (e) {
        completer.completeError(e);
      } finally {
        _activeRequests--;
        // start next queued call if any
        if (_queue.isNotEmpty) {
          final next = _queue.removeAt(0);
          Future.microtask(next.start);
        }
      }
    }

    final queued = _QueuedCall(start);
    if (_activeRequests < _maxConcurrent) {
      // start immediately
      Future.microtask(queued.start);
    } else {
      _queue.add(queued);
    }

    return completer.future;
  }

  // 超軽量の疑似翻訳: 既知語を置換してユーザーに意味の手がかりを与える
  static String _pseudoTranslate(String text) {
    var result = text;
    // 単語ごとに置換（長い文章でも安全）。記号・括弧付きの語や複数形にも対応する。
    _tinyDict.forEach((eng, jp) {
      // 単語境界にマッチするが、末尾のピリオドやカンマに続く場合も考慮
      result = result.replaceAll(
          RegExp('\\b${RegExp.escape(eng)}\\b', caseSensitive: false), jp);
      // 複数形の's'に対応（books -> book -> 辞書にbookがあれば置換される）
      result = result.replaceAll(
          RegExp('\\b${RegExp.escape(eng)}s\\b', caseSensitive: false), jp);
    });

    // それでも置換が無い場合はトークン分割して既知語だけを置換する試みを行う
    if (result == text) {
      final tokens = text.split(RegExp(r'[^A-Za-z]+'));
      var worked = false;
      var out = text;
      for (final t in tokens) {
        if (t.trim().isEmpty) continue;
        final key = t.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '');
        if (_tinyDict.containsKey(key)) {
          out = out.replaceAll(RegExp(RegExp.escape(t)), _tinyDict[key]!);
          worked = true;
        } else if (key.endsWith('s') &&
            _tinyDict.containsKey(key.substring(0, key.length - 1))) {
          out = out.replaceAll(RegExp(RegExp.escape(t)),
              _tinyDict[key.substring(0, key.length - 1)]!);
          worked = true;
        }
      }
      if (worked) {
        _cache[text] = '$out（簡易翻訳）';
        return '$out（簡易翻訳）';
      }

      // 本当に置換ができない場合、長い文は先頭だけ切って注記を付与
      if (text.length > 160) {
        return '${text.substring(0, 157)}...（原文/簡易表示）';
      }
      return '$text（未翻訳・簡易表示）';
    }

    return '$result（簡易翻訳）';
  }

  static void clearCache() {
    _cache.clear();
  }
}

class _QueuedCall {
  final void Function() start;
  _QueuedCall(this.start);
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
