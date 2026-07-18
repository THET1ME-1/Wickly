import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../l10n/locale_controller.dart';
import '../l10n/strings.dart';

/// Место и погода на момент записи.
class EntryContext {
  final double? lat;
  final double? lon;
  final String? place;
  final String? weather;
  final int? weatherCode;
  final double? temp;

  const EntryContext({
    this.lat,
    this.lon,
    this.place,
    this.weather,
    this.weatherCode,
    this.temp,
  });

  bool get isEmpty => lat == null && weather == null;

  EntryContext merge(EntryContext other) => EntryContext(
        lat: other.lat ?? lat,
        lon: other.lon ?? lon,
        place: other.place ?? place,
        weather: other.weather ?? weather,
        weatherCode: other.weatherCode ?? weatherCode,
        temp: other.temp ?? temp,
      );
}

/// Подставляет в запись место и погоду.
///
/// Всё по желанию: без разрешения на геолокацию запись просто останется без
/// места, а без сети — без погоды. Дневник не должен ничего требовать, чтобы
/// человек мог написать пару строк.
///
/// Погода берётся у Open-Meteo: без ключа, без регистрации и без передачи
/// чего-либо, кроме округлённых координат.
class ContextService {
  const ContextService._();

  static const _weatherApi = 'https://api.open-meteo.com/v1/forecast';

  /// Собирает контекст: сперва координаты, затем название места и погода.
  static Future<EntryContext> capture({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final position = await _position().timeout(timeout);
      if (position == null) return const EntryContext();

      // Название и погода независимы — тянем разом, а не по очереди.
      final results = await Future.wait([
        _placeName(position.latitude, position.longitude)
            .timeout(timeout, onTimeout: () => null),
        _weather(position.latitude, position.longitude)
            .timeout(timeout, onTimeout: () => null),
      ]);

      final weather = results[1] as _Weather?;
      return EntryContext(
        lat: position.latitude,
        lon: position.longitude,
        place: results[0] as String?,
        weather: weather == null ? null : weatherLabel(weather.code),
        weatherCode: weather?.code,
        temp: weather?.temp,
      );
    } catch (_) {
      // Нет разрешения, нет сети, нет сенсора — запись обойдётся без контекста.
      return const EntryContext();
    }
  }

  static Future<Position?> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  /// Человеческое название места: улица или район, а не полный адрес —
  /// в дневнике важно «Набережная», а не индекс и номер дома.
  static Future<String?> _placeName(double lat, double lon) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(
        lat,
        lon,
        locale: Locale(LocaleController.instance.code),
      );
      if (marks.isEmpty) return null;
      final m = marks.first;
      for (final candidate in [
        m.street,
        m.subLocality,
        m.locality,
        m.administrativeArea,
      ]) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<_Weather?> _weather(double lat, double lon) async {
    try {
      // Округляем координаты до сотых (~1 км): для погоды хватает, а точное
      // место наружу не уходит.
      final uri = Uri.parse('$_weatherApi'
          '?latitude=${lat.toStringAsFixed(2)}'
          '&longitude=${lon.toStringAsFixed(2)}'
          '&current=temperature_2m,weather_code');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, Object?>;
      final current = json['current'] as Map<String, Object?>?;
      if (current == null) return null;
      return _Weather(
        code: (current['weather_code'] as num?)?.toInt() ?? 0,
        temp: (current['temperature_2m'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Код погоды WMO → короткое слово на языке интерфейса.
  static String weatherLabel(int code) => tr(switch (code) {
        0 => 'weather_clear',
        1 || 2 => 'weather_partly',
        3 => 'weather_cloudy',
        45 || 48 => 'weather_fog',
        51 || 53 || 55 || 56 || 57 => 'weather_drizzle',
        61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'weather_rain',
        71 || 73 || 75 || 77 || 85 || 86 => 'weather_snow',
        95 || 96 || 99 => 'weather_storm',
        _ => 'weather_cloudy',
      });

  /// Иконка под тот же код.
  static IconData weatherIcon(int? code) => switch (code) {
        0 => Icons.wb_sunny_rounded,
        1 || 2 => Icons.wb_cloudy_rounded,
        3 => Icons.cloud_rounded,
        45 || 48 => Icons.foggy,
        51 || 53 || 55 || 56 || 57 => Icons.grain_rounded,
        61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => Icons.umbrella_rounded,
        71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit_rounded,
        95 || 96 || 99 => Icons.thunderstorm_rounded,
        _ => Icons.cloud_rounded,
      };

  /// «+24°, ясно» — подпись пилюли погоды.
  static String weatherChip(double? temp, String? label) {
    final parts = <String>[
      if (temp != null) '${temp > 0 ? '+' : ''}${temp.round()}°',
      ?label,
    ];
    return parts.join(', ');
  }
}

class _Weather {
  final int code;
  final double? temp;
  const _Weather({required this.code, this.temp});
}
