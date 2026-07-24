import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../chat/chat_page.dart';
import '../notifications/notices_page.dart';
import 'order_actions.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        // Несколько заказов ведутся независимо; ближайший — выше.
        final active = [...store.inProgress]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        final queue = store.offered;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => Future.delayed(const Duration(milliseconds: 700)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                children: [
                  _StatusLine(
                    store: store,
                    onBell: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const NoticesPage())),
                  ),
                  const SizedBox(height: 18),

                  // 1. Что делать прямо сейчас.
                  if (active.isNotEmpty)
                    ...active.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ActiveTask(
                            order: e.value,
                            nearest: active.length > 1 && e.key == 0,
                            total: active.length,
                          ),
                        ))
                  else
                    _Idle(store: store),

                  // 2. Что дальше — тихим списком.
                  if (queue.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _QuietHeader('Далее', trailing: '${queue.length}'),
                    const SizedBox(height: 4),
                    ..._withDividers(queue
                        .map((o) => _QueueRow(
                              order: o,
                              onTap: () => _open(context, o),
                              onStart: () => performPrimary(context, o),
                            ))
                        .toList()),
                  ],

                  // 3. Итоги дня — одной строкой.
                  const SizedBox(height: 26),
                  _TodayLine(store: store),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _withDividers(List<Widget> rows) {
    final out = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i < rows.length - 1) {
        out.add(Divider(height: 1, color: AppColors.line, indent: 4, endIndent: 4));
      }
    }
    return out;
  }

  void _open(BuildContext context, DeliveryOrder o) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id)));
  }
}

// ─────────────── 0. Статус: одна тихая строка ───────────────

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.store, required this.onBell});
  final AppStore store;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final onLine = store.onLine;
    final color = store.paused
        ? AppColors.warning
        : onLine
            ? AppColors.success
            : AppColors.faint;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => showLineSheet(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: onLine ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 7)] : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(store.lineLabel,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                if (store.onSlot)
                  Text('  ·  до 13:00', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 18, color: AppColors.faint),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: onBell,
          visualDensity: VisualDensity.compact,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, color: AppColors.muted, size: 22),
              if (store.unreadNotices > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 15),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.bg, width: 1.5),
                    ),
                    child: Text('${store.unreadNotices}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 9.5)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Управление линией вынесено в лист — на экране не мешает.
void showLineSheet(BuildContext context) {
  final store = AppStore.I;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => ActionSheet(
        title: 'Статус работы',
        subtitle: store.onLine ? 'Заказы назначаются автоматически' : 'Заказы не приходят',
        children: [
          ActionSheetOption(
            icon: Icons.event_available_rounded,
            color: AppColors.success,
            title: 'Слот',
            sub: store.onSlot ? 'Активен · 09:00–13:00' : 'Нет активного слота',
            highlight: store.onSlot,
            onTap: () => Navigator.pop(ctx),
          ),
          ActionSheetOption(
            icon: Icons.storefront_rounded,
            color: AppColors.primary,
            title: store.exchangeOn ? 'Биржа включена' : 'Включить Биржу',
            sub: 'Заказы без запланированного слота',
            highlight: store.exchangeOn,
            onTap: store.toggleExchange,
          ),
          ActionSheetOption(
            icon: store.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: AppColors.warning,
            title: store.paused ? 'Продолжить работу' : 'Взять паузу',
            sub: 'Пауза доступна между заказами',
            highlight: store.paused,
            onTap: store.togglePause,
          ),
        ],
      ),
    ),
  );
}

// ─────────────── 1. Активная задача ───────────────

class _ActiveTask extends StatelessWidget {
  const _ActiveTask({required this.order, this.nearest = false, this.total = 1});
  final DeliveryOrder order;
  final bool nearest;
  final int total;

