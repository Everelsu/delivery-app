import 'package:flutter/material.dart';
import 'models.dart';

/// Глобальный стор на моках. Никаких сетевых запросов — только заглушки,
/// имитирующие ответ бэкенда с задержкой.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  bool authed = false;

  // Режим линии: заказы приходят, если ты «на линии» — на слоте ИЛИ на Бирже.
  bool exchangeOn = false; // Биржа включена
  bool paused = false; // Пауза
  bool get onSlot => slots.any((s) => s.status == SlotStatus.active);
  bool get onLine => (onSlot || exchangeOn) && !paused;

  String get lineLabel {
    if (paused) return 'Пауза';
    if (!onLine) return 'Не на линии';
    if (onSlot) return 'На слоте';
    return 'Биржа';
  }

  final courier = Courier(
    name: 'Егор Дагбаев',
    phone: '+7 924 ••• 45 67',
    rating: 4.92,
    vehicle: 'Велосипед',
    deliveriesTotal: 1284,
    balance: 3860,
  );

  int todayEarned = 1740;
  int todayDeliveries = 6;
  int todayKm = 23;

  final List<DeliveryOrder> _orders = _seed();
  List<DeliveryOrder> get orders => _orders;

  DeliveryOrder? get active =>
      _orders.where((o) => o.stage != OrderStage.delivered && o.stage != OrderStage.offered).firstOrNull;

  List<DeliveryOrder> get offered => _orders.where((o) => o.stage == OrderStage.offered).toList();
  List<DeliveryOrder> get inProgress => _orders
      .where((o) => o.stage != OrderStage.offered && o.stage != OrderStage.delivered && o.stage != OrderStage.canceled)
      .toList();
  List<DeliveryOrder> get done => _orders.where((o) => o.stage == OrderStage.delivered).toList();

  /// Полигоны закрепляются за аккаунтом администратором — курьер видит
  /// слоты только по ним, а не все тысячи слотов по стране.
  static const assignedPolygons = ['Центр', 'Северный'];

  final List<WorkSlot> slots = _seedSlots();

  /// Слоты планируются на неделю вперёд (7 дней).
  static List<WorkSlot> _seedSlots() {
    const wd = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    const polygons = assignedPolygons;
    final now = DateTime.now();
    final list = <WorkSlot>[];
    int id = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.add(Duration(days: i));
      final label = switch (i) {
        0 => 'Сегодня',
        1 => 'Завтра',
        _ => '${wd[d.weekday]}, ${d.day}',
      };
      final windows = [
        ('09:00', '13:00', 330),
        ('13:00', '17:00', 340),
        ('17:00', '21:00', 360),
      ];
      for (int w = 0; w < windows.length; w++) {
        final poly = polygons[(i + w) % polygons.length];
        // Сегодня: первый слот активен, вечерний запланирован; остальные — открытые.
        SlotStatus status = SlotStatus.open;
        if (i == 0 && w == 0) status = SlotStatus.active;
        if (i == 0 && w == 2) status = SlotStatus.planned;
        if (i == 1 && w == 1) status = SlotStatus.planned;
        final promo = (w == 2)
            ? 'Вечерний бонус'
            : (i + w) % 3 == 0
                ? '+10% на полигоне'
                : null;
        list.add(WorkSlot(
          id: 'sl${id++}',
          day: label,
          from: windows[w].$1,
          to: windows[w].$2,
          polygon: poly,
          status: status,
          perHour: windows[w].$3,
          promo: promo,
        ));
      }
    }
    return list;
  }

  void toggleSlot(WorkSlot s) {
    if (s.status == SlotStatus.open) {
      s.status = SlotStatus.planned;
      s.remindMe = true; // при планировании сразу включаем напоминание
    } else if (s.status == SlotStatus.planned) {
      s.status = SlotStatus.open;
      s.remindMe = false;
    }
    notifyListeners();
  }

  void toggleReminder(WorkSlot s) {
    s.remindMe = !s.remindMe;
    notifyListeners();
  }

  // --- Настройки уведомлений (вкладка личных данных) ---
  bool notifyOrders = true;
  bool notifySlots = true;
  bool notifyPayouts = true;
  bool soundOn = true;
  bool vibrationOn = true;

  void setSetting(String key, bool v) {
    switch (key) {
      case 'orders':
        notifyOrders = v;
      case 'slots':
        notifySlots = v;
      case 'payouts':
        notifyPayouts = v;
      case 'sound':
        soundOn = v;
      case 'vibration':
        vibrationOn = v;
    }
    notifyListeners();
  }

  // --- Центр уведомлений ---
  final List<AppNotice> notices = [
    AppNotice(
      kind: NoticeKind.order,
      title: 'Назначен заказ',
      body: 'ул. Бабушкина, 104 · 2.4 км · ₽420',
      time: _ago(6),
    ),
    AppNotice(
      kind: NoticeKind.slot,
      title: 'Слот начнётся через 15 минут',
      body: 'Сегодня 17:00–21:00 · Центр',
      time: _ago(24),
    ),
    AppNotice(
      kind: NoticeKind.payout,
      title: 'Выплата зачислена',
      body: '₽ 12 480 за прошлую неделю',
      time: _ago(60 * 22),
      unread: false,
    ),
    AppNotice(
      kind: NoticeKind.support,
      title: 'Ответ поддержки',
      body: 'По вашему обращению о фотоконтроле — всё в порядке',
      time: _ago(60 * 26),
      unread: false,
    ),
    AppNotice(
      kind: NoticeKind.system,
      title: 'Обновились правила сервиса',
      body: 'Изменился порядок возврата отменённых заказов',
      time: _ago(60 * 50),
      unread: false,
    ),
  ];

  int get unreadNotices => notices.where((n) => n.unread).length;

  void markNoticesRead() {
    for (final n in notices) {
      n.unread = false;
    }
    notifyListeners();
  }

  void addNotice(AppNotice n) {
    notices.insert(0, n);
    notifyListeners();
  }

  // --- История доставок ---
  final List<HistoryEntry> history = _seedHistory();

  static List<HistoryEntry> _seedHistory() {
    final now = DateTime.now();
    final data = <(int, String, int, double, bool)>[
      (0, 'ул. Горького, 40', 300, 2.0, false),
      (0, 'ул. Ленина, 18', 340, 1.6, true),
      (0, 'мкр. Северный, 4', 380, 3.2, false),
      (1, 'ул. Амурская, 62', 320, 2.1, true),
      (1, 'ул. Чкалова, 95', 290, 1.4, false),
      (1, 'ул. Бабушкина, 12', 410, 3.6, false),
      (1, 'ул. Журавлёва, 30', 300, 1.9, true),
      (2, 'мкр. Северный, 21', 360, 2.8, false),
      (2, 'ул. Ленина, 77', 280, 1.2, false),
      (3, 'ул. Столярова, 8', 330, 2.3, true),
      (3, 'ул. Амурская, 15', 350, 2.6, false),
      (4, 'ул. Горького, 5', 310, 1.8, false),
    ];
    return data
        .map((e) => HistoryEntry(
              date: DateTime(now.year, now.month, now.day - e.$1, 12 - e.$1, 30),
              address: e.$2,
              payout: e.$3,
              km: e.$4,
              leftAtDoor: e.$5,
            ))
        .toList();
  }

  final Map<String, List<ChatMessage>> _chats = {};

  List<ChatMessage> chatFor(String orderId) {
    return _chats.putIfAbsent(
      orderId,
      () => [
        ChatMessage('Заказ передан курьеру', fromMe: false, system: true, time: _ago(14)),
        ChatMessage('Здравствуйте! Уже собираю ваш заказ 🛒', fromMe: true, time: _ago(11)),
        ChatMessage('Добрый день! Домофон не работает, позвоните — спущусь', fromMe: false, time: _ago(6)),
      ],
    );
  }

  void sendMessage(String orderId, String text) {
    final list = chatFor(orderId);
    list.add(ChatMessage(text, fromMe: true, time: DateTime.now()));
    notifyListeners();
    // Заглушка «ответа» оператора.
    Future.delayed(const Duration(milliseconds: 1400), () {
      list.add(ChatMessage('Принято, спасибо! 👌', fromMe: false, time: DateTime.now()));
      notifyListeners();
    });
  }

  // --- Чат поддержки ---
  final List<ChatMessage> support = [
    ChatMessage('Здравствуйте! Это поддержка Спринт. Опишите проблему — поможем.', fromMe: false, time: _ago(2)),
  ];

  void sendSupport(String text) {
    support.add(ChatMessage(text, fromMe: true, time: DateTime.now()));
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1500), () {
      support.add(ChatMessage(_supportReply(text), fromMe: false, time: DateTime.now()));
      notifyListeners();
    });
  }

  /// Ответы по темам — подбираем по ключевым словам.
  static const _supportTopics = <(List<String>, String)>[
    (
      ['опозда', 'не успева', 'задерж', 'таймер', 'просроч'],
      'Если видите, что не успеваете, — просто продолжайте доставку. Одно опоздание почти не влияет на рейтинг: он считается по последним 20 дням. Если задержка из-за магазина, отметьте это в «Проблема с заказом».'
    ),
    (
      ['рейтинг', 'оценк', 'звёзд', 'звезд'],
      'Рейтинг от 1 до 5 обновляется по последним 20 дням. На него влияют: доставки вовремя, вовремя начатые слоты, оценки клиентов и соблюдение стандартов.'
    ),
    (
      ['скан', 'штрихкод', 'штрих', 'qr', 'код', 'пакет'],
      'Сканируйте штрихкод на пакете и подтверждайте каждый пакет кнопкой. Если код не читается — нажмите «Ввести код» и укажите последние 4 цифры номера заказа с этикетки.'
    ),
    (
      ['двер', 'оставил', 'оставить', 'бескон'],
      'Способ вручения задаёт клиент. Если заказ помечен «оставить у двери» — оставьте, сфотографируйте и подтвердите. Фото сохраняется как доказательство доставки.'
    ),
    (
      ['паспорт', '18', 'алког', 'возраст'],
      'Для заказов 18+ проверьте паспорт при вручении. Если клиент отказывается показать документ или он младше 18 — не передавайте заказ и оформите возврат через «Проблема с заказом».'
    ),
    (
      ['фото', 'фотоконтрол'],
      'Фото должно быть чётким, заказ — целиком в кадре. По результатам фотоконтроля заказ могут отменить, поэтому не снимайте в темноте и не обрезайте пакет.'
    ),
    (
      ['бирж', 'на лини', 'пауз'],
      'Заказы приходят, когда вы на линии: либо в запланированном слоте, либо с включённой Биржей. Пауза доступна только между заказами, во время доставки её взять нельзя.'
    ),
    (
      ['полигон', 'зон', 'район'],
      'Полигоны закрепляет администратор — вы видите слоты только по своим зонам. Чтобы добавить полигон, напишите в поддержку, запрос уйдёт менеджеру.'
    ),
    (
      ['бонус', 'акци', 'челлендж'],
      'Бонусы обновляются в начале каждого месяца, размер зависит от числа доставок и рейтинга. Акции можно выбрать во вкладке «Акции» и при планировании слота.'
    ),
    (
      ['слот', 'смен', 'график', 'планир'],
      'Слоты планируются на неделю вперёд во вкладке «Слоты». Отказаться можно не позднее чем за 2 часа до начала — частые отказы снижают рейтинг.'
    ),
    (
      ['выплат', 'деньг', 'оплат', 'карт', 'зарплат', 'самозанят'],
      'Выплаты приходят каждый четверг на привязанную карту. Предварительная сумма появляется на следующий день после смены. Чеки для самозанятости формируются автоматически.'
    ),
    (
      ['клиент', 'не отвеча', 'дозвон', 'домофон'],
      'Если клиент не отвечает — позвоните ещё раз через приложение и подождите у двери. Через 10 минут ожидания оформите проблему через «Проблема с заказом», мы подскажем, что делать с заказом.'
    ),
    (
      ['приложен', 'глюч', 'висн', 'баг', 'ошибк', 'не работает'],
      'Попробуйте перезапустить приложение и проверить интернет. Если не помогло — сделайте скриншот экрана с ошибкой и пришлите сюда, передам разработчикам.'
    ),
  ];

  String _supportReply(String q) {
    final t = q.toLowerCase();
    for (final (keys, answer) in _supportTopics) {
      if (keys.any(t.contains)) return answer;
    }
    return 'Принял ваш вопрос. Передаю специалисту — ответим в течение нескольких минут.';
  }

  void toggleExchange() {
    if (exchangeOn && inProgress.isNotEmpty) return; // нельзя выключить Биржу во время доставки
    exchangeOn = !exchangeOn;
    if (exchangeOn) paused = false;
    notifyListeners();
  }

  void togglePause() {
    if (inProgress.isNotEmpty && !paused) return; // пауза только между заказами
    paused = !paused;
    notifyListeners();
  }

  int _nextCode = 4840;

  /// Авто-назначение заказа (как в оригинале — заказ выдают курьеру).
  DeliveryOrder simulateNewOrder() {
    final code = _nextCode++;
    final o = DeliveryOrder(
      id: 'N$code',
      stage: OrderStage.offered,
      storeName: 'Маркет на Ленина',
      storeAddress: 'ул. Ленина, 42',
      clientName: 'Мария',
      clientAddressShort: 'ул. Амурская, 15',
      clientAddressFull: 'г. Чита, ул. Амурская, 15, кв. 44',
      distanceKm: 1.9,
      payout: 280,
      etaMin: 11,
      isExpress: true,
      payType: PayType.online,
      entrance: '1',
      floor: '4',
      apartment: '44',
      leaveAtDoor: true,
      surcharges: const [Surcharge('Срочный бонус', 70, icon: Icons.bolt_rounded)],
      pickupBy: DateTime.now().add(const Duration(minutes: 8)),
      deadline: DateTime.now().add(const Duration(minutes: 25)),
      items: [OrderItem('Продукты', 5, weightKg: 2.8)],
    );
    _orders.insert(0, o);
    notifyListeners();
    return o;
  }

  void advance(DeliveryOrder o) {
    o.stage = switch (o.stage) {
      OrderStage.offered => OrderStage.toStore,
      OrderStage.toStore => OrderStage.atStore,
      OrderStage.atStore => OrderStage.toClient,
      OrderStage.toClient => OrderStage.delivered,
      _ => o.stage,
    };
    if (o.stage == OrderStage.delivered) {
      todayDeliveries += 1;
      todayEarned += o.payout;
      todayKm += o.distanceKm.round();
    }
    notifyListeners();
  }

  static DateTime _ago(int min) => DateTime.now().subtract(Duration(minutes: min));

  static List<DeliveryOrder> _seed() => [
        DeliveryOrder(
          id: 'A1',
          stage: OrderStage.toClient,
          storeName: 'Маркет на Ленина',
          storeAddress: 'ул. Ленина, 42',
          clientName: 'Анна',
          clientAddressShort: 'ул. Бабушкина, 104',
          clientAddressFull: 'г. Чита, ул. Бабушкина, 104, кв. 57',
          distanceKm: 2.4,
          payout: 320,
          etaMin: 12,
          isExpress: true,
          payType: PayType.online,
          entrance: '3',
          floor: '9',
          apartment: '57',
          comment: 'Домофон не работает',
          clientComment: 'Оставьте пакет у двери, не звоните — ребёнок спит',
          leaveAtDoor: true,
          noDoorbell: true,
          isHot: true,
          pickupBy: DateTime.now().add(const Duration(minutes: 6)),
          deadline: DateTime.now().add(const Duration(minutes: 12)),
          surcharges: const [
            Surcharge('Надбавка за время', 60, icon: Icons.schedule_rounded),
            Surcharge('Повышенная оплата', 40, icon: Icons.trending_up_rounded),
          ],
          items: [
            OrderItem('Молоко 3.2% 930мл', 2, weightKg: 0.95),
            OrderItem('Хлеб «Бородинский»', 1, weightKg: 0.4),
            OrderItem('Бананы', 1, weightKg: 1.2),
            OrderItem('Яйцо С0, 10 шт', 1, weightKg: 0.7),
          ],
        ),
        DeliveryOrder(
          id: 'A2',
          stage: OrderStage.offered,
          storeName: 'Маркет Экспресс',
          storeAddress: 'ул. Чкалова, 120',
          clientName: 'Дмитрий',
          clientAddressShort: 'мкр. Северный, 12',
          clientAddressFull: 'г. Чита, мкр. Северный, 12, кв. 3',
          distanceKm: 3.1,
          payout: 410,
          etaMin: 18,
          payType: PayType.online,
          entrance: '1',
          floor: '2',
          apartment: '3',
          hasDrink: true,
          surcharges: const [Surcharge('Надбавка за расстояние', 50, icon: Icons.route_rounded)],
          items: [
            OrderItem('Вода питьевая 5л', 3, weightKg: 5),
            OrderItem('Пельмени 800г', 2, weightKg: 0.8),
            OrderItem('Кофе молотый 250г', 1, weightKg: 0.25),
          ],
        ),
        DeliveryOrder(
          id: 'A3',
          stage: OrderStage.offered,
          storeName: 'Маркет на Ленина',
          storeAddress: 'ул. Ленина, 42',
          clientName: 'Ольга',
          clientAddressShort: 'ул. Журавлёва, 88',
          clientAddressFull: 'г. Чита, ул. Журавлёва, 88, кв. 21',
          distanceKm: 1.5,
          payout: 260,
          etaMin: 9,
          isExpress: true,
          payType: PayType.online,
          entrance: '2',
          floor: '5',
          apartment: '21',
          needsAgeCheck: true,
          isSuperfast: true,
          surcharges: const [Surcharge('Суперфаст-бонус', 90, icon: Icons.rocket_launch_rounded)],
          items: [
            OrderItem('Йогурт питьевой', 4, weightKg: 0.29),
            OrderItem('Сыр «Российский» 200г', 1, weightKg: 0.2),
            OrderItem('Вино красное 0.75л', 1, weightKg: 1.2),
          ],
        ),
        DeliveryOrder(
          id: 'A0',
          stage: OrderStage.delivered,
          storeName: 'Маркет Экспресс',
          storeAddress: 'ул. Чкалова, 120',
          clientName: 'Сергей',
          clientAddressShort: 'ул. Горького, 40',
          clientAddressFull: 'г. Чита, ул. Горького, 40, кв. 9',
          distanceKm: 2.0,
          payout: 300,
          etaMin: 0,
          payType: PayType.online,
          items: [OrderItem('Продукты', 8, weightKg: 4.2)],
        ),
      ];
}
