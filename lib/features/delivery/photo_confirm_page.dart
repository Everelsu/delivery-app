import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

/// Фото-подтверждение доставки. Снимок делается настоящей камерой.
class PhotoConfirmPage extends StatefulWidget {
  const PhotoConfirmPage({super.key, required this.order, this.leaveAtDoor = false});
  final DeliveryOrder order;
  final bool leaveAtDoor;
  @override
  State<PhotoConfirmPage> createState() => _PhotoConfirmPageState();
}

class _PhotoConfirmPageState extends State<PhotoConfirmPage> {
  final _picker = ImagePicker();
  final List<Uint8List> _shots = [];
  bool _busy = false;
  String? _error;

  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (mounted) setState(() => _shots.add(bytes));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Камера недоступна. Проверьте разрешение.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = _shots.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.leaveAtDoor ? 'Фото у двери' : 'Фото доставки',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _preview(has)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _capture,
                      icon: const Icon(Icons.photo_camera_rounded, size: 20),
                      label: Text(has ? 'Ещё фото' : 'Сделать фото',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24, width: 1.4),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (has) ...[
                    HoldButton(
                      label: widget.leaveAtDoor ? 'Оставлено у двери' : 'Доставлено',
                      icon: Icons.check_circle_rounded,
                      onConfirm: () => Navigator.pop(context, true),
                    ),
                    const SizedBox(height: 5),
                    const Text('Удерживайте 2 секунды',
                        style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 12)),
                  ] else
                    const Text('Нужно минимум одно фото',
                        style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(bool has) {
    if (!has) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF121A26),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.leaveAtDoor ? Icons.door_front_door_rounded : Icons.photo_camera_rounded,
                  color: Colors.white24, size: 52),
              const SizedBox(height: 14),
              Text(
                widget.leaveAtDoor
                    ? 'Оставьте заказ у двери\nи сфотографируйте'
                    : 'Сфотографируйте переданный заказ',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 14.5, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _shots.length,
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(_shots[i], fit: BoxFit.cover),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() => _shots.removeAt(i)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
