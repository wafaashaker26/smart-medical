//  HOME SCREEN
// ================================================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/models.dart';
import '../main.dart';

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
    _tabCtrl.dispose(); _searchCtrl.dispose();
    _chatCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    try {
      final syms = await ApiService.getAllSymptoms();
      setState(() { _allSymptoms = syms; _filtered = syms; _symptomsLoaded = true; });
    } catch (e) {
      _snack('Connection error: $e', isError: true);
    }
  }

  void _filter(String q) => setState(() =>
  _filtered = _allSymptoms
      .where((s) => s.toLowerCase().contains(q.toLowerCase()))
      .toList());

  void _toggle(String s) => setState(() =>
  _selected.contains(s) ? _selected.remove(s) : _selected.add(s));

  Future<void> _predict() async {
    if (_selected.isEmpty) { _snack('Select at least one symptom'); return; }
    setState(() { _loading = true; _result = null; _chatHistory = []; });
    try {
      final r = await ApiService.predict(_selected);
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
      _snack('Error: $e', isError: true);
    }
  }

  Future<void> _sendChat() async {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty || _result == null) return;
    _chatCtrl.clear();
    setState(() { _chatHistory.add({'role': 'user', 'content': msg}); _chatLoading = true; });
    _scrollDown();
    try {
      final trimmed = _chatHistory.length > 6
          ? _chatHistory.sublist(_chatHistory.length - 6)
          : List<Map<String, String>>.from(_chatHistory);

      final reply = await ApiService.chat(
        message:  msg,
        disease:  _result!.disease,
        risk:     _result!.riskLevel,
        symptoms: _selected,
        history:  trimmed,
      );
      setState(() { _chatHistory.add({'role': 'assistant', 'content': reply}); _chatLoading = false; });
      _scrollDown();
    } catch (e) {
      setState(() => _chatLoading = false);
      _snack('Error: $e', isError: true);
    }
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 200), () {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
    );
  });

  void _reset() {
    setState(() { _selected.clear(); _result = null; _chatHistory = []; });
    _tabCtrl.animateTo(0);
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: isError ? kRed : kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SafeArea(child: Column(children: [
      _header(),
      _tabBar(),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _symptomsTab(),
        _resultsTab(),
        _chatTab(),
      ])),
    ])),
  );

  // ---- HEADER ----
  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: const BoxDecoration(
      color: kSurface,
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MediScan', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Symptom analysis & diagnosis', style: TextStyle(color: kMuted, fontSize: 11)),
      ])),
      if (_result != null)
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: kMuted, size: 20),
          onPressed: _reset,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
    ]),
  );

  // ---- TAB BAR ----
  Widget _tabBar() => Container(
    color: kSurface,
    child: TabBar(
      controller: _tabCtrl,
      indicatorColor: kAccent,
      indicatorWeight: 1.5,
      labelColor: kAccent,
      unselectedLabelColor: kMuted,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      tabs: const [
        Tab(text: 'الأعراض'),
        Tab(text: 'النتائج'),
        Tab(text: 'الدردشة'),
      ],
    ),
  );

  // ================================================================
  //  TAB 1 — SYMPTOMS
  // ================================================================
  Widget _symptomsTab() => Column(children: [
    Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filter,
        style: const TextStyle(color: kText, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search symptoms...',
          prefixIcon: const Icon(Icons.search_rounded, color: kMuted, size: 18),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, color: kMuted, size: 16),
            onPressed: () { _searchCtrl.clear(); _filter(''); },
          )
              : null,
        ),
      ),
    ),

    if (_selected.isNotEmpty) ...[
      Container(
        color: kSurface,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selected.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _toggle(_selected[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kAccentL,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kAccent.withOpacity(0.4), width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _selected[i].replaceAll('_', ' '),
                    style: const TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.close_rounded, color: kAccent, size: 12),
                ]),
              ),
            ),
          ),
        ),
      ),
      Container(
        color: kSurface,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: Row(children: [
          Text('${_selected.length} selected', style: const TextStyle(color: kMuted, fontSize: 11)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selected.clear()),
            child: const Text('Clear all', style: TextStyle(color: kRed, fontSize: 11)),
          ),
        ]),
      ),
    ],

    Container(
      color: kSurface,
      child: const Divider(height: 12, thickness: 0.5, color: kBorder),
    ),

    Expanded(
      child: !_symptomsLoaded
          ? const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))
          : _filtered.isEmpty
          ? const Center(child: Text('No symptoms found', style: TextStyle(color: kMuted, fontSize: 13)))
          : ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final s   = _filtered[i];
          final sel = _selected.contains(s);
          return InkWell(
            onTap: () => _toggle(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: sel ? kAccentL.withOpacity(0.5) : kSurface,
                border: const Border(bottom: BorderSide(color: kBorder, width: 0.5)),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: sel ? kAccent : Colors.transparent,
                    border: Border.all(color: sel ? kAccent : kBorder, width: sel ? 1.5 : 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: sel
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  s.replaceAll('_', ' '),
                  style: TextStyle(
                    color: sel ? kAccent : kText,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    ),

    Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: ElevatedButton(
        onPressed: _loading ? null : _predict,
        child: _loading
            ? const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text('Analyze symptoms (${_selected.length})'),
      ),
    ),
  ]);

  // ================================================================
  //  TAB 2 — RESULTS
  // ================================================================
  Widget _resultsTab() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kAccent, strokeWidth: 2),
            SizedBox(height: 14),
            Text(
              'جاري التحليل...',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, color: kMuted, size: 40),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج بعد',
              style: TextStyle(
                color: kText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'اختر الأعراض وقم بالتحليل',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final r = _result!;
    final rColor =
    r.riskLevel == 'High'
        ? kRed
        : r.riskLevel == 'Medium'
        ? kYellow
        : kGreen;

    final rBg =
    r.riskLevel == 'High'
        ? kRedL
        : r.riskLevel == 'Medium'
        ? kYellowL
        : kGreenL;

    final rBd =
    r.riskLevel == 'High'
        ? kRedB
        : r.riskLevel == 'Medium'
        ? kYellowB
        : kGreenB;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [

          // ================= التشخيص الأساسي =================
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('التشخيص الأساسي'),
                const SizedBox(height: 10),
                Text(
                  r.disease,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),

                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rBd, width: 0.5),
                      ),
                      child: Text(
                        'درجة الخطورة: ${r.riskLevel}',
                        style: TextStyle(
                          color: rColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'النتيجة: ${r.riskScore}',
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ================= التشخيصات المحتملة =================
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('تشخيصات محتملة'),
                const SizedBox(height: 12),

                ...r.probabilities.map(
                      (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [

                        SizedBox(
                          width: 140,
                          child: Text(
                            p.disease,
                            style: const TextStyle(
                              color: kMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: p.probability,
                              minHeight: 5,
                              backgroundColor: kBorder,
                              valueColor:
                              const AlwaysStoppedAnimation(kAccent),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        SizedBox(
                          width: 50,
                          child: Text(
                            '${(p.probability * 100).toStringAsFixed(1)}%',
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              color: kText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ================= تحليل الأعراض =================
          // _card(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       _sectionLabel('تحليل الأعراض'),
          //       const SizedBox(height: 10),
          //
          //       ...r.explanation.map(
          //             (e) => Padding(
          //           padding: const EdgeInsets.symmetric(vertical: 5),
          //           child: Row(
          //             textDirection: TextDirection.rtl,
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Container(
          //                 width: 5,
          //                 height: 5,
          //                 margin: const EdgeInsets.only(top: 6),
          //                 decoration: const BoxDecoration(
          //                   color: kAccent,
          //                   shape: BoxShape.circle,
          //                 ),
          //               ),
          //               const SizedBox(width: 10),
          //               Expanded(
          //                 child: Text(
          //                   e,
          //                   style: const TextStyle(
          //                     color: kText,
          //                     fontSize: 13,
          //                     height: 1.5,
          //                   ),
          //                   textDirection: TextDirection.rtl,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 10),

          // ================= الملخص الطبي =================
          if (r.aiSummary.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('ملخص طبي'),
                  const SizedBox(height: 10),
                  Text(
                    r.aiSummary,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 13,
                      height: 1.6,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ================= متابعة =================
          OutlinedButton(
            onPressed: () => _tabCtrl.animateTo(2),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kBorder, width: 0.5),
              foregroundColor: kText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 46),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: kMuted),
                SizedBox(width: 8),
                Text(
                  'متابعة مع الاستشارة الذكية',
                  style: TextStyle(color: kMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  //  TAB 3 — CHAT / CONSULT
  // ================================================================
  Widget _chatTab() {
    if (_result == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: const Icon(Icons.chat_bubble_outline_rounded, color: kMuted, size: 40),
      ),
      const SizedBox(height: 16),
      const Text('Run a diagnosis first', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      const Text('Go to Symptoms tab to get started', style: TextStyle(color: kMuted, fontSize: 12)),
    ]));
    }

    return Column(children: [
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(14),
          itemCount: _chatHistory.length + (_chatLoading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _chatHistory.length) return _bubble(isUser: false, msg: '', loading: true);
            final m = _chatHistory[i];
            return _bubble(isUser: m['role'] == 'user', msg: m['content'] ?? '');
          },
        ),
      ),

      Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kBorder, width: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _chatCtrl,
              style: const TextStyle(color: kText, fontSize: 13),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendChat(),
              decoration: const InputDecoration(hintText: 'Ask a question...'),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _chatLoading ? null : _sendChat,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _chatLoading ? kBorder : kAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _chatLoading
                  ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ---- CHAT BUBBLE ----
  Widget _bubble({required bool isUser, required String msg, bool loading = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: kAccentL,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kAccent.withOpacity(0.3), width: 0.5),
            ),
            child: const Icon(Icons.monitor_heart_outlined, color: kAccent, size: 14),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? kAccentL : kSurface,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(14),
                topRight:    const Radius.circular(14),
                bottomLeft:  Radius.circular(isUser ? 14 : 3),
                bottomRight: Radius.circular(isUser ? 3 : 14),
              ),
              border: Border.all(
                color: isUser ? kAccent.withOpacity(0.25) : kBorder,
                width: 0.5,
              ),
            ),
            child: loading
                ? SizedBox(
              height: 16,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _Dot(delay: 0), const SizedBox(width: 4),
                _Dot(delay: 150), const SizedBox(width: 4),
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
              textDirection: isUser ? TextDirection.ltr : TextDirection.rtl,
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder, width: 0.5),
            ),
            child: const Icon(Icons.person_outline_rounded, color: kMuted, size: 14),
          ),
        ],
      ],
    ),
  );

  // ---- HELPERS ----
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
    t.toUpperCase(),
    style: const TextStyle(color: kMuted, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8),
  );
}
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 6, height: 6,
      decoration: const BoxDecoration(color: kMuted, shape: BoxShape.circle),
    ),
  );
}