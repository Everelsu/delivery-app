import 'package:flutter/material.dart';
import '../../app/theme.dart';

class Promo {
  Promo(this.title, this.desc, this.reward, this.current, this.target, {this.joined = false});
  final String title;
  final String desc;
  final int reward;
  final int current;
  final int target;
  bool joined;
  double get progress => (current / target).clamp(0, 1);
  bool get done => current >= target;
}

class PromosPage extends StatefulWidget {
  const PromosPage({super.key});
  @override
  State<PromosPage> createState() => _PromosPageState();
}

class _PromosPageState extends State<PromosPage> {
  final _promos = [
    Promo('15 доставок за день', 'до конца дня', 500, 9, 15, joined: true),
    Promo('Марафон недели', '60 доставок за 7 дней', 1500, 41, 60, joined: true),
    Promo('Вечер пятницы', '5 доставок с 18:00', 300, 2, 5),
    Promo('Ранняя пташка', 'слот с началом до 09:00', 200, 0, 1),
  ];

  @override
  Widget build(BuildContext context) {
    final mine = _promos.where((p) => p.joined).toList();
    final other = _promos.where((p) => !p.joined).toList();

    return ListenableBuilder(
      listenable: ThemeController.I,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                // Главное — сколько уже заработано бонусами.
                Text('Бонусы', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₽ 2 800',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -1.2, color: AppColors.ink)),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text('в июле',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.muted)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Начислится вместе с выплатой в четверг',
                    style: Theme.of(context).textTheme.bodySmall),

                if (mine.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _Header('Мои акции'),
                  ...mine.map((p) => _PromoRow(promo: p, onTap: () => _toggle(p))),
                ],

                if (other.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _Header('Доступные'),
                  ...other.map((p) => _PromoRow(promo: p, onTap: () => _toggle(p))),
                ],

                const SizedBox(height: 28),
                Text('Бонусы обновляются в начале месяца. Размер зависит от числа доставок и рейтинга.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggle(Promo p) {
    setState(() => p.joined = !p.joined);
  }
}

class _Header extends StatelessWidget {
  // Намеренно не const: читает AppColors, const-экземпляр не перекрасится.
  // ignore: prefer_const_constructors_in_immutables
  _Header(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.8)),
    );
  }
}

/// Плоская строка акции: название, награда, тонкий прогресс.
class _PromoRow extends StatelessWidget {
  const _PromoRow({required this.promo, required this.onTap});
  final Promo promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = promo;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(p.desc, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('+${p.reward} ₽',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: p.done ? AppColors.success : AppColors.inkSoft)),
                  ],
                ),
                if (p.joined) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: p.progress,
                            minHeight: 5,
                            backgroundColor: AppColors.line,
                            valueColor: AlwaysStoppedAnimation(p.done ? AppColors.success : AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${p.current}/${p.target}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.muted)),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Участвовать',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ),
                ],
              ],
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}
