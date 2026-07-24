import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';

/// Личные данные и настройки уведомлений.
class PersonalPage extends StatelessWidget {
  const PersonalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        final c = store.courier;
        return Scaffold(
          appBar: AppBar(title: const Text('Личные данные')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Center(
                child: Column(
                  children: [
                    InitialsAvatar(initials: c.initials, size: 76, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(c.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text('Курьер · с марта 2024',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              _Header('Данные'),
              _Field(label: 'Телефон', value: c.phone, editable: true),
              _Field(label: 'Транспорт', value: c.vehicle, editable: true),
              _Field(label: 'Город', value: 'Чита'),
              _Field(label: 'Полигоны', value: AppStore.assignedPolygons.join(', '), hint: 'назначает менеджер'),
              _Field(label: 'Статус', value: 'Самозанятый · НПД', last: true),

              const SizedBox(height: 26),
              _Header('Документы'),
              _DocRow(title: 'Паспорт', status: 'Проверен', ok: true),
              _DocRow(title: 'Справка о самозанятости', status: 'Проверена', ok: true),
              _DocRow(title: 'Банковская карта', status: '•••• 4417', ok: true, last: true),

              const SizedBox(height: 26),
              _Header('Уведомления'),
              _Toggle(
                title: 'Новые заказы',
                sub: 'Пуш при назначении заказа',
                value: store.notifyOrders,
                onChanged: (v) => store.setSetting('orders', v),
              ),
              _Toggle(
                title: 'Слоты',
                sub: 'Напоминание за 15 минут до начала',
                value: store.notifySlots,
                onChanged: (v) => store.setSetting('slots', v),
              ),
              _Toggle(
                title: 'Выплаты',
                sub: 'Уведомлять о зачислении по четвергам',
                value: store.notifyPayouts,
                onChanged: (v) => store.setSetting('payouts', v),
              ),
              _Toggle(
                title: 'Звук',
                value: store.soundOn,
                onChanged: (v) => store.setSetting('sound', v),
              ),
              _Toggle(
                title: 'Вибрация',
                value: store.vibrationOn,
                onChanged: (v) => store.setSetting('vibration', v),
                last: true,
              ),

              const SizedBox(height: 24),
              Text(
                'Данные и полигоны меняет менеджер — напишите в поддержку, если что-то указано неверно.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _Header(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 0.8)),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.hint,
    this.editable = false,
    this.last = false,
  });
  final String label;
  final String value;
  final String? hint;
  final bool editable;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink)),
                    if (hint != null)
                      Text(hint!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (editable)
                Icon(Icons.edit_rounded, size: 18, color: AppColors.faint)
              else
                Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.faint),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.title, required this.status, required this.ok, this.last = false});
  final String title;
  final String status;
  final bool ok;
  final bool last;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          child: Row(
            children: [
              Icon(ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                  size: 20, color: ok ? AppColors.success : AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
              ),
              Text(status,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.muted)),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    this.sub,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                    if (sub != null)
                      Text(sub!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.line, indent: 2, endIndent: 2),
      ],
    );
  }
}
