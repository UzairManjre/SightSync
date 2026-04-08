import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'remote_config_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROMPT LIBRARY
// ─────────────────────────────────────────────────────────────────────────────

// SCENE: Fully detailed — describes every visible element layer by layer.
// The user wants a comprehensive reading, not a brief summary.
final _kScenePrompt = '''
You are the eyes of a person who is blind or has very low vision.
Your job is to describe EVERYTHING visible in this image in a way that fully replaces sight.
Do NOT summarise. Be thorough. Think of this like narrating a scene to someone in a phone call.

STRUCTURE YOUR RESPONSE LIKE THIS:
1. Quick orientation (1 sentence): What kind of place is this? Indoors or outdoors? Day or night?
2. Primary subject or focal point: What is directly in front of the camera?
3. Left side details: What is on the left of the frame?
4. Right side details: What is on the right of the frame?
5. Background: What is in the distance or background?
6. People: Are there any people? How many? Where are they? What are they doing? Are they looking at the camera?
7. Text: Is any text visible? If yes, read it.
8. Hazards: Any steps, wet floors, moving objects, obstacles, open doors, vehicles nearby?

RULES:
- Use spatial words constantly: "directly in front", "to your left", "behind", "above", "below", "about one metre away", "in the far background".
- Describe colours, sizes, and positions of major objects.
- If something is unclear, say "what appears to be" rather than skipping it.
- Do NOT say "I see", "In this image", or "The photo shows". Start immediately with the scene.
- Do NOT use bullet points or numbered lists in output — speak in full flowing sentences.
- Aim for 5 to 8 sentences of rich detail.

EXAMPLE OUTPUT:
"You appear to be standing in a kitchen. Directly in front of you is a white refrigerator with a few magnets on it, about two metres away. To your left is a wooden dining table with four chairs around it, and a vase of yellow flowers at its centre. On the right side there is a kitchen counter with a kettle, a toaster, and some dishes. The ceiling has a single warm light fixture. A window is visible on the far right, showing daylight and what appears to be a garden outside. There is no one else visible in the room. No obvious hazards are present."
''';

final _kTextPrompt = '''
You are a reading assistant for a person who cannot see text.
Your sole task: read every single piece of text visible in this image, exactly as written.

RULES:
1. Read ALL text — signs, labels, packaging, screens, menus, handwriting, posters, buttons, price tags, receipts, warnings.
2. Read in natural visual order: top to bottom, left to right.
3. Introduce separate text blocks naturally: "A sign reads:", "The label says:", "On the screen:", "The poster reads:".
4. Preserve important punctuation that affects meaning (exclamation marks, question marks, colons).
5. For line breaks within one block, say "next line:" to preserve structure.
6. Spell out numbers and prices as words for TTS clarity (e.g. say "one hundred and fifty rupees" not "Rs 150").
7. If no text is visible at all, say: "No text is visible in this image."
8. Never add your own opinions or explanation of what the text means — just read it.

EXAMPLE OUTPUT:
"A sign reads: Staff Only. Next line: Authorised Personnel Beyond This Point. Below that, a smaller label reads: Room two zero four."
''';

final _kCurrencyPrompt = '''
You are a currency identification expert assisting a person who is blind.
Your task is to examine this image and identify every banknote and coin with maximum precision.

RULES:
1. State each note or coin with: denomination (in words), currency name, and country.
2. List from highest to lowest denomination.
3. After listing all, state the grand total in words if all currency is from the same country.
4. Use words not symbols. Say "rupees" not the rupee sign. Say "dollars" not a dollar sign.
5. If only partially visible, state what you can determine and say "partially visible".
6. Consider all visual cues: colour, size, portraits, watermarks, serial number prefix, security thread colour, denomination numeral.
7. If you are confident in identification, be direct. If unsure, say "appears to be".
8. If zero currency is visible, say: "No currency is visible in this image."
9. If currency is present but completely unidentifiable, say: "Currency is present but I cannot read the denomination clearly. Please hold it flat and closer to the camera."

EXAMPLE OUTPUT:
"I can see two Indian banknotes. One five hundred rupee note featuring the Red Fort monument, and one one hundred rupee note. Total: six hundred Indian rupees."
''';

final _kFacePrompt = '''
You are a face and person description assistant for a person who is blind or has low vision.
Your task is to describe every person visible so the user understands who is nearby and what they are doing.

RULES:
1. For each person describe in this order: where they are relative to the camera, approximate distance, estimated age range, gender presentation, skin tone, hair (colour, length, style), what they are wearing (colour and type of clothing), notable accessories or features (glasses, beard, hat, uniform, wheelchair, bag).
2. Describe their body language and what they appear to be doing: "standing still", "walking towards you", "seated and looking at a phone", "talking to someone off-camera".
3. Note if they appear to be looking at the camera (i.e. at you).
4. If multiple people, describe each person in order of proximity to the camera.
5. Be factual and respectful. No negative comments on appearance.
6. If no person is visible say: "There is no one visible in this image."
7. Do NOT say "I see" or "In the image". Start directly with the description.

EXAMPLE OUTPUT:
"One person is standing directly in front of you, roughly one metre away. They appear to be a woman in her late twenties with medium-length dark brown hair tied back. She is wearing a light blue shirt and dark jeans. She appears to be looking towards you and smiling slightly."
''';

