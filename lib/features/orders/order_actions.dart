import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import '../chat/chat_page.dart';
import '../delivery/photo_confirm_page.dart';
import '../delivery/scan_page.dart';

/// Демо-координаты точек (Чита).
const kStoreLat = 52.0340, kStoreLon = 113.4990;
const kClientLat = 52.0268, kClientLon = 113.5165;

/// Подпись основного действия по стадии заказа.
/// Способ вручения определяется типом заказа (его выбирает заказчик).
String primaryActionLabel(DeliveryOrder o) => switch (o.stage) {
      OrderStage.offered => 'Начать · еду в магазин',
      OrderStage.toStore => 'Я в магазине',
      OrderStage.atStore => 'Отсканировать пакеты',
      OrderStage.toClient => o.leaveAtDoor ? 'Оставить у двери' : 'Отдать клиенту',
      _ => 'Далее',
    };

IconData primaryActionIcon(DeliveryOrder o) => switch (o.stage) {
      OrderStage.atStore => Icons.qr_code_scanner_rounded,
      OrderStage.toClient => o.leaveAtDoor ? Icons.door_front_door_rounded : Icons.volunteer_activism_rounded,
      _ => Icons.arrow_forward_rounded,
    };

/// Удержанием подтверждаем только вручение в руки — там нет другой проверки.
/// Взятие пакетов проверяется сканированием, доставка у двери — фото.
bool primaryNeedsHold(DeliveryOrder o) =>
    o.stage == OrderStage.toClient && !o.leaveAtDoor;

/// Выполняет основное действие. Способ вручения берётся из типа заказа —
/// курьера ни о чём не спрашиваем.
Future<void> performPrimary(
  BuildContext context,
  DeliveryOrder order, {
  bool popAfterDeliver = false,
}) async {
  final store = AppStore.I;

  // Взятие пакетов подтверждаем сканированием (резерв — 4-значный код).
  if (order.stage == OrderStage.atStore) {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ScanPage(order: order)),
    );
    if (ok == true) store.advance(order);
    return;
  }

  // Доставка «оставить у двери» — через экран фото.
  if (order.stage == OrderStage.toClient && order.leaveAtDoor) {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PhotoConfirmPage(order: order, leaveAtDoor: true)),
    );
    if (ok == true) {
      store.advance(order);
      if (popAfterDeliver && context.mounted) Navigator.pop(context);
    }
    return;
  }

  final wasDelivering = order.stage == OrderStage.toClient;
  store.advance(order);
  if (wasDelivering && popAfterDeliver && context.mounted) Navigator.pop(context);
}

/// Основная кнопка заказа: обычный тап или удержание — решает [primaryNeedsHold].
class OrderPrimaryButton extends StatelessWidget {
  const OrderPrimaryButton({super.key, required this.order, this.popAfterDeliver = false});
  final DeliveryOrder order;
  final bool popAfterDeliver;

