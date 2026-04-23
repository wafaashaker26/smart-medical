class DiseaseProba {
  final String disease;
  final double probability;

  DiseaseProba({required this.disease, required this.probability});

  factory DiseaseProba.fromJson(Map<String, dynamic> j) =>
      DiseaseProba(
        disease: j['disease'],
        probability: (j['probability'] as num).toDouble(),
      );
}

class PredictionResult {
  final String disease;
  final String riskLevel;
  final int riskScore;
  final List<DiseaseProba> probabilities;
  final List<String> explanation;
  final String aiSummary;

  PredictionResult({
    required this.disease,
    required this.riskLevel,
    required this.riskScore,
    required this.probabilities,
    required this.explanation,
    required this.aiSummary,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) =>
      PredictionResult(
        disease: j['disease'],
        riskLevel: j['risk_level'],
        riskScore: j['risk_score'],
        probabilities: (j['probabilities'] as List)
            .map((e) => DiseaseProba.fromJson(e))
            .toList(),
        explanation: List<String>.from(j['explanation']),
        aiSummary: j['ai_summary'] ?? '',
      );
}