import 'package:flutter/material.dart';
import '../app/theme.dart';

enum OrderStage { offered, toStore, atStore, toClient, delivered, canceled }

extension OrderStageX on OrderStage {
  String get label => switch (this) {
        OrderStage.offered => 'Назначен',
        OrderStage.toStore => 'Еду в магазин',
        OrderStage.atStore => 'В магазине',
        OrderStage.toClient => 'Везу клиенту',
        OrderStage.delivered => 'Доставлен',
        OrderStage.canceled => 'Отменён',
      };

  Color get color => switch (this) {
        OrderStage.offered => AppColors.violet,
        OrderStage.toStore => AppColors.info,
        OrderStage.atStore => AppColors.warning,
        OrderStage.toClient => AppColors.primary,
        OrderStage.delivered => AppColors.success,
        OrderStage.canceled => AppColors.danger,
      };

  IconData get icon => switch (this) {
        OrderStage.offered => Icons.assignment_ind_rounded,
        OrderStage.toStore => Icons.storefront_rounded,
        OrderStage.atStore => Icons.shopping_basket_rounded,
        OrderStage.toClient => Icons.directions_bike_rounded,
        OrderStage.delivered => Icons.check_circle_rounded,
        OrderStage.canceled => Icons.cancel_rounded,
      };
}

