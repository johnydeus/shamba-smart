import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/satellite_models.dart';
import 'eosda_service.dart';

class CropAnalysisService {
  final EosdaService _eosda;

  CropAnalysisService(this._eosda);

  static const _claudeUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-5';
  static String get _claudeKey => dotenv.env['CLAUDE_API_KEY'] ?? '';

  // ── Main analysis pipeline ─────────────────────────────────────────────────

  Future<CropAnalysisReport> analyzeField({
    required FieldPolygon field,
  }) async {
    final now = DateTime.now();
    final dateRange30 = now.subtract(const Duration(days: 30));

    // 1. Fetch NDVI and NDWI in parallel for efficiency
    final results = await Future.wait([
      _eosda.getNdviStats(
          polygonId: field.id, startDate: dateRange30, endDate: now),
      _eosda.getNdwiStats(
          polygonId: field.id, startDate: dateRange30, endDate: now),
      _eosda.getWeatherData(polygonId: field.id),
    ]);

    final ndviReadings = results[0] as List<NdviReading>;
    final ndwiReadings = results[1] as List<NdwiReading>;
    final weather      = results[2] as Map<String, dynamic>;

    // 2. Use most recent readings
    final latestNdvi = ndviReadings.isNotEmpty
        ? ndviReadings.last
        : NdviReading(
            date: now, average: 0.42, min: 0.28, max: 0.60, cloudCover: 0.1);

    final latestNdwi = ndwiReadings.isNotEmpty ? ndwiReadings.last : null;

    // 3. Derive analysis — NDWI now drives water stress instead of estimation
    final soil       = _interpretSoil(latestNdvi, weather);
    final waterStress = _interpretWaterStressFromNdwi(latestNdwi, latestNdvi, weather);
    final nutrients  = _interpretNutrients(latestNdvi);
    final pests      = _interpretPestRisk(latestNdvi, weather);

    // 4. Health score
    final score = _calculateHealthScore(latestNdvi, waterStress, nutrients);

    // 5. Recommendations (NDWI-aware)
    final recs = _buildRecommendations(
        latestNdvi, latestNdwi, soil, waterStress, nutrients, pests);

    // 6. Claude AI summary in Kiswahili
    final aiSummary = await _claudeSummary(
      ndvi: latestNdvi,
      ndwi: latestNdwi,
      soil: soil,
      waterStress: waterStress,
      nutrients: nutrients,
      pests: pests,
      score: score,
      fieldName: field.name,
    );

    return CropAnalysisReport(
      fieldId: field.id,
      generatedAt: now,
      overallHealthScore: score,
      latestNdvi: latestNdvi,
      latestNdwi: latestNdwi,
      soilAnalysis: soil,
      waterStress: waterStress,
      nutrients: nutrients,
      pestDisease: pests,
      recommendations: recs,
      aiSummary: aiSummary,
    );
  }

  // ── NDVI interpretation algorithms ────────────────────────────────────────

  SoilAnalysis _interpretSoil(
      NdviReading ndvi, Map<String, dynamic> weather) {
    final humidity =
        ((weather['main'] as Map?)?['humidity'] as num? ?? 65).toDouble();

    String status;
    double moisture;
    Map<String, String> nutrients;

    if (ndvi.average >= 0.6) {
      status   = 'Nzuri Sana';
      moisture = 60 + (ndvi.average - 0.6) * 100;
      nutrients = {'N': 'Kutosha', 'P': 'Kutosha', 'K': 'Kutosha'};
    } else if (ndvi.average >= 0.4) {
      status   = 'Wastani';
      moisture = 40 + ndvi.average * 30;
      nutrients = {'N': 'Wastani', 'P': 'Kutosha', 'K': 'Wastani'};
    } else if (ndvi.average >= 0.2) {
      status   = 'Mbaya';
      moisture = 20 + ndvi.average * 40;
      nutrients = {'N': 'Haitoshi', 'P': 'Wastani', 'K': 'Haitoshi'};
    } else {
      status   = 'Mbaya Sana';
      moisture = (ndvi.average * 50).clamp(5, 30);
      nutrients = {'N': 'Haitoshi Kabisa', 'P': 'Haitoshi', 'K': 'Haitoshi Kabisa'};
    }

    // Adjust moisture by humidity
    moisture = (moisture * (humidity / 100) * 1.3).clamp(5, 100);

    final textures = ['Tifutifu', 'Udongo Mwekundu', 'Mfinyanzi', 'Mchanga'];
    final texture  = textures[(ndvi.average * textures.length)
            .floor()
            .clamp(0, textures.length - 1)];

    return SoilAnalysis(
      status: status,
      moistureLevel: double.parse(moisture.toStringAsFixed(1)),
      texture: texture,
      nutrientLevels: nutrients,
    );
  }

