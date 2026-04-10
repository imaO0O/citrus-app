import 'package:flutter/material.dart';
import '../../core/utils/daily_quote_service.dart';

class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

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
    _savedQuotes = [_quoteService.getQuoteForDate()];
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
      appBar: AppBar(title: const Text('Аффирмации')),
      body: Column(
        children: [
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Твоя аффирмация',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEDE8E0),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: _savedQuotes.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final quote = _savedQuotes[index];
                final isActive = index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: isActive ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: const Color(0xFF1A1A2E),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 24),
                          Text(
                            '«${quote['quote']}»',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                              color: Color(0xFFC8B89A),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 140, 66, 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              quote['label'] ?? 'Аффирмация дня',
                              style: const TextStyle(
                                fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _prevQuote,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Назад'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A8298),
                      side: const BorderSide(color: Color(0xFF5A5468)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _nextQuote,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Дальше'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    foregroundColor: const Color(0xFF0C0C14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
