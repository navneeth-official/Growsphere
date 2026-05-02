/// What we ask the vision model to focus on (same [DiseaseReport] shape for UI).
enum ImageAnalysisIntent {
  plantHealthAndDisease,
  pestIdentification,
  plantSpeciesIdentification,
}

/// **Firebase:** upload image to Storage, run Cloud Function + Vertex AI / custom model.
abstract class DiseaseAnalysisRepository {
  Future<DiseaseReport> analyzeImageBytes(
    List<int> bytes, {
    String? plantName,
    ImageAnalysisIntent intent = ImageAnalysisIntent.plantHealthAndDisease,
  });
}

class DiseaseReport {
  DiseaseReport({required this.label, required this.severity, required this.advice});

  final String label;
  final String severity;
  final String advice;
}

class StubDiseaseAnalysisRepository implements DiseaseAnalysisRepository {
  @override
  Future<DiseaseReport> analyzeImageBytes(
    List<int> bytes, {
    String? plantName,
    ImageAnalysisIntent intent = ImageAnalysisIntent.plantHealthAndDisease,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return DiseaseReport(
      label: 'Unconfirmed leaf stress (demo)',
      severity: 'Low–medium (educational stub)',
      advice: 'This build does not run a real vision model. Check for uniform yellowing (nutrient), '
          'angular spots (fungal), or stippling (thrips). Improve airflow and avoid overhead watering at night.'
          '${plantName != null ? ' Plant: $plantName.' : ''}',
    );
  }
}
