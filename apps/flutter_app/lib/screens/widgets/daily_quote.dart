import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';

class DailyQuote extends StatelessWidget {
  final String quote;
  final String label;

  DailyQuote({
    super.key,
    this.quote = 'Каждый день — это новая возможность стать лучше. Ты справишься!',
    this.label = 'Аффирмация дня',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: AppSize.padding(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(255, 140, 66, 0.12),
              Color.fromRGBO(255, 173, 31, 0.08),
            ],
          ),
          borderRadius: AppSize.radius(16),
          border: Border.all(
            color: Color.fromRGBO(255, 140, 66, 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✨', style: TextStyle(fontSize: AppSize.s(20))),
            AppSize.gapW(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '«$quote»',
                    style: TextStyle(
                      fontSize: AppSize.s(14),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  AppSize.gapH(8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      color: AppColors.dimForeground,
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
