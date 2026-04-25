import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/soil_data_model.dart';

// SoilGrids v2.0 — ISRIC World Soil Information
// 100% free, no API key, no expiry, 30m resolution across Africa
class SoilService {
  static const String _baseUrl =
      'https://rest.isric.org/soilgrids/v2.0/properties/query';
  static const String _cacheKey = 'last_soil_data';

  static Future<SoilDataModel> getSoilData(double lat, double lon) async {
    // Build URL with multiple 'property' params (can't use queryParameters
    // map since Dart merges duplicate keys — build string directly instead)
    final url = Uri.parse(
      '$_baseUrl'
      '?lat=${lat.toStringAsFixed(6)}'
      '&lon=${lon.toStringAsFixed(6)}'
      '&property=phh2o'
      '&property=clay'
      '&property=sand'
      '&property=silt'
      '&property=nitrogen'
      '&property=soc'
      '&depth=0-5cm'
      '&value=mean',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return SoilDataModel.fromSoilGridsJson(json, lat, lon);
        case 429:
          throw Exception(
              'Maombi mengi sana. Subiri dakika 1 kisha jaribu tena.');
        case 503:
          throw Exception(
              'Seva ya SoilGrids haifanyi kazi sasa. Jaribu baadaye.');
        default:
          throw Exception(
              'Hitilafu ya seva (${response.statusCode}). Jaribu tena.');
      }
    } on TimeoutException {
      throw Exception(
          'Muda umekwisha. Angalia mtandao wako na jaribu tena.');
    } on SocketException {
      throw Exception(
          'Hakuna mtandao. Angalia connection ya intaneti yako.');
    } on FormatException {
      throw Exception('Hitilafu ya data iliyopokelewa. Jaribu tena.');
    }
  }

  static Future<void> cacheResult(SoilDataModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(model.toJson()));
    } catch (e) {
      debugPrint('SoilService cache error: $e');
    }
  }

  static Future<SoilDataModel?> getCachedResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SoilDataModel.fromCacheJson(json);
    } catch (e) {
      debugPrint('SoilService cache read error: $e');
      return null;
    }
  }

  // Friendly fertiliser recommendation based on actual soil values
  static String getRecommendation(SoilDataModel soil) {
    final ph = soil.ph;
    final sand = soil.sand ?? 0;
    final clay = soil.clay ?? 0;

    if (ph != null && ph < 5.5 && clay > 35) {
      return 'Udongo wako ni tindikali sana na mzito — ongeza chokaa (lime) '
          'kg 200–300 kwa ekari na fanya mifereji mizuri ya maji ili '
          'kuboresha hali ya udongo.';
    }
    if (ph != null && ph < 5.5) {
      return 'pH ni ndogo sana. Ongeza chokaa (agricultural lime) '
          'kg 150–200 kwa ekari kabla ya kupanda. Rudia baada ya miezi 6.';
    }
    if (ph != null && ph > 7.5) {
      return 'Udongo una alkali nyingi. Ongeza sulfuri au tumia mbolea ya '
          'ammonium sulfate kupunguza pH. Epuka mbolea ya CAN kwenye udongo huu.';
    }
    if (sand > 65) {
      return 'Udongo una mchanga mwingi — haushiki maji vizuri. '
          'Mwagilia mara nyingi (kidogo kidogo) na ongeza mboji '
          'nyingi kuboresha uwezo wa kushikilia maji na virutubisho.';
    }
    if (clay > 50) {
      return 'Udongo ni mzito sana — unaweza kujaa maji. '
          'Fanya mifereji mizuri, ongeza mboji, na lima kwa kina '
          'kidogo ili kuepuka kuoza kwa mizizi.';
    }
    if (ph != null && ph >= 6.5 && ph <= 7.0) {
      return 'Udongo wako uko vizuri kabisa! pH ni bora kwa mazao mengi. '
          'Endelea na matumizi ya mboji na mzunguko wa mazao kudumisha rutuba.';
    }
    return 'Udongo wako uko katika hali ya wastani. Ongeza mboji '
        '(organic matter) mara kwa mara na pima udongo kila mwaka '
        'ili kufuatilia mabadiliko.';
  }
}