  @override
  Widget build(BuildContext context) {
    final toClient = order.stage == OrderStage.toClient;
    final stageText = switch (order.stage) {
      OrderStage.toStore => 'ЕДУ В МАГАЗИН',
      OrderStage.atStore => 'ЗАБРАТЬ НА КАССЕ',
      OrderStage.toClient => 'ВЕЗУ КЛИЕНТУ',
      _ => 'В РАБОТЕ',
    };
    final address = toClient ? order.clientAddressShort : order.storeName;
    final sub = toClient ? _doorInfo(order) : order.storeAddress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id))),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(stageText,
                          style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              letterSpacing: 0.8)),
                      if (nearest) ...[
                        const SizedBox(width: 8),
                        const Pill(text: 'ближе', color: AppColors.primary),
                      ],
                      const Spacer(),
                      if (order.currentDeadline != null)
                        _Timer(deadline: order.currentDeadline!, label: order.deadlineLabel),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Главное — адрес.
                  Text(address,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          height: 1.15,
                          letterSpacing: -0.8,
                          color: AppColors.ink)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(sub,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ],
                  if (toClient) ..._criticalNotes(context, order),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              children: [
                OrderPrimaryButton(order: order),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Маршрут — самое частое действие в движении, держим на виду.
                    Expanded(
                      child: _TonalButton(
                        icon: Icons.navigation_rounded,
                        label: 'Маршрут',
                        onTap: () => showNavigatorChooser(context,
                            toClient: toClient,
                            address: toClient ? order.clientAddressFull : order.storeAddress),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconButton(
                      icon: Icons.call_rounded,
                      tooltip: 'Позвонить',
                      onTap: () => showCallSheet(context, order),
                    ),
                    const SizedBox(width: 8),
                    _IconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      tooltip: 'Чат',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => ChatPage(orderId: order.id))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _doorInfo(DeliveryOrder o) {
    final parts = <String>[];
    if (o.entrance != null) parts.add('подъезд ${o.entrance}');
    if (o.floor != null) parts.add('этаж ${o.floor}');
    if (o.apartment != null) parts.add('кв. ${o.apartment}');
    return parts.join(' · ');
  }

  /// Только то, что критично не забыть у двери.
  List<Widget> _criticalNotes(BuildContext context, DeliveryOrder o) {
    final notes = <(IconData, String, Color)>[];
    if (o.needsAgeCheck) notes.add((Icons.badge_rounded, 'Проверить паспорт · 18+', AppColors.danger));
    if (o.leaveAtDoor) notes.add((Icons.door_front_door_rounded, 'Оставить у двери', AppColors.inkSoft));
    if (o.noDoorbell) notes.add((Icons.notifications_off_rounded, 'Не звонить в дверь', AppColors.inkSoft));
    if (notes.isEmpty) return [];
    return [
      const SizedBox(height: 14),
      ...notes.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(n.$1, size: 17, color: n.$3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(n.$2,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: n.$3)),
                ),
              ],
            ),
          )),
    ];
  }
}

/// Компактный таймер: только цифры, цвет только когда горит.
class _Timer extends StatefulWidget {
  const _Timer({required this.deadline, required this.label});
  final DateTime deadline;
  final String label;
  @override
  State<_Timer> createState() => _TimerState();
}

class _TimerState extends State<_Timer> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    final over = left.isNegative;
    final abs = left.abs();
    final urgent = !over && left.inMinutes < 5;
    final color = over
        ? AppColors.danger
        : urgent
            ? AppColors.warning
            : AppColors.muted;
    final txt = '${abs.inMinutes.toString().padLeft(2, '0')}:${(abs.inSeconds % 60).toString().padLeft(2, '0')}';
    return Row(
      children: [
        Icon(over ? Icons.warning_amber_rounded : Icons.schedule_rounded, size: 16, color: color),
        const SizedBox(width: 5),
        Text(over ? 'опоздание ' : '${widget.label} ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.muted)),
        Text('${over ? '−' : ''}$txt',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color, letterSpacing: -0.3)),
      ],
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

class _TonalButton extends StatelessWidget {
  const _TonalButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: AppColors.inkSoft),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w800, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 20, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

// ─────────────── Простой режим ожидания ───────────────

class _Idle extends StatelessWidget {
  const _Idle({required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final onLine = store.onLine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(onLine ? Icons.radar_rounded : Icons.pause_circle_outline_rounded,
              size: 40, color: onLine ? AppColors.primary : AppColors.faint),
          const SizedBox(height: 14),
          Text(onLine ? 'Ищем заказы' : 'Вы не на линии',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.ink)),
          const SizedBox(height: 6),
          if (onLine)
            _Countdown()
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: store.toggleExchange,
                child: const Text('Включить Биржу',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  // Намеренно не const: виджет читает AppColors (глобальные), и const-экземпляр
  // не перестроится при смене темы.
  // ignore: prefer_const_constructors_in_immutables
  _Countdown();
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  static const _period = 120;
  int _left = _period;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _left = _left <= 1 ? _period : _left - 1));
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Text('Проверка через $mm:$ss',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 14));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

// ─────────────── 2. Очередь ───────────────

class _QuietHeader extends StatelessWidget {
  const _QuietHeader(this.title, {this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.8)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.order, required this.onTap, required this.onStart});
  final DeliveryOrder order;
  final VoidCallback onTap;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.clientAddressShort,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('${order.distanceKm} км · ₽ ${order.total}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            // Любой заказ можно взять в работу сразу — порядок не навязываем.
            TextButton(
              onPressed: onStart,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Начать',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

// ─────────────── 3. Итог дня ───────────────

class _TodayLine extends StatelessWidget {
  const _TodayLine({required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text('Сегодня',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.muted)),
          const Spacer(),
          Text('${store.todayDeliveries} дост.',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.inkSoft)),
          Text('  ·  ', style: TextStyle(color: AppColors.faint)),
          Text('${store.todayKm} км',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.inkSoft)),
          Text('  ·  ', style: TextStyle(color: AppColors.faint)),
          Text('₽ ${store.todayEarned}',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: AppColors.ink)),
        ],
      ),
    );
  }
}
