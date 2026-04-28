// ================================================================
//  HOME SCREEN — نسخة عربية كاملة
// ================================================================
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../main.dart';

// ================================================================
//  ترجمة أسماء الأمراض للعربية
// ================================================================
const Map<String, String> diseaseTranslation = {
  '(vertigo) Paroymsal  Positional Vertigo': 'الدوار الوضعي الانتيابي',
  'AIDS': 'الإيدز',
  'Acne': 'حب الشباب',
  'Alcoholic hepatitis': 'التهاب الكبد الكحولي',
  'Allergy': 'الحساسية',
  'Arthritis': 'التهاب المفاصل',
  'Bronchial Asthma': 'الربو القصبي',
  'Cervical spondylosis': 'الفقار العنقي',
  'Chicken pox': 'جدري الماء',
  'Chronic cholestasis': 'الركود الصفراوي المزمن',
  'Common Cold': 'نزلة البرد',
  'Dengue': 'حمى الضنك',
  'Diabetes': 'مرض السكري',
  'Dimorphic hemmorhoids(piles)': 'البواسير',
  'Drug Reaction': 'تفاعل دوائي',
  'Fungal infection': 'عدوى فطرية',
  'GERD': 'ارتجاع المريء',
  'Gastroenteritis': 'التهاب المعدة والأمعاء',
  'Heart attack': 'النوبة القلبية',
  'Hepatitis B': 'التهاب الكبد ب',
  'Hepatitis C': 'التهاب الكبد ج',
  'Hepatitis D': 'التهاب الكبد د',
  'Hepatitis E': 'التهاب الكبد هـ',
  'Hypertension': 'ارتفاع ضغط الدم',
  'Hyperthyroidism': 'فرط نشاط الغدة الدرقية',
  'Hypoglycemia': 'انخفاض سكر الدم',
  'Hypothyroidism': 'قصور الغدة الدرقية',
  'Impetigo': 'القوباء الجلدية',
  'Jaundice': 'اليرقان',
  'Malaria': 'الملاريا',
  'Migraine': 'الصداع النصفي',
  'Osteoarthristis': 'التهاب المفاصل التنكسي',
  'Paralysis (brain hemorrhage)': 'الشلل (نزيف دماغي)',
  'Peptic ulcer diseae': 'القرحة الهضمية',
  'Pneumonia': 'الالتهاب الرئوي',
  'Psoriasis': 'الصدفية',
  'Tuberculosis': 'السل الرئوي',
  'Typhoid': 'التيفويد',
  'Urinary tract infection': 'التهاب المسالك البولية',
  'Varicose veins': 'دوالي الأوردة',
  'hepatitis A': 'التهاب الكبد أ',
};

String translateDisease(String english) =>
    diseaseTranslation[english] ?? english;

// ================================================================
//  ترجمة درجة الخطورة
// ================================================================
String translateRisk(String risk) {
  if (risk.contains('High')) return 'خطورة عالية 🔴';
  if (risk.contains('Medium')) return 'خطورة متوسطة 🟡';
  return 'خطورة منخفضة 🟢';
}

