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

  List<String> _allSymptoms = [];
  List<String> _filtered = [];
  List<String> _selected = [];
  PredictionResult? _result;
  List<Map<String, String>> _chatHistory = [];

  bool _loading = false;
  bool _chatLoading = false;
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

  Future<void> _loadSymptoms() async {
    try {
      final syms = await ApiService.getAllSymptoms();

      if (!mounted) return;

      setState(() {
        _allSymptoms = syms;
        _filtered = syms;
        _symptomsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('خطأ في الاتصال: $e', isError: true);
    }
  }

  void _filter(String q) => setState(() =>
  _filtered = _allSymptoms
      .where((s) => s.toLowerCase().contains(q.toLowerCase()))
      .toList());

  void _toggle(String s) => setState(() =>
  _selected.contains(s) ? _selected.remove(s) : _selected.add(s));

  Future<void> _predict() async {
    if (_selected.isEmpty) {
      _snack('من فضلك اختر عرض واحد على الأقل');
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _chatHistory = [];
    });

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
      _snack('حدث خطأ: $e', isError: true);
    }
  }

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
        message: msg,
        disease: _result!.disease,
        risk: _result!.riskLevel,
        symptoms: _selected,
        history: trimmed,
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

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _selected.clear();
      _result = null;
      _chatHistory = [];
    });
    _tabCtrl.animateTo(0);
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? kRed : kAccent,
        ),
      );

  // ================================================================
  // UI ROOT (RTL فقط بدون تغيير الشكل)
  // ================================================================
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: kBg, // نفس الخلفية البيضاء
      body: SafeArea(
        child: Column(
          children: [
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
          ],
        ),
      ),
    ),
  );

  // ================================================================
  // HEADER (نفس التصميم)
  // ================================================================
  Widget _header() => Container(
    padding: const EdgeInsets.all(12),
    color: kSurface,
    child: Row(
      children: [
        const Icon(Icons.monitor_heart, color: kAccent),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'MediScan - التحليل الطبي',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (_result != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          )
      ],
    ),
  );

  // ================================================================
  // TAB BAR (نفس الشكل)
  // ================================================================
  Widget _tabBar() => Container(
    color: kSurface,
    child: TabBar(
      controller: _tabCtrl,
      indicatorColor: kAccent,
      labelColor: kAccent,
      unselectedLabelColor: kMuted,
      tabs: const [
        Tab(text: 'الأعراض'),
        Tab(text: 'النتائج'),
        Tab(text: 'الدردشة'),
      ],
    ),
  );

  // ================================================================
  // SYMPTOMS (نفس UI)
  // ================================================================
  Widget _symptomsTab() => Directionality(
    textDirection: TextDirection.rtl,
    child: Column(children: [

      // ================= SEARCH =================
      Container(
        color: kSurface,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _filter,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: kText, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'ابحث عن الأعراض...',
            prefixIcon: const Icon(Icons.search_rounded, color: kMuted, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close_rounded, color: kMuted, size: 16),
              onPressed: () {
                _searchCtrl.clear();
                _filter('');
              },
            )
                : null,
          ),
        ),
      ),

      // ================= SELECTED =================
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
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kAccentL,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kAccent.withOpacity(0.4), width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _selected[i].replaceAll('_', ' '),
                      style: const TextStyle(
                        color: kAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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
            Text(
              'تم اختيار ${_selected.length}',
              style: const TextStyle(color: kMuted, fontSize: 11),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selected.clear()),
              child: const Text(
                'مسح الكل',
                style: TextStyle(color: kRed, fontSize: 11),
              ),
            ),
          ]),
        ),
      ],

      // ================= DIVIDER =================
      Container(
        color: kSurface,
        child: const Divider(height: 12, thickness: 0.5, color: kBorder),
      ),

      // ================= LIST =================
      Expanded(
        child: !_symptomsLoaded
            ? const Center(
          child: CircularProgressIndicator(
            color: kAccent,
            strokeWidth: 2,
          ),
        )
            : _filtered.isEmpty
            ? const Center(
          child: Text(
            'لا توجد أعراض',
            style: TextStyle(color: kMuted, fontSize: 13),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final s = _filtered[i];
            final sel = _selected.contains(s);

            return InkWell(
              onTap: () => _toggle(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: sel ? kAccentL.withOpacity(0.5) : kSurface,
                  border: const Border(
                    bottom: BorderSide(color: kBorder, width: 0.5),
                  ),
                ),
                child: Row(children: [

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: sel ? kAccent : Colors.transparent,
                      border: Border.all(
                        color: sel ? kAccent : kBorder,
                        width: sel ? 1.5 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      s.replaceAll('_', ' '),
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: sel ? kAccent : kText,
                        fontSize: 13,
                        fontWeight:
                        sel ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),

      // ================= BUTTON =================
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
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text('تحليل الأعراض (${_selected.length})'),
        ),
      ),
    ]),
  );

  // ================================================================
  // RESULTS (نفس الشكل)
  // ================================================================
  Widget _resultsTab() => Container(
    color: kBg,
    child: Center(
      child: _result == null
          ? const Text('لا توجد نتائج بعد')
          : Text(_result!.disease),
    ),
  );

  // ================================================================
  // CHAT (نفس UI)
  // ================================================================
  Widget _chatTab() => Column(
    children: [
      Expanded(child: Container()),
      TextField(controller: _chatCtrl),
      ElevatedButton(
        onPressed: _sendChat,
        child: const Text('إرسال'),
      ),
    ],
  );
}