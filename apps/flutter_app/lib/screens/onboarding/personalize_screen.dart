import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_size.dart';
import '../../core/widgets/citrus_button.dart';
import '../../core/services/focus_prefs_service.dart';

/// Выбор целей пользователя — влияет на рекомендации курсов и подсказки.
/// Показывается один раз при первом запуске; доступен и из Настроек.
class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    FocusPrefsService().getFocus().then((f) {
      if (mounted) setState(() => _selected.addAll(f));
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FocusPrefsService().setFocus(_selected.toList());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSize.padding(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSize.gapH(8),
                        Text('Что для тебя сейчас важнее?', style: AppText.displayTitle),
                        AppSize.gapH(8),
                        Text(
                          'Подберём подходящие курсы и подсказки. Можно выбрать несколько — и поменять в любой момент.',
                          style: AppText.bodyMuted.copyWith(height: 1.5),
                        ),
                        AppSize.gapH(22),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: kFocusOptions.map((o) {
                            final sel = _selected.contains(o.key);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (sel) {
                                  _selected.remove(o.key);
                                } else {
                                  _selected.add(o.key);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: AppSize.paddingH(16, 12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.citrusOrange.withValues(alpha: 0.15)
                                      : AppColors.card,
                                  borderRadius: AppSize.radius(14),
                                  border: Border.all(
                                    color: sel ? AppColors.citrusOrange : AppColors.subtleBorder,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text(o.emoji, style: TextStyle(fontSize: AppSize.s(18))),
                                  AppSize.gapW(8),
                                  Text(
                                    o.label,
                                    style: TextStyle(
                                      color: sel ? AppColors.citrusOrange : AppColors.foreground,
                                      fontSize: AppSize.s(14),
                                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: AppSize.padding(24),
                  child: CitrusButton(
                    label: _selected.isEmpty ? 'Пропустить' : 'Готово',
                    onPressed: _save,
                    loading: _saving,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
