import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/notifications.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';

class SlotsPage extends StatefulWidget {
  const SlotsPage({super.key});
  @override
  State<SlotsPage> createState() => _SlotsPageState();
}

class _SlotsPageState extends State<SlotsPage> {
  int _day = 0; // индекс выбранного дня

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        // Дни в порядке появления — по ним и листаем.
        final days = <String>[];
        for (final s in store.slots) {
          if (!days.contains(s.day)) days.add(s.day);
        }
        if (_day >= days.length) _day = 0;

        final mine = store.slots.where((s) => s.status != SlotStatus.open).toList();
        final dayName = days.isEmpty ? '' : days[_day];
        final daySlots = store.slots.where((s) => s.day == dayName).toList()
          ..sort((a, b) => a.from.compareTo(b.from));
        final plannedHours = mine.length * 4;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Шапка: сколько запланировано + закреплённые полигоны.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Запланировано', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$plannedHours ч',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 32,
                                  letterSpacing: -1.2,
                                  color: AppColors.ink)),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('на неделю',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.muted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 15, color: AppColors.muted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text('Ваши полигоны: ${AppStore.assignedPolygons.join(', ')}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Переключатель дней — вместо простыни на неделю.
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = i == _day;
                      final has = store.slots.any((s) => s.day == days[i] && s.status != SlotStatus.open);
                      return GestureDetector(
                        onTap: () => setState(() => _day = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.line),
                          ),
                          child: Row(
                            children: [
                              Text(days[i],
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: selected ? Colors.white : AppColors.inkSoft)),
                              if (has) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.white : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Слоты выбранного дня.
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      if (daySlots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('На этот день слотов нет',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        )
                      else
                        ...daySlots.map((s) => _SlotRow(
                              slot: s,
                              onToggle: () => store.toggleSlot(s),
                              onRemind: s.status == SlotStatus.open
                                  ? null
                                  : () {
                                      store.toggleReminder(s);
                                      if (s.remindMe) {
                                        AppNotifications.show(context,
                                            title: 'Напомним за 15 минут',
                                            body: '${s.day} · ${s.range} · ${s.polygon}',
                                            icon: Icons.notifications_active_rounded,
                                            color: AppColors.primary);
                                      }
                                    },
                            )),
                      const SizedBox(height: 18),
                      Text('Отказаться от слота можно не позднее чем за 2 часа до начала.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Плоская строка слота.
class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.onToggle, this.onRemind});
  final WorkSlot slot;
  final VoidCallback onToggle;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final isOpen = slot.status == SlotStatus.open;
    final isActive = slot.status == SlotStatus.active;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(slot.range,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: isActive ? AppColors.primary : AppColors.ink)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.polygon,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.inkSoft)),
                    if (slot.promo != null)
                      Text(slot.promo!,
                          style: const TextStyle(
                              color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              if (isActive)
                Text('идёт',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13.5))
              else if (isOpen) ...[
                Text('₽${slot.perHour}/ч',
                    style: TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onToggle,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Взять',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ] else ...[
                if (onRemind != null)
                  IconButton(
                    onPressed: onRemind,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Напоминание за 15 минут',
                    icon: Icon(
                      slot.remindMe
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 20,
                      color: slot.remindMe ? AppColors.primary : AppColors.faint,
                    ),
                  ),
                IconButton(
                  onPressed: () => _confirmDrop(context),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Отказаться от слота',
                  icon: Icon(Icons.close_rounded, size: 19, color: AppColors.faint),
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }

  /// Отказ от слота — действие с последствиями, подтверждаем удержанием.
  void _confirmDrop(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration:
            BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Отказаться от слота?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${slot.day} · ${slot.range} · ${slot.polygon}',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Частые отказы снижают рейтинг',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            HoldButton(
              label: 'Отказаться',
              icon: Icons.close_rounded,
              color: AppColors.danger,
              onConfirm: () {
                Navigator.pop(ctx);
                onToggle();
              },
            ),
            const SizedBox(height: 5),
            Text('Удерживайте 2 секунды',
                style: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 10),
            GhostButton(label: 'Оставить слот', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }
}