  // NDWI-driven water stress — more accurate than NDVI-only estimation
  WaterStressAnalysis _interpretWaterStressFromNdwi(
    NdwiReading? ndwi,
    NdviReading ndvi,
    Map<String, dynamic> weather,
  ) {
    // If we have real NDWI, use it directly
    if (ndwi != null) {
      final status = ndwi.healthStatus;
      // Convert NDWI to a 0–1 stress index (inverted: high NDWI = low stress)
      final stressIndex =
          ((0.2 - ndwi.average) / 0.6).clamp(0.0, 1.0);

      return WaterStressAnalysis(
        level: status.labelSw,
        stressIndex: double.parse(stressIndex.toStringAsFixed(2)),
        recommendation: status.irrigationAdvice,
        ndwiReading: ndwi,
      );
    }

    // Fallback: estimate from NDVI + weather when NDWI unavailable
    final rain = ((weather['rain'] as Map?)?['1h'] as num? ?? 0).toDouble();
    final temp = ((weather['main'] as Map?)?['temp'] as num? ?? 28).toDouble();
    final stressIndex =
        (1.0 - ndvi.average + (temp - 25) / 30 - rain * 0.1).clamp(0.0, 1.0);

    String level;
    String recommendation;
    if (stressIndex < 0.25) {
      level = 'Hakuna Mkazo';
      recommendation = 'Mmea una maji ya kutosha. Endelea na umwagiliaji wa kawaida.';
    } else if (stressIndex < 0.5) {
      level = 'Mkazo Mdogo';
      recommendation = 'Ongeza umwagiliaji kidogo — mara moja kwa siku asubuhi mapema.';
    } else if (stressIndex < 0.75) {
      level = 'Mkazo wa Wastani';
      recommendation = 'Umwagiliaji wa haraka unahitajika. Piga mara mbili kwa siku.';
    } else {
      level = 'Mkazo Mkali';
      recommendation = '⚠️ Hatari! Mmea unakufa kwa ukosefu wa maji. Mwagilia SASA HIVI.';
    }

    return WaterStressAnalysis(
      level: level,
      stressIndex: double.parse(stressIndex.toStringAsFixed(2)),
      recommendation: recommendation,
    );
  }

  NutrientAnalysis _interpretNutrients(NdviReading ndvi) {
    final deficiencies = <NutrientDeficiency>[];

    if (ndvi.average < 0.5) {
      deficiencies.add(const NutrientDeficiency(
        nutrient: 'Nitrojeni (N)',
        severity: 'Wastani',
        symptoms:
            'Majani yanaonekana njano hasa ya zamani. Ukuaji umepungua.',
        treatment:
            'Weka mbolea ya Urea (46%N) — gramu 50 kwa mmea mmoja. Rudia baada ya wiki 3.',
      ));
    }

    if (ndvi.average < 0.35) {
      deficiencies.add(const NutrientDeficiency(
        nutrient: 'Fosforasi (P)',
        severity: 'Kali',
        symptoms:
            'Majani na mashina yanageuka zambarau/nyekundu. Mizizi mifupi.',
        treatment:
            'Weka DAP (18-46-0) gramu 30 kwa mmea. Changanya kwenye udongo.',
      ));
    }

    if (ndvi.average < 0.25) {
      deficiencies.add(const NutrientDeficiency(
        nutrient: 'Potasiamu (K)',
        severity: 'Kali',
        symptoms:
            'Kingo za majani zinaungua na kukauka. Matunda ni madogo.',
        treatment:
            'Weka Muriate of Potash (MOP) gramu 20 kwa mmea au CAN.',
      ));
    }

    final status = deficiencies.isEmpty
        ? 'Virutubisho Vya Kutosha'
        : deficiencies.length == 1
            ? 'Upungufu Mdogo'
            : 'Upungufu Mkubwa — Hatua ya Haraka Inahitajika';

    return NutrientAnalysis(
      deficiencies: deficiencies,
      overallStatus: status,
    );
  }

