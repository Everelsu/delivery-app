import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Результат прокладки маршрута по дорогам.
class RouteResult {
  const RouteResult({required this.points, required this.distanceKm, required this.minutes});
  final List<LatLng> points;
  final double distanceKm;
  final int minutes;
}

/// Прокладка маршрута через публичный OSRM.
/// Возвращает null, если сети нет или сервис не ответил — вызывающий код
/// в этом случае показывает прямую линию.
class Routing {
  static const _base = 'https://router.project-osrm.org/route/v1';

  static Future<RouteResult?> road(
    LatLng from,
    LatLng to, {
    String profile = 'driving',
  }) async {
    final url = Uri.parse(
      '$_base/$profile/${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}?overview=full&geometries=geojson',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes.first as Map<String, dynamic>;
      final coords = (r['geometry']?['coordinates'] as List?) ?? const [];
      if (coords.isEmpty) return null;
      return RouteResult(
        points: coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList(growable: false),
        distanceKm: ((r['distance'] as num?)?.toDouble() ?? 0) / 1000,
        minutes: (((r['duration'] as num?)?.toDouble() ?? 0) / 60).round(),
      );
    } catch (_) {
      return null; // офлайн или таймаут — не роняем экран
    }
  }
}