/// Особое условие заказа — бейдж в карточке (горячая еда, 18+, у двери и т.д.).
class OrderCondition {
  const OrderCondition(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

/// Доплата/акция к базовой стоимости заказа.
class Surcharge {
  const Surcharge(this.label, this.amount, {this.icon = Icons.add_rounded});
  final String label;
  final int amount; // ₽
  final IconData icon;
}

/// В сервисе все заказы предоплачены онлайн — оплаты на месте нет.
enum PayType { online }

extension PayTypeX on PayType {
  String get label => 'Оплачено онлайн';
  IconData get icon => Icons.verified_rounded;
}

class OrderItem {
  OrderItem(this.name, this.qty, {this.weightKg = 0});
  final String name;
  final int qty;
  final double weightKg;
}

class DeliveryOrder {
  DeliveryOrder({
    required this.id,
    required this.stage,
    required this.storeName,
    required this.storeAddress,
    required this.clientName,
    required this.clientAddressShort,
    required this.clientAddressFull,
    required this.distanceKm,
    required this.payout,
    required this.etaMin,
    required this.items,
    required this.payType,
    this.isExpress = false,
    this.comment,
    this.clientComment,
    this.entrance,
    this.floor,
    this.apartment,
    this.leaveAtDoor = false,
    this.noDoorbell = false,
    this.isHot = false,
    this.hasDrink = false,
    this.needsAgeCheck = false,
    this.isSuperfast = false,
    this.surcharges = const [],
    this.pickupBy,
    this.deadline,
  });

  final String id;
  OrderStage stage;
  final String storeName;
  final String storeAddress;
  final String clientName;
  final String clientAddressShort;
  final String clientAddressFull;
  final double distanceKm;
  final int payout; // ₽
  final int etaMin;
  final List<OrderItem> items;
  final PayType payType;
  final bool isExpress;
  final String? comment; // комментарий к адресу
  final String? clientComment; // комментарий от клиента
  final String? entrance;
  final String? floor;
  final String? apartment;

  // Особые условия заказа
  final bool leaveAtDoor; // оставить у двери
  final bool noDoorbell; // не звонить в дверь
  final bool isHot; // горячая еда
  final bool hasDrink; // напиток в заказе
  final bool needsAgeCheck; // 18+, проверить паспорт
  final bool isSuperfast; // суперфаст (оплата выше)
  final List<Surcharge> surcharges; // доплаты/акции
  final DateTime? pickupBy; // до какого времени забрать заказ в магазине
  final DateTime? deadline; // до какого времени передать клиенту

  /// Актуальный срок зависит от стадии: сначала забор, потом доставка.
  DateTime? get currentDeadline => switch (stage) {
        OrderStage.offered || OrderStage.toStore || OrderStage.atStore => pickupBy,
        OrderStage.toClient => deadline,
        _ => null,
      };

  String get deadlineLabel =>
      stage == OrderStage.toClient ? 'Передать до' : 'Забрать до';

  int get itemsCount => items.fold(0, (a, b) => a + b.qty);
  double get weightKg => items.fold(0.0, (a, b) => a + b.weightKg * b.qty);

  int get surchargeTotal => surcharges.fold(0, (a, b) => a + b.amount);
  int get total => payout + surchargeTotal;
  bool get hasBoostedPay => surchargeTotal > 0;

  /// Активные условия заказа для отображения бейджами.
  List<OrderCondition> get conditions => [
        if (leaveAtDoor) const OrderCondition(Icons.door_front_door_rounded, 'Оставить у двери', Color(0xFF6366F1)),
        if (noDoorbell) const OrderCondition(Icons.notifications_off_rounded, 'Не звонить в дверь', Color(0xFF6B7280)),
        if (needsAgeCheck) const OrderCondition(Icons.badge_rounded, '18+ · проверить паспорт', Color(0xFFEF4444)),
        if (isHot) const OrderCondition(Icons.local_fire_department_rounded, 'Горячая еда', Color(0xFFF97316)),
        if (hasDrink) const OrderCondition(Icons.local_cafe_rounded, 'Напиток в заказе', Color(0xFF0EA5E9)),
        if (isSuperfast) const OrderCondition(Icons.rocket_launch_rounded, 'Суперфаст', Color(0xFF00B8A9)),
      ];
}

class ChatMessage {
  ChatMessage(this.text, {required this.fromMe, required this.time, this.system = false});
  final String text;
  final bool fromMe;
  final DateTime time;
  final bool system;
}

/// Запись в истории доставок.
class HistoryEntry {
  const HistoryEntry({
    required this.date,
    required this.address,
    required this.payout,
    required this.km,
    this.leftAtDoor = false,
  });
  final DateTime date;
  final String address;
  final int payout;
  final double km;
  final bool leftAtDoor;
}

/// Уведомление в центре уведомлений.
enum NoticeKind { order, slot, payout, support, system }

extension NoticeKindX on NoticeKind {
  IconData get icon => switch (this) {
        NoticeKind.order => Icons.assignment_ind_rounded,
        NoticeKind.slot => Icons.event_available_rounded,
        NoticeKind.payout => Icons.payments_rounded,
        NoticeKind.support => Icons.support_agent_rounded,
        NoticeKind.system => Icons.info_rounded,
      };
  Color get color => switch (this) {
        NoticeKind.order => const Color(0xFF43A82E),
        NoticeKind.slot => const Color(0xFF6D4AE0),
        NoticeKind.payout => const Color(0xFF2FA84F),
        NoticeKind.support => const Color(0xFF2B7FFF),
        NoticeKind.system => const Color(0xFF6B7A70),
      };
}

class AppNotice {
  AppNotice({
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.unread = true,
  });
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime time;
  bool unread;
}

enum SlotStatus { open, planned, active }

extension SlotStatusX on SlotStatus {
  String get label => switch (this) {
        SlotStatus.open => 'Открытый',
        SlotStatus.planned => 'Запланирован',
        SlotStatus.active => 'Активен',
      };
  Color get color => switch (this) {
        SlotStatus.open => const Color(0xFF3B82F6),
        SlotStatus.planned => const Color(0xFF6366F1),
        SlotStatus.active => const Color(0xFF22C55E),
      };
}

class WorkSlot {
  WorkSlot({
    required this.id,
    required this.day,
    required this.from,
    required this.to,
    required this.polygon,
    required this.status,
    this.perHour = 320,
    this.promo,
    this.remindMe = false,
  });
  final String id;
  final String day; // «Сегодня», «Завтра» …
  final String from; // «09:00»
  final String to; // «13:00»
  final String polygon; // район/полигон
  SlotStatus status;
  final int perHour; // ставка ₽/ч (ориентир)
  final String? promo; // акция на слоте
  bool remindMe; // напоминание о слоте

  String get range => '$from – $to';
}

class Courier {
  Courier({
    required this.name,
    required this.phone,
    required this.rating,
    required this.vehicle,
    required this.deliveriesTotal,
    required this.balance,
  });
  final String name;
  final String phone;
  final double rating;
  final String vehicle;
  final int deliveriesTotal;
  final int balance;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }
}
