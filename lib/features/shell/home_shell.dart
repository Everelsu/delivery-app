import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../orders/orders_page.dart';
import '../map/route_page.dart';
import '../slots/slots_page.dart';
import '../promos/promos_page.dart';
import '../profile/profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [OrdersPage(), RoutePage(), SlotsPage(), PromosPage(), ProfilePage()];
  final _tabs = const [
    (_Tab(Icons.list_alt_rounded, 'Заказы')),
    (_Tab(Icons.map_rounded, 'Маршрут')),
    (_Tab(Icons.event_note_rounded, 'Слоты')),
    (_Tab(Icons.local_offer_rounded, 'Акции')),
    (_Tab(Icons.person_rounded, 'Профиль')),
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        final active = store.inProgress.isNotEmpty ? store.inProgress.first : null;
        return Scaffold(
          extendBody: true,
          body: AnimatedSwitcher(
            // Короткое затухание без сдвига — переключение вкладок должно быть
            // мгновенным по ощущению, а не «ездить».
            duration: const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Быстрый возврат к активному заказу. На «Заказах» и «Маршруте»
              // не показываем — там заказ и так на экране.
              if (active != null && _index != 0 && _index != 1)
                _ActiveBar(order: active, onTap: () => setState(() => _index = 0)),
              _NavBar(
                index: _index,
                tabs: _tabs,
                onTap: (i) => setState(() => _index = i),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Мини-панель активного заказа над навбаром.
class _ActiveBar extends StatelessWidget {
  const _ActiveBar({required this.order, required this.onTap});
  final DeliveryOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toClient = order.stage == OrderStage.toClient;
    final where = toClient ? order.clientAddressShort : order.storeName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: order.stage.color.withValues(alpha: 0.4)),
              boxShadow: AppShadows.soft,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(order.stage.icon, size: 19, color: order.stage.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.stage.label,
                          style: TextStyle(
                              color: order.stage.color, fontWeight: FontWeight.w800, fontSize: 11.5)),
                      Text(where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.tabs, required this.onTap});
  final int index;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.lift,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < tabs.length; i++)
            _NavItem(
              tab: tabs[i],
              selected: i == index,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.onTap});
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Выбранный — залит фирменным зелёным с белым текстом: одинаково читается
    // и в светлой, и в тёмной теме.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 46,
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 21, color: selected ? Colors.white : AppColors.faint),
            if (selected) ...[
              const SizedBox(width: 7),
              Text(
                tab.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