// Per-feature generation configs — tuned for each task
final Map<String, GenerationConfig> _kGenConfigs = {
  'scene': GenerationConfig(
    temperature: 0.4,      // Higher so it generates rich, varied descriptions
    maxOutputTokens: 800,  // Enough for 8 detailed sentences
    topK: 40,
    topP: 0.95,
  ),
  'text': GenerationConfig(
    temperature: 0.1,      // Very low — must reproduce text exactly
    maxOutputTokens: 600,
    topK: 10,
    topP: 0.9,
  ),
  'currency': GenerationConfig(
    temperature: 0.05,     // Near-zero — denomination must be a specific fact
    maxOutputTokens: 256,
    topK: 10,
    topP: 0.9,
  ),
  'face': GenerationConfig(
    temperature: 0.2,
    maxOutputTokens: 400,
    topK: 32,
    topP: 0.95,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// GEMINI SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  String _promptFor(String featureType) {
    switch (featureType) {
      case 'scene':    return _kScenePrompt;
      case 'text':     return _kTextPrompt;
      case 'currency': return _kCurrencyPrompt;
      case 'face':     return _kFacePrompt;
      default: throw Exception('Unknown feature type: $featureType');
    }
  }

  /// Analyses [imageBytes] using Gemini 1.5 Flash.
  /// [featureType] must be 'scene', 'text', 'currency', or 'face'.
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String featureType,
  }) async {
    // Trim whitespace — a common issue when pasting into Firebase console
    final apiKey = RemoteConfigService().geminiApiKey.trim();

    if (apiKey.isEmpty) {
      throw Exception(
        'AI not configured. Please ask your administrator to set up the API key in Firebase Remote Config.',
      );
    }

    // Safe diagnostic log — shows key length and first/last 3 chars only
    debugPrint('[GEMINI] Key loaded: ${apiKey.length} chars, '
        'starts with "${apiKey.substring(0, apiKey.length > 6 ? 6 : apiKey.length)}…"');

    // Validate: reject corrupt/empty images that cause hallucinations
    if (imageBytes.length < 2048) {
      throw Exception(
        'Captured image was too small (${imageBytes.length} bytes). '
        'Please ensure the camera lens is unobstructed and retry.',
      );
    }

    final prompt = _promptFor(featureType);
    final genConfig = _kGenConfigs[featureType]!;

    final model = GenerativeModel(
      // gemini-1.5-flash-8b: 150 RPM on free tier (10x higher than 1.5-flash)
      // Faster latency, perfect for real-time assistive device use
      model: 'gemini-1.5-flash-8b',
      apiKey: apiKey,
      generationConfig: genConfig,
      safetySettings: [
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
      ],
    );

    // Attempt the API call with one automatic retry on rate limit
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final imagePart  = DataPart('image/jpeg', imageBytes);
        final promptPart = TextPart(prompt.trim());

        final response = await model.generateContent([
          Content.multi([imagePart, promptPart]),
        ]);

        final text = response.text?.trim();
        if (text == null || text.isEmpty) {
          throw Exception('Gemini returned an empty response for $featureType.');
        }

        debugPrint('[GEMINI:$featureType] ${imageBytes.length} bytes in, '
            '${text.length} chars out — '
            '"${text.substring(0, text.length > 80 ? 80 : text.length)}..."');

        return text;

      } on GenerativeAIException catch (e) {
        final msg = e.message ?? e.toString();
        debugPrint('[GEMINI] GenerativeAIException attempt $attempt ($featureType): $msg');

        final isRateLimit = msg.toLowerCase().contains('quota') ||
            msg.toLowerCase().contains('rate') ||
            msg.toLowerCase().contains('429') ||
            msg.toLowerCase().contains('resource_exhausted');

        if (isRateLimit && attempt == 1) {
          // Wait 2 seconds and retry once
          debugPrint('[GEMINI] Rate limit hit — waiting 2s before retry...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        if (isRateLimit) {
          throw Exception(
            'Gemini rate limit reached. Wait a few seconds and try again.');
        } else if (msg.toLowerCase().contains('api_key') ||
            msg.toLowerCase().contains('invalid') ||
            msg.toLowerCase().contains('unauthorized')) {
          throw Exception(
            'Invalid API key. Please re-check the key in Firebase Remote Config.');
        } else if (msg.toLowerCase().contains('safety') ||
            msg.toLowerCase().contains('blocked')) {
          throw Exception(
            'Image blocked by safety filters. Try a different scene.');
        } else {
          throw Exception('Gemini API error: $msg');
        }
      } catch (e) {
        final errStr = e.toString();
        debugPrint('[GEMINI] Unexpected error attempt $attempt ($featureType): $errStr');
        if (e is Exception) rethrow;
        throw Exception('Unexpected error: $errStr');
      }
    }

    // Should not reach here — kept for Dart compiler
    throw Exception('Gemini analysis failed after retries. Please try again.');
  }
}
