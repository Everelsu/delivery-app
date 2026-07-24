import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';

/// Логотип-заглушка «Спринт» — оригинальная марка, рисуется кодом.
class SprintLogo extends StatelessWidget {
  const SprintLogo({super.key, this.size = 44, this.showWordmark = true});
  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.62),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Text(
          'Спринт',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.expand = true,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? const SizedBox(
              key: ValueKey('l'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              key: const ValueKey('c'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
    final btn = SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: child,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Ввод кода отдельными ячейками (как в нормальных приложениях).
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
  });
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  String get _text => _ctrl.text;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final filled = i < _text.length;
              final active = i == _text.length && _focus.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 58,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.line,
                    width: active ? 2 : 1.4,
                  ),
                ),
                child: Text(
                  filled ? _text[i] : '',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: 0),
                ),
              );
            }),
          ),
          // Невидимое поле — принимает ввод, автозаполнение из SMS и вставку.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged?.call(v);
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }
}

/// Живой таймер обратного отсчёта до [deadline]. Краснеет на исходе.
class CountdownChip extends StatefulWidget {
  const CountdownChip({super.key, required this.deadline, this.label = 'Передать за'});
  final DateTime deadline;
  final String label;
  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    final overdue = left.isNegative;
    final abs = left.abs();
    final mm = abs.inMinutes.toString().padLeft(2, '0');
    final ss = (abs.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = !overdue && left.inMinutes < 3;
    final color = overdue
        ? AppColors.danger
        : urgent
            ? AppColors.warning
            : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(overdue ? Icons.warning_amber_rounded : Icons.timer_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(overdue ? 'Опоздание' : widget.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              Text('${overdue ? '−' : ''}$mm:$ss',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5, height: 1)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

/// Кнопка «зажми, чтобы подтвердить» — заполняется по мере удержания,
/// срабатывает при полном заполнении. Отпустил раньше — откат.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.onConfirm,
    this.icon = Icons.check_rounded,
    this.color = AppColors.primary,
    this.duration = const Duration(milliseconds: 1900),
  });
  final String label;
  final VoidCallback onConfirm;
  final IconData icon;
  final Color color;
  final Duration duration;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 200), // откат — быстрый
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_done) {
          _done = true;
          HapticFeedback.mediumImpact();
          widget.onConfirm();
        }
      });
  }

  void _start(_) {
    if (_done) return;
    HapticFeedback.selectionClick();
    _c.forward();
  }

  void _cancel([_]) {
    if (_done) return;
    _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _start,
      onTapUp: _cancel,
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return SizedBox(
            height: 56,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, cons) {
                final w = cons.maxWidth;
                // Два одинаковых слоя: нижний в цвете, верхний белый и подрезан
                // по прогрессу. Текст не меняется, цвет «протекает» попиксельно.
                return Stack(
                  children: [
                    _layer(w, widget.color.withValues(alpha: 0.16), widget.color),
                    ClipRect(
                      clipper: _SweepClipper(_c.value),
                      child: _layer(w, widget.color, Colors.white),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _layer(double w, Color bg, Color fg) => Container(
        width: w,
        height: 56,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}

class _SweepClipper extends CustomClipper<Rect> {
  _SweepClipper(this.p);
  final double p;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * p, size.height);
  @override
  bool shouldReclip(_SweepClipper old) => old.p != p;
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onPressed, this.icon, this.color});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? AppColors.ink,
          side: BorderSide(color: AppColors.line, width: 1.4),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Круглая аватарка с инициалами.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 44, this.color = AppColors.violet});
  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * 0.36),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
