import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_size.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/citrus_button.dart';
import 'privacy_policy_screen.dart';

/// Экран явного согласия при первом запуске. Блокирующий: пользователь не
/// продолжит, пока не примет политику конфиденциальности и условия.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  /// Ключ флага согласия (версионируем — при смене политики можно поднять до v2).
  static const flagKey = 'privacy_consent_v1';

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _continue() async {
    if (!_accepted) return;
    setState(() => _saving = true);
    await StorageService().setString(ConsentScreen.flagKey, 'true');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: AppSize.padding(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: AppSize.s(96),
                      height: AppSize.s(96),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.citrusOrange.withValues(alpha: 0.22),
                          AppColors.citrusOrange.withValues(alpha: 0.04),
                        ]),
                        border: Border.all(color: AppColors.citrusOrange.withValues(alpha: 0.22)),
                      ),
                      child: Center(child: Text('🍊', style: TextStyle(fontSize: AppSize.s(44)))),
                    ),
                    AppSize.gapH(22),
                    Text('Добро пожаловать в Цитрус', style: AppText.displayTitle, textAlign: TextAlign.center),
                    AppSize.gapH(10),
                    Text(
                      'Мы бережно храним твои данные о настроении, сне и дневнике, не продаём их '
                      'и не передаём для рекламы. В любой момент ты можешь выгрузить или удалить всё в Настройках.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMuted.copyWith(height: 1.5),
                    ),
                    AppSize.gapH(20),
                    GestureDetector(
                      onTap: () => setState(() => _accepted = !_accepted),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: AppSize.s(24),
                            height: AppSize.s(24),
                            decoration: BoxDecoration(
                              color: _accepted ? AppColors.citrusOrange : Colors.transparent,
                              borderRadius: AppSize.radius(7),
                              border: Border.all(
                                color: _accepted ? AppColors.citrusOrange : AppColors.subtleBorder,
                                width: 1.5,
                              ),
                            ),
                            child: _accepted
                                ? Icon(Icons.check, size: AppSize.s(16), color: Colors.white)
                                : null,
                          ),
                          AppSize.gapW(12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: AppSize.s(2)),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Я принимаю ', style: AppText.body),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                                    ),
                                    child: Text(
                                      'политику конфиденциальности и условия',
                                      style: AppText.body.copyWith(
                                        color: AppColors.citrusOrange,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
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
                    AppSize.gapH(24),
                    CitrusButton(
                      label: 'Принять и продолжить',
                      onPressed: _accepted ? _continue : null,
                      loading: _saving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
