import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../app/theme.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import '../orders/order_actions.dart';
import '../orders/order_detail_page.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});
  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final _map = MapController();

  static const _store = LatLng(kStoreLat, kStoreLon);
  static const _client = LatLng(kClientLat, kClientLon);
  // Текущее положение курьера (демо).
  static const _courier = LatLng(52.0356, 113.4930);

  RouteResult? _route;
  bool _loading = true;
  bool _failed = false;
  String? _loadedFor; // для какой цели уже проложили

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  LatLng get _target {
    final o = AppStore.I.inProgress.isNotEmpty ? AppStore.I.inProgress.first : null;
    final toClient = o?.stage == OrderStage.toClient;
    return toClient ? _client : _store;
  }

  Future<void> _load() async {
    final target = _target;
    final key = '${target.latitude},${target.longitude}';
    if (_loadedFor == key && _route != null) return;

    setState(() {
      _loading = true;
      _failed = false;
    });
    final r = await Routing.road(_courier, target);
    if (!mounted) return;
    setState(() {
      _route = r;
      _loading = false;
      _failed = r == null;
      _loadedFor = key;
    });
    if (r != null) _fit(r.points);
  }

  void _fit(List<LatLng> pts) {
    if (pts.isEmpty) return;
    _map.fitCamera(
      CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.fromLTRB(50, 90, 50, 260)),
    );
  }

  /// Пока маршрут не проложен — прямая линия, чтобы экран не был пустым.
  List<LatLng> get _line => _route?.points ?? [_courier, _target];

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.I]),
      builder: (context, _) {
        final order = store.inProgress.isNotEmpty ? store.inProgress.first : null;
        final toClient = order?.stage == OrderStage.toClient;

        // Цель сменилась (заехали в магазин → поехали к клиенту) — перепроложить.
        final key = '${_target.latitude},${_target.longitude}';
        if (_loadedFor != null && _loadedFor != key && !_loading) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _load());
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              Positioned.fill(child: _buildMap(context)),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _mapBtn(Icons.zoom_out_map_rounded, () => _fit(_line)),
                        const SizedBox(height: 10),
                        _mapBtn(Icons.my_location_rounded, () => _map.move(_courier, 15)),
                        const SizedBox(height: 10),
                        _mapBtn(Icons.refresh_rounded, _load),
                      ],
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SafeArea(
                  child: Align(alignment: Alignment.topCenter, child: _Chip(text: 'Строим маршрут…')),
                )
              else if (_failed)
                const SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _Chip(text: 'Маршрут недоступен офлайн', warn: true),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: order == null ? _noRoute(context) : _card(context, order, toClient),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _courier,
        initialZoom: 13.5,
        backgroundColor: AppColors.bg,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          // CartoDB Voyager — чистый «приложенческий» стиль вместо сырого OSM.
          // {r} + retinaMode дают @2x-тайлы, без них карта мылит на плотном экране.
          urlTemplate: AppColors.dark
              ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.sprint.courier',
          maxNativeZoom: 20,
          tileProvider: NetworkTileProvider(),
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _line,
              strokeWidth: 6,
              color: _failed ? AppColors.faint : AppColors.primary,
              borderStrokeWidth: 2,
              borderColor: Colors.white,
              // Пунктир, пока это лишь прямая, а не дорога.
              pattern: _route == null
                  ? StrokePattern.dashed(segments: const [10, 8])
                  : const StrokePattern.solid(),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            _pin(_courier, Icons.directions_bike_rounded, AppColors.accent, big: true),
            _pin(_store, Icons.storefront_rounded, AppColors.info),
            _pin(_client, Icons.location_on_rounded, AppColors.primary),
          ],
        ),
        // Атрибуция обязательна по условиям OSM/CARTO.
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution('OpenStreetMap', onTap: () {}),
            TextSourceAttribution('CARTO', onTap: () {}),
          ],
        ),
      ],
    );
  }

  Marker _pin(LatLng at, IconData icon, Color color, {bool big = false}) {
    final size = big ? 44.0 : 38.0;
    return Marker(
      point: at,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
        ),
        child: Icon(icon, color: Colors.white, size: big ? 22 : 19),
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(icon, color: AppColors.ink, size: 21),
        ),
      );

  Widget _noRoute(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Нет активного маршрута',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('Появится, когда назначат заказ',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  Widget _card(BuildContext context, DeliveryOrder order, bool toClient) {
    final address = toClient ? order.clientAddressFull : order.storeAddress;
    // Данные из проложенного маршрута точнее, чем заглушки заказа.
    final km = _route?.distanceKm ?? order.distanceKm;
    final min = _route?.minutes ?? order.etaMin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.lift,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(order.stage.icon, size: 18, color: order.stage.color),
              const SizedBox(width: 6),
              Text(order.stage.label,
                  style: TextStyle(
                      color: order.stage.color, fontWeight: FontWeight.w800, fontSize: 13)),
              const Spacer(),
              if (order.currentDeadline != null)
                CountdownChip(deadline: order.currentDeadline!, label: order.deadlineLabel),
            ],
          ),
          const SizedBox(height: 10),
          Text(toClient ? order.clientAddressShort : order.storeName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${km.toStringAsFixed(1)} км · ~$min мин',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.muted)),
              if (_route != null) ...[
                const SizedBox(width: 6),
                Text('по дорогам',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.faint)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Навигатор',
                  icon: Icons.navigation_rounded,
                  onPressed: () =>
                      showNavigatorChooser(context, toClient: toClient, address: address),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  label: 'Заказ',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.warn = false});
  final String text;
  final bool warn;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warn)
            const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning)
          else
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
        ],
      ),
    );
  }
}
