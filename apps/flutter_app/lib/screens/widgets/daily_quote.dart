import 'package:flutter/material.dart';

class DailyQuote extends StatelessWidget {
  final String quote;
  final String label;

  const DailyQuote({
    super.key,
    this.quote = 'Каждый день — это новая возможность стать лучше. Ты справишься!',
    this.label = 'Аффирмация дня',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(255, 140, 66, 0.12),
              Color.fromRGBO(255, 173, 31, 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(255, 140, 66, 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '«$quote»',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: Color(0xFFC8B89A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5A5468),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
