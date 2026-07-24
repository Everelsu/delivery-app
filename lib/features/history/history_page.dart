import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        // Группируем по дню, свежие сверху.
        final sorted = [...store.history]..sort((a, b) => b.date.compareTo(a.date));
        final groups = <String, List<HistoryEntry>>{};
        for (final e in sorted) {
          groups.putIfAbsent(_dayLabel(e.date), () => []).add(e);
        }
        final total = sorted.fold<int>(0, (a, b) => a + b.payout);

        return Scaffold(
          appBar: AppBar(title: const Text('История заказов')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text('Всего за период', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₽ $total',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          letterSpacing: -1.2,
                          color: AppColors.ink)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${sorted.length} доставок',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...groups.entries.expand((g) {
                final daySum = g.value.fold<int>(0, (a, b) => a + b.payout);
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6, left: 2, right: 2),
                    child: Row(
                      children: [
                        Text(g.key.toUpperCase(),
                            style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                letterSpacing: 0.8)),
                        const Spacer(),
                        Text('₽ $daySum',
                            style: TextStyle(
                                color: AppColors.inkSoft, fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  ...g.value.map((e) => _Row(entry: e)),
                ];
              }),
            ],
          ),
        );
      },
    );
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    const months = ['', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля',
      'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${d.day} ${months[d.month]}';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});
  final HistoryEntry entry;
  @override
  Widget build(BuildContext context) {
    final t = '${entry.date.hour.toString().padLeft(2, '0')}:'
        '${entry.date.minute.toString().padLeft(2, '0')}';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                child: Text(t,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.muted)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text('${entry.km} км', style: Theme.of(context).textTheme.bodySmall),
                        if (entry.leftAtDoor) ...[
                          Text(' · ', style: TextStyle(color: AppColors.faint)),
                          Icon(Icons.door_front_door_rounded, size: 12, color: AppColors.faint),
                          const SizedBox(width: 3),
                          Text('у двери', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text('₽ ${entry.payout}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkSoft)),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}