  PestDiseaseAnalysis _interpretPestRisk(
      NdviReading ndvi, Map<String, dynamic> weather) {
    final humidity =
        ((weather['main'] as Map?)?['humidity'] as num? ?? 65).toDouble();
    final temp =
        ((weather['main'] as Map?)?['temp'] as num? ?? 28).toDouble();

    final threats = <DetectedThreat>[];
    String riskLevel;

    // High humidity + warm temp + declining NDVI = disease risk
    if (humidity > 70 && temp > 25 && ndvi.average < 0.5) {
      threats.add(const DetectedThreat(
        name: 'Ugonjwa wa Ukungu (Blight)',
        type: 'Ugonjwa',
        severity: 'Wastani',
        description:
            'Hali ya hewa (joto + unyevu) inafaa ukuaji wa ukungu kwenye mimea.',
        treatments: [
          'Pulizia Ridomil Gold MZ 68WP — gramu 30 kwa dumu 15L',
          'Pulizia Dithane M-45 — gramu 40 kwa dumu 15L',
          'Ondoa majani yaliyoathirika mara moja',
        ],
      ));
    }

    // Low NDVI with specific pattern = pest damage
    if (ndvi.average < 0.4 && ndvi.max - ndvi.min > 0.3) {
      threats.add(const DetectedThreat(
        name: 'Viwavi wa Jeshi (Fall Armyworm)',
        type: 'Wadudu',
        severity: 'Juu',
        description:
            'Tofauti kubwa kati ya NDVI ya juu na ya chini inaonyesha uharibifu wa wadudu.',
        treatments: [
          'Pulizia Coragen 20SC — ml 20 kwa dumu 15L',
          'Pulizia Emamectin Benzoate — gramu 10 kwa dumu 15L',
          'Angalia shamba usiku — viwavi wanakula usiku',
        ],
      ));
    }

    riskLevel = threats.isEmpty
        ? 'Chini'
        : threats.length == 1
            ? 'Wastani'
            : 'Juu';

    return PestDiseaseAnalysis(threats: threats, riskLevel: riskLevel);
  }

  // ── Overall health score (0–100) ──────────────────────────────────────────

  double _calculateHealthScore(
    NdviReading ndvi,
    WaterStressAnalysis water,
    NutrientAnalysis nutrients,
  ) {
    final ndviScore    = ndvi.average * 50;
    final waterScore   = (1.0 - water.stressIndex) * 30;
    final nutrientScore =
        (1.0 - nutrients.deficiencies.length / 3.0) * 20;

    return (ndviScore + waterScore + nutrientScore).clamp(0, 100);
  }

  // ── Recommendations ───────────────────────────────────────────────────────

  List<String> _buildRecommendations(
    NdviReading ndvi,
    NdwiReading? ndwi,
    SoilAnalysis soil,
    WaterStressAnalysis water,
    NutrientAnalysis nutrients,
    PestDiseaseAnalysis pests,
  ) {
    final recs = <String>[];

    // NDWI-specific water recommendations (more precise than NDVI-derived)
    if (ndwi != null) {
      if (ndwi.healthStatus == NdwiHealthStatus.severeStress) {
        recs.add('🚨 NDWI: ${ndwi.average.toStringAsFixed(3)} — ${ndwi.healthStatus.irrigationAdvice}');
      } else if (ndwi.healthStatus == NdwiHealthStatus.moderateStress ||
                 ndwi.healthStatus == NdwiHealthStatus.slightStress) {
        recs.add('💧 NDWI inaonyesha mkazo wa maji — ${ndwi.healthStatus.irrigationAdvice}');
      } else if (ndwi.healthStatus == NdwiHealthStatus.wellWatered) {
        recs.add('✅ NDWI: maji ya kutosha — ${ndwi.healthStatus.irrigationAdvice}');
      }
    } else if (water.stressIndex > 0.4) {
      recs.add('💧 ${water.recommendation}');
    }

    for (final d in nutrients.deficiencies) {
      recs.add('🌱 Weka ${d.nutrient}: ${d.treatment}');
    }

    for (final t in pests.threats) {
      recs.add('🛡️ ${t.name}: ${t.treatments.first}');
    }

    if (ndvi.average < 0.3) {
      recs.add(
          '📊 NDVI ya chini sana — fikiria kupanda upya au kubadilisha zao.');
    }

    if (recs.isEmpty) {
      recs.add('✅ Shamba lako lipo katika hali nzuri. Endelea na huduma ya kawaida.');
    }

    return recs;
  }

