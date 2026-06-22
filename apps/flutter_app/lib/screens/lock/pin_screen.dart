import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/services/pin_service.dart';

/// Экран PIN-кода: установка (с подтверждением) или разблокировка.
class PinScreen extends StatefulWidget {
  /// true — установка нового PIN (с подтверждением); false — разблокировка.
  final bool setup;

  /// Вызывается при успехе. Если null — экран сам делает Navigator.pop(true).
  final VoidCallback? onSuccess;

  /// Можно ли закрыть экран (для разблокировки на входе — нельзя).
  final bool canCancel;

  const PinScreen({super.key, this.setup = false, this.onSuccess, this.canCancel = true});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  final _pinService = PinService();
  String _pin = '';
  String? _firstPin; // для подтверждения при установке
  String _error = '';
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  String get _title {
    if (!widget.setup) return 'Введите PIN-код';
    return _firstPin == null ? 'Придумайте PIN-код' : 'Повторите PIN-код';
  }

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = '';
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _process);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _process() async {
    if (widget.setup) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
        });
      } else if (_firstPin == _pin) {
        await _pinService.setPin(_pin);
        if (!mounted) return;
        _success();
      } else {
        _fail('PIN-коды не совпадают');
        setState(() => _firstPin = null);
      }
    } else {
      final ok = await _pinService.verify(_pin);
      if (!mounted) return;
      if (ok) {
        _success();
      } else {
        _fail('Неверный PIN-код');
      }
    }
  }

  void _success() {
    HapticFeedback.lightImpact();
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _fail(String msg) {
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
    setState(() {
      _error = msg;
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canCancel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              if (widget.canCancel)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.close, color: AppColors.mutedForeground),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                )
              else
                AppSize.gapH(40),
              const Spacer(),
              Container(
                width: AppSize.s(64),
                height: AppSize.s(64),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.citrusOrange.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1)],
                ),
                child: Icon(Icons.lock_rounded, color: Colors.white, size: AppSize.s(30)),
              ),
              AppSize.gapH(20),
              Text(_title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(20), fontWeight: FontWeight.w700)),
              AppSize.gapH(8),
              SizedBox(
                height: AppSize.s(18),
                child: Text(_error, style: TextStyle(color: AppColors.destructive, fontSize: AppSize.s(13))),
              ),
              AppSize.gapH(16),
              // Точки
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final dx = math.sin(_shake.value * math.pi * 4) * 10 * (1 - _shake.value);
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      margin: AppSize.paddingH(8, 0),
                      width: AppSize.s(16),
                      height: AppSize.s(16),
                      decoration: BoxDecoration(
                        color: filled ? AppColors.citrusOrange : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: filled ? AppColors.citrusOrange : AppColors.subtleBorder, width: 2),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              _buildKeypad(),
              AppSize.gapH(24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    Widget key(String d) => _KeypadButton(label: d, onTap: () => _onDigit(d));
    return Padding(
      padding: AppSize.paddingH(40, 0),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [key('1'), key('2'), key('3')]),
          AppSize.gapH(16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [key('4'), key('5'), key('6')]),
          AppSize.gapH(16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [key('7'), key('8'), key('9')]),
          AppSize.gapH(16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SizedBox(width: AppSize.s(72)),
            key('0'),
            SizedBox(
              width: AppSize.s(72),
              height: AppSize.s(72),
              child: IconButton(
                icon: Icon(Icons.backspace_outlined, color: AppColors.mutedForeground),
                onPressed: _onBackspace,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSize.s(72),
        height: AppSize.s(72),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.foreground.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(26), fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
