import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import '../chat/chat_page.dart';
import '../history/history_page.dart';
import '../notifications/notices_page.dart';
import 'personal_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        final c = store.courier;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                // Кто ты
                Row(
                  children: [
                    InitialsAvatar(initials: c.initials, size: 52, color: AppColors.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('${c.phone} · самозанятый',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 19),
                        const SizedBox(width: 3),
                        Text(c.rating.toStringAsFixed(2),
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                      ],
                    ),
                  ],
                ),

                // Деньги — главное в профиле
                const SizedBox(height: 30),
                Text('К выплате', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text('₽ ${c.balance}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -1.2, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Придёт в четверг, ${_nextThursday()}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _showPayouts(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('История выплат',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                  ),
                ),

                // Статистика — тихими строками
                const SizedBox(height: 30),
                _Header('Статистика'),
                _StatRow(label: 'Доставок всего', value: '${c.deliveriesTotal}'),
                _StatRow(label: 'Рейтинг', value: c.rating.toStringAsFixed(2)),
                _StatRow(label: 'Транспорт', value: c.vehicle),
                _StatRow(label: 'Зона работы', value: 'Чита, Центр', last: true),

                // Тема
                const SizedBox(height: 30),
                _Header('Оформление'),
                const SizedBox(height: 10),
                _ThemeSwitch(),

                // Настройки
                const SizedBox(height: 30),
                _Header('Настройки'),
                _MenuRow(
                  title: 'Личные данные',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PersonalPage())),
                ),
                _MenuRow(
                  title: 'История заказов',
                  value: '${store.history.length}',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                ),
                _MenuRow(
                  title: 'Уведомления',
                  value: store.unreadNotices > 0 ? '${store.unreadNotices} новых' : null,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const NoticesPage())),
                ),
                _MenuRow(
                  title: 'Поддержка',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const ChatPage.support())),
                  last: true,
                ),

                const SizedBox(height: 26),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _confirmLogout(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Выйти из аккаунта',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _nextThursday() {
    var d = DateTime.now();
    do {
      d = d.add(const Duration(days: 1));
    } while (d.weekday != DateTime.thursday);
    const months = ['', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля',
      'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${d.day} ${months[d.month]}';
  }

  void _showPayouts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayoutsSheet(),
    );
  }

  void _confirmLogout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выйти из аккаунта?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Во время слота выйти нельзя — сначала завершите смену',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            HoldButton(
              label: 'Выйти из аккаунта',
              icon: Icons.logout_rounded,
              color: AppColors.danger,
              onConfirm: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 5),
            Text('Удерживайте 2 секунды',
                style: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 10),
            GhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.8)),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.inkSoft)),
              ),
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.title, this.value, required this.onTap, this.last = false});
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool last;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                ),
                if (value != null)
                  Text(value!,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.muted)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
              ],
            ),
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}

/// ВАЖНО: не помечать const — иначе при смене темы поддерево не перестроится.
class _ThemeSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = ThemeController.I.mode;
    const opts = [
      (ThemeMode.light, 'Светлая'),
      (ThemeMode.dark, 'Тёмная'),
      (ThemeMode.system, 'Система'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: opts.map((o) {
          final selected = o.$1 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => ThemeController.I.set(o.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: selected ? AppShadows.soft : null,
                ),
                child: Text(
                  o.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PayoutsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('17 июля', 12480),
      ('10 июля', 11960),
      ('3 июля', 13210),
      ('26 июня', 10870),
    ];
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('История выплат', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Четверг, ${r.$1}',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.inkSoft)),
                    ),
                    Text('₽ ${r.$2}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Закрыть', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