// ================================================================
//  HOME SCREEN
// ================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _chatCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<String>              _allSymptoms    = [];
  List<String>              _filtered       = [];
  List<String>              _selected       = [];
  PredictionResult?         _result;
  List<Map<String, String>> _chatHistory    = [];
  bool _loading        = false;
  bool _chatLoading    = false;
  bool _symptomsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadSymptoms();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---- تحميل الأعراض ----
  Future<void> _loadSymptoms() async {
    try {
      final syms = await ApiService.getAllSymptoms();
      setState(() {
        _allSymptoms = syms.map((s) => symptomTranslation[s] ?? s).toList()
          ..sort((a, b) => a.compareTo(b)); // ترتيب أبجدي
        _filtered = _allSymptoms;
        _symptomsLoaded = true;
      });
    } catch (e) {
      _snack('خطأ في الاتصال: $e', isError: true);
    }
  }

  void _filter(String q) => setState(() => _filtered = _allSymptoms
      .where((s) => s.contains(q))
      .toList());

  void _toggle(String s) => setState(
          () => _selected.contains(s) ? _selected.remove(s) : _selected.add(s));

  // ---- التحليل ----
  Future<void> _predict() async {
    if (_selected.isEmpty) {
      _snack('اختر عرضاً واحداً على الأقل');
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
      _chatHistory = [];
    });

    try {
      final englishSymptoms =
      _selected.map((s) => getEnglishSymptom(s)).toList();
      final r = await ApiService.predict(englishSymptoms);

      setState(() {
        _result = r;
        _loading = false;
        _chatHistory = [
          {'role': 'assistant', 'content': r.aiSummary},
        ];
      });
      _tabCtrl.animateTo(1);
    } catch (e) {
      setState(() => _loading = false);
      _snack('حدث خطأ: $e', isError: true);
    }
  }

  // ---- الدردشة ----
  Future<void> _sendChat() async {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty || _result == null) return;
    _chatCtrl.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'content': msg});
      _chatLoading = true;
    });
    _scrollDown();
    try {
      final trimmed = _chatHistory.length > 6
          ? _chatHistory.sublist(_chatHistory.length - 6)
          : List<Map<String, String>>.from(_chatHistory);

      final reply = await ApiService.chat(
        message:  msg,
        disease:  _result!.disease,
        risk:     _result!.riskLevel,
        symptoms: _selected.map((s) => getEnglishSymptom(s)).toList(),
        history:  trimmed,
      );
      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': reply});
        _chatLoading = false;
      });
      _scrollDown();
    } catch (e) {
      setState(() => _chatLoading = false);
      _snack('حدث خطأ: $e', isError: true);
    }
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 200), () {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  void _reset() {
    setState(() {
      _selected.clear();
      _result = null;
      _chatHistory = [];
      _searchCtrl.clear();
      _filtered = _allSymptoms;
    });
    _tabCtrl.animateTo(0);
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 13),
            textDirection: TextDirection.rtl),
        backgroundColor: isError ? kRed : kAccent,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ));

  // ================================================================
  //  BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SafeArea(
      child: Column(children: [
        _header(),
        _tabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _symptomsTab(),
              _resultsTab(),
              _chatTab(),
            ],
          ),
        ),
      ]),
    ),
  );

  // ================================================================
  //  HEADER
  // ================================================================
  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: const BoxDecoration(
      color: kSurface,
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: kAccent, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.monitor_heart_outlined,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ميدي سكان',
                  style: TextStyle(
                      color: kText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Text('تحليل الأعراض والتشخيص الأولي',
                  style: TextStyle(color: kMuted, fontSize: 11)),
            ],
          ),
        ),
        if (_result != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kMuted, size: 20),
            onPressed: _reset,
            tooltip: 'بدء من جديد',
            padding: EdgeInsets.zero,
            constraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    ),
  );

  // ================================================================
  //  TAB BAR
  // ================================================================
  Widget _tabBar() => Container(
    color: kSurface,
    child: TabBar(
      controller: _tabCtrl,
      indicatorColor: kAccent,
      indicatorWeight: 2,
      labelColor: kAccent,
      unselectedLabelColor: kMuted,
      labelStyle:
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      tabs: const [
        Tab(text: 'الأعراض'),
        Tab(text: 'النتائج'),
        Tab(text: 'الاستشارة'),
      ],
    ),
  );

  // ================================================================
  //  TAB 1 — الأعراض
  // ================================================================
  Widget _symptomsTab() => Column(children: [
    // شريط البحث
    Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filter,
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: kText, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'ابحث عن عرض...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon:
          const Icon(Icons.search_rounded, color: kMuted, size: 18),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                color: kMuted, size: 16),
            onPressed: () {
              _searchCtrl.clear();
              _filter('');
            },
          )
              : null,
        ),
      ),
    ),

    // الأعراض المختارة
    if (_selected.isNotEmpty) ...[
      Container(
        color: kSurface,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        child: SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL direction for chips
            itemCount: _selected.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _toggle(_selected[i]),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kAccentL,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: kAccent.withOpacity(0.4), width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.close_rounded,
                      color: kAccent, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    _selected[i],
                    style: const TextStyle(
                        color: kAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
      Container(
        color: kSurface,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text('${_selected.length} مختار',
                style:
                const TextStyle(color: kMuted, fontSize: 11)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selected.clear()),
              child: const Text('مسح الكل',
                  style: TextStyle(color: kRed, fontSize: 11)),
            ),
          ],
        ),
      ),
    ],

    Container(
      color: kSurface,
      child:
      const Divider(height: 12, thickness: 0.5, color: kBorder),
    ),

    // قائمة الأعراض
    Expanded(
      child: !_symptomsLoaded
          ? const Center(
          child: CircularProgressIndicator(
              color: kAccent, strokeWidth: 2))
          : _filtered.isEmpty
          ? const Center(
          child: Text('لا توجد نتائج',
              style: TextStyle(color: kMuted, fontSize: 13)))
          : ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final s = _filtered[i];
          final sel = _selected.contains(s);
          return InkWell(
            onTap: () => _toggle(s),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sel
                    ? kAccentL.withOpacity(0.5)
                    : kSurface,
                border: const Border(
                    bottom: BorderSide(
                        color: kBorder, width: 0.5)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: sel
                          ? kAccent
                          : Colors.transparent,
                      border: Border.all(
                          color: sel ? kAccent : kBorder,
                          width: sel ? 1.5 : 0.5),
                      borderRadius:
                      BorderRadius.circular(5),
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s,
                    style: TextStyle(
                      color: sel ? kAccent : kText,
                      fontSize: 13,
                      fontWeight: sel
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),

    // زر التحليل
    Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: ElevatedButton(
        onPressed: _loading ? null : _predict,
        child: _loading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : Text(
          _selected.isEmpty
              ? 'اختر الأعراض أولاً'
              : 'تحليل الأعراض (${_selected.length})',
        ),
      ),
    ),
  ]);

  // ================================================================
  //  TAB 2 — النتائج
  // ================================================================
  Widget _resultsTab() {
    // حالة التحليل
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kAccent, strokeWidth: 2),
            SizedBox(height: 14),
            Text('جاري تحليل الأعراض...',
                style: TextStyle(color: kMuted, fontSize: 13)),
          ],
        ),
      );
    }

    // لا يوجد نتائج بعد
    if (_result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kAccentL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: kAccent, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('لا توجد نتائج بعد',
                  style: TextStyle(
                      color: kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'اذهب إلى تبويب الأعراض، اختر ما تشعر به\nواضغط "تحليل الأعراض"',
                style: TextStyle(color: kMuted, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _tabCtrl.animateTo(0),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('ابدأ التحليل'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccent,
                  side: const BorderSide(color: kAccent, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final r = _result!;
    final arabicDisease = translateDisease(r.disease);
    final arabicRisk    = translateRisk(r.riskLevel);

    // ألوان درجة الخطورة
    final Color rColor;
    final Color rBg;
    final Color rBd;
    if (r.riskLevel.contains('High')) {
      rColor = kRed; rBg = kRedL; rBd = kRedB;
    } else if (r.riskLevel.contains('Medium')) {
      rColor = kYellow; rBg = kYellowL; rBd = kYellowB;
    } else {
      rColor = kGreen; rBg = kGreenL; rBd = kGreenB;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [

          // ── بطاقة التشخيص الرئيسي ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('التشخيص المبدئي'),
                const SizedBox(height: 10),
                Text(
                  arabicDisease,
                  style: const TextStyle(
                      color: kText,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  r.disease, // الاسم الإنجليزي بخط أصغر
                  style: const TextStyle(color: kMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  // درجة الخطورة
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: rBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: rBd, width: 0.5),
                    ),
                    child: Text(
                      arabicRisk,
                      style: TextStyle(
                          color: rColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('النقاط: ${r.riskScore}',
                      style:
                      const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── الأعراض المختارة ──
          if (_selected.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('الأعراض التي أدخلتها'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selected.map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kAccentL,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: kAccent.withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: kAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── التشخيصات المحتملة ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('الاحتمالات الأخرى'),
                const SizedBox(height: 12),
                ...r.probabilities.map((p) {
                  final arabic = translateDisease(p.disease);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(arabic,
                                style: const TextStyle(
                                    color: kText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text(
                            '${(p.probability * 100).toStringAsFixed(1)}٪',
                            style: TextStyle(
                                color: p.probability > 0.5
                                    ? kAccent
                                    : kMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: p.probability,
                            minHeight: 6,
                            backgroundColor: kBorder,
                            valueColor:
                            AlwaysStoppedAnimation(
                                p.probability > 0.5
                                    ? kAccent
                                    : kMuted),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── الملخص الطبي (من Gemini) ──
          if (r.aiSummary.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _sectionLabel('الملخص الطبي'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kAccentL,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('AI',
                          style: TextStyle(
                              color: kAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    r.aiSummary,
                    style: const TextStyle(
                        color: kText, fontSize: 13, height: 1.7),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── تحذير طبي ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kYellowL,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kYellowB, width: 0.5),
            ),
            child: const Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: kYellow, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هذا التحليل للاسترشاد فقط ولا يُغني عن استشارة طبيب متخصص.',
                    style:
                    TextStyle(color: kYellow, fontSize: 11, height: 1.5),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── زر الاستشارة ──
          ElevatedButton.icon(
            onPressed: () => _tabCtrl.animateTo(2),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('متابعة مع الاستشارة الذكية'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 8),

          // ── زر إعادة التحليل ──
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('تحليل جديد'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kMuted,
              side: const BorderSide(color: kBorder, width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 46),
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ================================================================
  //  TAB 3 — الاستشارة
  // ================================================================
  Widget _chatTab() {
    if (_result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kAccentL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: kAccent,
                    size: 44),
              ),
              const SizedBox(height: 20),
              const Text('ابدأ التشخيص أولاً',
                  style: TextStyle(
                      color: kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'قم بتحليل أعراضك أولاً لتتمكن\nمن التحدث مع المستشار الطبي',
                style: TextStyle(color: kMuted, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _tabCtrl.animateTo(0),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('ابدأ التحليل'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccent,
                  side: const BorderSide(color: kAccent, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: [
      // معلومة التشخيص في أعلى الدردشة
      Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kAccentL,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kAccent.withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.medical_information_outlined,
                color: kAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'استشارة حول: ${translateDisease(_result!.disease)}',
                style: const TextStyle(
                    color: kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),

      // محادثة
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(14),
          itemCount:
          _chatHistory.length + (_chatLoading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _chatHistory.length)
              return _bubble(isUser: false, msg: '', loading: true);
            final m = _chatHistory[i];
            return _bubble(
                isUser: m['role'] == 'user', msg: m['content'] ?? '');
          },
        ),
      ),

      // حقل الإدخال
      Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kBorder, width: 0.5)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: TextField(
                controller: _chatCtrl,
                style: const TextStyle(color: kText, fontSize: 13),
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendChat(),
                decoration: const InputDecoration(
                    hintText: 'اكتب سؤالك...',
                    hintTextDirection: TextDirection.rtl),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _chatLoading ? null : _sendChat,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _chatLoading ? kBorder : kAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _chatLoading
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ================================================================
  //  فقاعة الدردشة
  // ================================================================
  Widget _bubble(
      {required bool isUser, required String msg, bool loading = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isUser) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder, width: 0.5),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: kMuted, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? kAccentL : kSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isUser ? 3 : 14),
                    bottomRight: Radius.circular(isUser ? 14 : 3),
                  ),
                  border: Border.all(
                    color:
                    isUser ? kAccent.withOpacity(0.25) : kBorder,
                    width: 0.5,
                  ),
                ),
                child: loading
                    ? SizedBox(
                  height: 16,
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(delay: 0),
                        const SizedBox(width: 4),
                        _Dot(delay: 150),
                        const SizedBox(width: 4),
                        _Dot(delay: 300),
                      ]),
                )
                    : Text(
                  msg,
                  style: TextStyle(
                    color: isUser ? kAccent : kText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            if (!isUser) ...[
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kAccentL,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: kAccent.withOpacity(0.3), width: 0.5),
                ),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: kAccent, size: 14),
              ),
            ],
          ],
        ),
      );

  // ================================================================
  //  مساعدات
  // ================================================================
  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: child,
  );

  Widget _sectionLabel(String t) => Text(
    t,
    style: const TextStyle(
        color: kMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5),
  );
}

// ================================================================
//  نقطة التحميل (Typing indicator)
// ================================================================
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay),
            () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 6,
      height: 6,
      decoration:
      const BoxDecoration(color: kMuted, shape: BoxShape.circle),
    ),
  );
}
