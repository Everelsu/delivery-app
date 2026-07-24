import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

/// Проверка взятия пакетов. Камера находит код, но пакет засчитывается
/// только после подтверждения кнопкой — иначе «сканится всё подряд».
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.order});
  final DeliveryOrder order;
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final List<String> _confirmed = [];
  String? _pending; // найден, но ещё не подтверждён
  bool _torch = false;

  late final int _need = widget.order.items.length.clamp(1, 3);
  bool get _done => _confirmed.length >= _need;

  void _onDetect(BarcodeCapture cap) {
    if (_done) return;
    for (final b in cap.barcodes) {
      final v = b.rawValue;
      if (v == null || v.isEmpty) continue;
      if (_confirmed.contains(v) || _pending == v) return;
      HapticFeedback.selectionClick();
      setState(() => _pending = v);
      return;
    }
  }

  void _confirmPending() {
    final v = _pending;
    if (v == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _confirmed.add(v);
      _pending = null;
    });
  }

  String _short(String v) => v.length <= 18 ? v : '${v.substring(0, 18)}…';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Пакеты заказа',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Подсветка',
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torch = !_torch);
            },
            icon: Icon(_torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Прогресс — сколько пакетов уже подтверждено.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: List.generate(_need, (i) {
                  final filled = i < _confirmed.length;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i == _need - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: filled ? AppColors.primary : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _viewfinder()),
            _bottom(),
          ],
        ),
      ),
    );
  }

  Widget _viewfinder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _cameraError(),
            ),
            IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(46),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _pending != null ? AppColors.primary : Colors.white70,
                    width: 2.5,
                  ),
                ),
              ),
            ),
            if (_done)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 54),
                    SizedBox(height: 10),
                    Text('Все пакеты отсканированы',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cameraError() => Container(
        color: const Color(0xFF121A26),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_rounded, color: Colors.white38, size: 44),
              SizedBox(height: 12),
              Text('Камера недоступна',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 4),
              Text('Разрешите доступ или введите код вручную',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        children: [
          // Найденный код — подтверждаем вручную.
          if (_pending != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Код найден',
                            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 11.5)),
                        Text(_short(_pending!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Не тот код',
                    onPressed: () => setState(() => _pending = null),
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Подтвердить пакет ${_confirmed.length + 1} из $_need',
              icon: Icons.add_rounded,
              onPressed: _confirmPending,
            ),
          ] else
            Text(
              _done ? 'Готово — можно продолжать' : 'Наведите камеру на штрихкод пакета',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _done ? AppColors.primary : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5),
            ),

          const SizedBox(height: 12),
          if (_done)
            PrimaryButton(
              label: 'Забрал заказ',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _manualCode,
                  child: const Text('Ввести код',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              Container(width: 1, height: 18, color: Colors.white24),
              Expanded(
                child: TextButton(
                  // Демо-удобство: пропустить сканирование целиком.
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Пропустить · демо',
                      style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Резерв — 4 последние цифры номера заказа с этикетки.
  void _manualCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(22),
          decoration:
              BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Код с этикетки', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Последние 4 цифры номера заказа',
                  textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              CodeInput(
                length: 4,
                onCompleted: (code) {
                  Navigator.pop(ctx);
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _confirmed.add('manual-$code-${_confirmed.length}');
                    _pending = null;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