  // ── Claude AI Kiswahili summary ───────────────────────────────────────────

  Future<String> _claudeSummary({
    required NdviReading ndvi,
    required NdwiReading? ndwi,
    required SoilAnalysis soil,
    required WaterStressAnalysis waterStress,
    required NutrientAnalysis nutrients,
    required PestDiseaseAnalysis pests,
    required double score,
    required String fieldName,
  }) async {
    final ndwiLine = ndwi != null
        ? '- NDWI (Mkazo wa Maji): ${ndwi.average.toStringAsFixed(3)} (${ndwi.healthStatus.labelSw}) — maudhui ya maji: ${ndwi.waterContentPercent.toStringAsFixed(0)}%'
        : '- NDWI: Haipo (kukosekana kwa data)';

    final prompt = '''
Wewe ni mtaalamu wa kilimo wa Tanzania.
Uchambuzi wa satellite wa shamba "$fieldName" unaonyesha:

- NDVI ya wastani: ${ndvi.average.toStringAsFixed(2)} (${ndvi.healthStatus.labelSw})
$ndwiLine
- Alama ya afya: ${score.toStringAsFixed(0)}/100
- Hali ya maji: ${waterStress.level} (index: ${waterStress.stressIndex.toStringAsFixed(2)})
- Hali ya udongo: ${soil.status}, unyevu: ${soil.moistureLevel.toStringAsFixed(0)}%
- Virutubisho: ${nutrients.overallStatus}
- Hatari ya wadudu/magonjwa: ${pests.riskLevel}
${pests.threats.isNotEmpty ? '- Vitisho vilivyogunduliwa: ${pests.threats.map((t) => t.name).join(', ')}' : ''}
${nutrients.deficiencies.isNotEmpty ? '- Upungufu wa virutubisho: ${nutrients.deficiencies.map((d) => d.nutrient).join(', ')}' : ''}

Toa muhtasari mfupi wa aya 2–3 wa afya ya mazao na hatua za vitendo 3–5 za kufanya sasa.
Andika kwa Kiswahili rahisi, tumia emoji. Maneno mafupi yanayofaa kusomwa kwenye simu.
''';

    try {
      final response = await http.post(
        Uri.parse(_claudeUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _claudeKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 600,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
    } catch (e) {
      // Fallback to a rule-based summary
    }

    // Fallback summary when Claude is unreachable
    return _fallbackSummary(ndvi, ndwi, score, waterStress, pests);
  }

  String _fallbackSummary(
    NdviReading ndvi,
    NdwiReading? ndwi,
    double score,
    WaterStressAnalysis water,
    PestDiseaseAnalysis pests,
  ) {
    final emoji = score >= 70 ? '🟢' : score >= 45 ? '🟡' : '🔴';
    final ndwiLine = ndwi != null
        ? '\n💧 NDWI: ${ndwi.average.toStringAsFixed(3)} (${ndwi.healthStatus.labelSw}) — ${ndwi.healthStatus.irrigationAdvice}'
        : '';
    return '''
$emoji Afya ya Shamba: ${score.toStringAsFixed(0)}/100 — ${ndvi.healthStatus.labelSw}

NDVI ya leo ni ${ndvi.average.toStringAsFixed(2)}, inayoonyesha mimea yako ${ndvi.healthStatus.labelSw.toLowerCase()}.$ndwiLine ${pests.threats.isNotEmpty ? 'Kuna hatari ya ${pests.threats.first.name} — ${pests.threats.first.treatments.first}.' : 'Hakuna vitisho vikubwa vya wadudu au magonjwa vimegunduliwa.'}

Endelea kufuatilia uchambuzi wa satellite kila wiki kwa matokeo mazuri zaidi.
'''.trim();
  }
}
