/// **Where to put your Google AI Studio API key**
///
/// 1. **Recommended (dev & release builds):** pass at build/run time so the key is **not** committed:
///    ```text
///    flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
///    flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
///    ```
///
/// 2. **Optional model overrides** (defaults target widely available Flash models; copy ids from
///    [Google AI Studio](https://aistudio.google.com/) API panel, e.g. Flash Lite preview strings):
///    ```text
///    --dart-define=GEMINI_MODEL=gemini-2.0-flash
///    --dart-define=GEMINI_RESEARCH_MODEL=gemini-2.5-flash-lite-preview-05-2024
///    ```
///    If `GEMINI_RESEARCH_MODEL` is omitted, add-crop research uses `GEMINI_MODEL`.
///
/// Keys from [Google AI Studio](https://aistudio.google.com/) work with the `google_generative_ai` package.

abstract final class GeminiRuntimeConfig {
  /// API key from `flutter run --dart-define=GEMINI_API_KEY=...`
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Model id from AI Studio (e.g. `gemini-2.0-flash`, or a preview id you copy from the API panel).
  static const String model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  /// Optional separate model for add-crop research (e.g. Flash Lite preview). Empty → [model].
  static const String researchModel = String.fromEnvironment(
    'GEMINI_RESEARCH_MODEL',
    defaultValue: '',
  );

  static String get effectiveResearchModel => researchModel.isEmpty ? model : researchModel;

  static bool get isConfigured => apiKey.isNotEmpty;
}
