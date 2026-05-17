import 'package:flutter/material.dart';
import '../../core/utils/daily_quote_service.dart';
import '../../core/utils/app_size.dart';

class AffirmationsPage extends StatefulWidget {
  AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  final _quoteService = DailyQuoteService();
  late List<Map<String, String>> _savedQuotes;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final _savedQuotes = [_quoteService.getQuoteForDate()];
  }

  void _nextQuote() {
    if (_currentIndex < _savedQuotes.length - 1) {
      setState(() => _currentIndex++);
    } else {
      final newQuote = _quoteService.getRandomQuote();
      setState(() {
        _savedQuotes.add(newQuote);
        _currentIndex++;
      });
    }
  }

  void _prevQuote() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Аффирмации')),
      body: Column(
        children: [
          AppSize.gapH(24),

          Padding(
            padding: AppSize.paddingH(20, 0),
            child: Text(
              'Твоя аффирмация',
              style: TextStyle(
                fontSize: AppSize.s(20),
                fontWeight: FontWeight.w600,
                color: Color(0xFFEDE8E0),
              ),
            ),
          ),

          AppSize.gapH(24),

          Expanded(
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: _savedQuotes.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final quote = _savedQuotes[index];
                final isActive = index == _currentIndex;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: AppSize.paddingH(8, 0),
                  child: Card(
                    elevation: isActive ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSize.radius(20),
                    ),
                    color: Color(0xFF1A1A2E),
                    child: Padding(
                      padding: AppSize.padding(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('✨', style: TextStyle(fontSize: AppSize.s(40))),
                          AppSize.gapH(24),
                          Text(
                            '«${quote['quote']}»',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSize.s(20),
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                              color: Color(0xFFC8B89A),
                            ),
                          ),
                          AppSize.gapH(24),
                          Container(
                            padding: AppSize.paddingH(12, 6),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 140, 66, 0.15),
                              borderRadius: AppSize.radius(12),
                            ),
                            child: Text(
                              quote['label'] ?? 'Аффирмация дня',
                              style: TextStyle(
                                fontSize: AppSize.s(12),
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF8C42),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: AppSize.paddingH(20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _prevQuote,
                    icon: Icon(Icons.chevron_left),
                    label: Text('Назад'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF8A8298),
                      side: BorderSide(color: Color(0xFF5A5468)),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSize.radius(12),
                      ),
                    ),
                  ),
                AppSize.gapW(16),
                ElevatedButton.icon(
                  onPressed: _nextQuote,
                  icon: Icon(Icons.chevron_right),
                  label: Text('Дальше'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8C42),
                    foregroundColor: Color(0xFF0C0C14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSize.radius(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