  @override
  Widget build(BuildContext context) {
    void run() => performPrimary(context, order, popAfterDeliver: popAfterDeliver);

    if (!primaryNeedsHold(order)) {
      return PrimaryButton(
        label: primaryActionLabel(order),
        icon: primaryActionIcon(order),
        onPressed: run,
      );
    }
    return Column(
      children: [
        HoldButton(
          label: primaryActionLabel(order),
          icon: primaryActionIcon(order),
          onConfirm: run,
        ),
        const SizedBox(height: 5),
        Text('Удерживайте 2 секунды',
            style: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}

/// Выбор внешнего навигатора.
Future<void> showNavigatorChooser(BuildContext context, {required bool toClient, required String address}) async {
  final lat = toClient ? kClientLat : kStoreLat;
  final lon = toClient ? kClientLon : kStoreLon;

  Future<void> open(List<String> urls) async {
    for (final u in urls) {
      try {
        final uri = Uri.parse(u);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        // пробуем следующий вариант
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Приложение не установлено'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ));
    }
  }

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ActionSheet(
      title: 'Открыть маршрут',
      subtitle: address,
      children: [
        ActionSheetOption(
          icon: Icons.navigation_rounded,
          color: const Color(0xFFE30A17),
          title: 'Яндекс Навигатор',
          sub: 'Построит маршрут на авто',
          onTap: () {
            Navigator.pop(ctx);
            open([
              'yandexnavi://build_route_on_map?lat_to=$lat&lon_to=$lon',
              'https://yandex.ru/maps/?rtext=~$lat,$lon&rtt=auto',
            ]);
          },
        ),
        ActionSheetOption(
          icon: Icons.map_rounded,
          color: const Color(0xFFFFCC00),
          title: 'Яндекс Карты',
          sub: 'Пешком и на транспорте',
          onTap: () {
            Navigator.pop(ctx);
            open([
              'yandexmaps://maps.yandex.ru/?rtext=~$lat,$lon',
              'https://yandex.ru/maps/?rtext=~$lat,$lon',
            ]);
          },
        ),
        ActionSheetOption(
          icon: Icons.explore_rounded,
          color: const Color(0xFF3CB44B),
          title: '2ГИС',
          sub: 'Подробные дворы и подъезды',
          onTap: () {
            Navigator.pop(ctx);
            open([
              'dgis://2gis.ru/routeSearch/rsType/car/to/$lon,$lat',
              'https://2gis.ru/routeSearch/rsType/car/to/$lon,$lat',
            ]);
          },
        ),
        ActionSheetOption(
          icon: Icons.public_rounded,
          color: const Color(0xFF4285F4),
          title: 'Google Карты',
          sub: 'Универсальный вариант',
          onTap: () {
            Navigator.pop(ctx);
            open(['https://www.google.com/maps/dir/?api=1&destination=$lat,$lon']);
          },
        ),
      ],
    ),
  );
}

void showCallSheet(BuildContext context, DeliveryOrder order) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ActionSheet(
      title: 'Звонок',
      subtitle: 'Номер клиента скрыт — звоним через сервис',
      children: [
        ActionSheetOption(
          icon: Icons.call_rounded,
          color: AppColors.success,
          title: 'Позвонить клиенту',
          sub: order.clientName,
          onTap: () => Navigator.pop(ctx),
        ),
        ActionSheetOption(
          icon: Icons.support_agent_rounded,
          color: AppColors.info,
          title: 'Позвонить в поддержку',
          sub: 'Оператор Спринт',
          onTap: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

void showProblemSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ActionSheet(
      title: 'Проблема с заказом',
      children: [
        ActionSheetOption(
          icon: Icons.person_off_rounded,
          color: AppColors.warning,
          title: 'Клиент не выходит на связь',
          sub: 'Подскажем, что делать дальше',
          onTap: () => Navigator.pop(ctx),
        ),
        ActionSheetOption(
          icon: Icons.remove_shopping_cart_rounded,
          color: AppColors.warning,
          title: 'Товара нет в наличии',
          sub: 'Сообщим клиенту о замене',
          onTap: () => Navigator.pop(ctx),
        ),
        ActionSheetOption(
          icon: Icons.support_agent_rounded,
          color: AppColors.info,
          title: 'Написать в поддержку',
          sub: 'Чат с оператором',
          onTap: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage.support()));
          },
        ),
      ],
    ),
  );
}

// ─────────────────────────── Универсальный лист ───────────────────────────

class ActionSheet extends StatelessWidget {
  const ActionSheet({super.key, required this.title, this.subtitle, required this.children});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class ActionSheetOption extends StatelessWidget {
  const ActionSheetOption({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.onTap,
    this.highlight = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: highlight ? color.withValues(alpha: 0.10) : AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: highlight ? color.withValues(alpha: 0.4) : AppColors.line),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
                      Text(sub, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
