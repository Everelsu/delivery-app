import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import '../chat/chat_page.dart';
import 'order_actions.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        final order = store.orders.firstWhere((o) => o.id == orderId);
        final nearClient = order.stage == OrderStage.toClient || order.stage == OrderStage.delivered;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Заказ'),
            actions: [
              IconButton(
                tooltip: 'Проблема с заказом',
                onPressed: () => showProblemSheet(context),
                icon: Icon(Icons.error_outline_rounded, color: AppColors.muted),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _HeaderCard(order: order),
              const SizedBox(height: 12),
              _NextStopCard(order: order),
              if (order.conditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ConditionsCard(order: order),
              ],
              if (nearClient) ...[
                const SizedBox(height: 12),
                _ClientCard(order: order),
              ],
              const SizedBox(height: 12),
              _ItemsCard(order: order),
              const SizedBox(height: 12),
              _PaymentCard(order: order),
            ],
          ),
          bottomNavigationBar: _ActionBar(order: order),
        );
      },
    );
  }
}

// ─────────────────────────── Шапка ───────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    const stages = [OrderStage.toStore, OrderStage.atStore, OrderStage.toClient, OrderStage.delivered];
    final idx = stages.indexOf(order.stage);
    final active = order.stage != OrderStage.delivered && order.stage != OrderStage.offered;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Доставка', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(order.clientAddressShort,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 21, color: AppColors.ink, letterSpacing: -0.5, height: 1.2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₽ ${order.total}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary, letterSpacing: -0.8)),
                  if (order.hasBoostedPay)
                    Text('вкл. +${order.surchargeTotal}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(order.stage.icon, size: 18, color: order.stage.color),
              const SizedBox(width: 6),
              Text(order.stage.label,
                  style: TextStyle(color: order.stage.color, fontWeight: FontWeight.w800, fontSize: 14.5)),
              const Spacer(),
              if (order.currentDeadline != null && active)
                CountdownChip(deadline: order.currentDeadline!, label: order.deadlineLabel),
            ],
          ),
          if (idx >= 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < stages.length; i++) ...[
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= idx ? order.stage.color : AppColors.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (i < stages.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── Куда ехать сейчас ───────────────────────────

class _NextStopCard extends StatelessWidget {
  const _NextStopCard({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final toClient = order.stage == OrderStage.toClient || order.stage == OrderStage.delivered;
    final title = switch (order.stage) {
      OrderStage.offered || OrderStage.toStore => 'Заберите в магазине',
      OrderStage.atStore => 'Заберите заказ на кассе',
      OrderStage.toClient => 'Отвезите клиенту',
      OrderStage.delivered => 'Доставлено',
      _ => 'Точка маршрута',
    };
    final place = toClient ? order.clientName : order.storeName;
    final address = toClient ? order.clientAddressFull : order.storeAddress;
    final color = toClient ? AppColors.primary : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(toClient ? Icons.location_on_rounded : Icons.storefront_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(place, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(address, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 5),
              Text('${order.distanceKm} км', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 14),
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 5),
              Text('~${order.etaMin} мин', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              GestureDetector(
                onTap: () => showNavigatorChooser(context, toClient: toClient, address: address),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Маршрут', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Блоки ───────────────────────────

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({required this.order});
  final DeliveryOrder order;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Важно по заказу', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: order.conditions.map((c) => Pill(text: c.label, color: c.color, icon: c.icon)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.order});
  final DeliveryOrder order;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(initials: order.clientName[0], size: 40, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.clientName, style: Theme.of(context).textTheme.titleMedium),
                    Text('Клиент', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tag('Подъезд', order.entrance ?? '—'),
              _tag('Этаж', order.floor ?? '—'),
              _tag('Квартира', order.apartment ?? '—'),
            ],
          ),
          if (order.comment != null) ...[
            const SizedBox(height: 14),
            _note(Icons.info_rounded, AppColors.warning, order.comment!),
          ],
          if (order.clientComment != null) ...[
            const SizedBox(height: 10),
            _note(Icons.chat_bubble_rounded, AppColors.violet, order.clientComment!, label: 'Комментарий клиента'),
          ],
        ],
      ),
    );
  }

  Widget _tag(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      );

  Widget _note(IconData icon, Color color, String text, {String? label}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                    const SizedBox(height: 2),
                  ],
                  Text(text,
                      style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final DeliveryOrder order;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Состав заказа', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${order.itemsCount} шт · ${order.weightKg.toStringAsFixed(1)} кг',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                      child: Text('${it.qty}',
                          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(it.name, style: Theme.of(context).textTheme.bodyLarge)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final DeliveryOrder order;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ваша оплата', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Базовая ставка', style: Theme.of(context).textTheme.bodyMedium)),
              Text('₽ ${order.payout}', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14)),
            ],
          ),
          ...order.surcharges.map((s) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(s.icon, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: Theme.of(context).textTheme.bodyMedium)),
                    Text('+ ${s.amount}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.line),
          ),
          Row(
            children: [
              Text('Итого', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
              const Spacer(),
              Text('₽ ${order.total}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.ink, letterSpacing: -0.6)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Нижняя панель ───────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final done = order.stage == OrderStage.delivered;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 10),
                Text('Заказ доставлен',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.call_rounded,
                    label: 'Позвонить',
                    color: AppColors.success,
                    onTap: () => showCallSheet(context, order),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Чат',
                    color: AppColors.info,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => ChatPage(orderId: order.id))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OrderPrimaryButton(order: order, popAfterDeliver: true),
          ],
        ],
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}
