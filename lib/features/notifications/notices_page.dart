import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/notifications.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../orders/order_detail_page.dart';

/// Центр уведомлений.
class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});
  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  @override
  void initState() {
    super.initState();
    // Заходя в центр, помечаем всё прочитанным.
    WidgetsBinding.instance.addPostFrameCallback((_) => AppStore.I.markNoticesRead());
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Уведомления')),
          body: store.notices.isEmpty
              ? Center(
                  child: Text('Пока ничего нет', style: Theme.of(context).textTheme.bodyMedium))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    ...store.notices.map((n) => _NoticeRow(notice: n)),
                    const SizedBox(height: 20),
                    // Демо-кнопка: имитируем назначение заказа.
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _simulate(context, store),
                        icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                        label: const Text('Назначить заказ · демо',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _simulate(BuildContext context, AppStore store) {
    if (!store.onLine) {
      AppNotifications.show(context,
          title: 'Вы не на линии',
          body: 'Встаньте в слот или включите Биржу',
          icon: Icons.wifi_off_rounded,
          color: AppColors.warning);
      return;
    }
    final o = store.simulateNewOrder();
    store.addNotice(AppNotice(
      kind: NoticeKind.order,
      title: 'Назначен заказ',
      body: '${o.clientAddressShort} · ${o.distanceKm} км · ₽${o.total}',
      time: DateTime.now(),
      unread: false,
    ));
    AppNotifications.show(context,
        title: 'Назначен заказ',
        body: '${o.clientAddressShort} · ${o.distanceKm} км',
        icon: Icons.assignment_ind_rounded,
        color: AppColors.primary,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))));
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});
  final AppNotice notice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notice.kind.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(notice.kind.icon, size: 20, color: notice.kind.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notice.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.ink)),
                        ),
                        if (notice.unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(
                                color: AppColors.accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notice.body,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.35,
                            color: AppColors.inkSoft)),
                    const SizedBox(height: 3),
                    Text(_ago(notice.time), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'только что';
    if (d.inMinutes < 60) return '${d.inMinutes} мин назад';
    if (d.inHours < 24) return '${d.inHours} ч назад';
    return '${d.inDays} дн назад';
  }
}
