import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class MLKitService {
  static final MLKitService _instance = MLKitService._internal();
  factory MLKitService() => _instance;
  MLKitService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  late ImageLabeler _imageLabeler;
  late ObjectDetector _objectDetector;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Image Labeling configuration
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));

    // Object Detection configuration (Standard model)
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );

    _initialized = true;
  }

  /// [Scene] combines image labeling and object detection into a descriptive summary.
  Future<String> describeScene(File imageFile) async {
    await init();
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final labels = await _imageLabeler.processImage(inputImage);
      final objects = await _objectDetector.processImage(inputImage);

      if (labels.isEmpty && objects.isEmpty) return "I'm not sure what I'm looking at. Try moving the camera slightly.";

      final labelDescriptions = labels
          .take(3)
          .map((l) => l.label.toLowerCase())
          .join(", ");

      final objectDescriptions = objects
          .where((o) => o.labels.isNotEmpty)
          .map((o) => o.labels.first.text.toLowerCase())
          .toSet()
          .toList();

      String description = "";
      if (objectDescriptions.isNotEmpty) {
        if (objectDescriptions.length == 1) {
          description = "I see a ${objectDescriptions[0]}. ";
        } else {
          final last = objectDescriptions.removeLast();
          description = "I see a ${objectDescriptions.join(', ')} and a $last. ";
        }
      }

      if (labelDescriptions.isNotEmpty) {
        description += "The surroundings look like a $labelDescriptions.";
      }

      return description.isEmpty ? "I see some items but I'm not sure what they are." : description;
    } catch (e) {
      return "Offline analysis failed: ${e.toString()}";
    }
  }

  /// [Text] reads characters from an image file.
  Future<String> readText(File imageFile) async {
    await init();
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      if (recognizedText.text.trim().isEmpty) return "I don't see any text here.";
      return "The text reads: ${recognizedText.text}";
    } catch (e) {
      return "Offline text reading failed: ${e.toString()}";
    }
  }

  /// [Currency] uses object detection to identify money.
  Future<String> detectCurrency(File imageFile) async {
    await init();
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final objects = await _objectDetector.processImage(inputImage);
      final currency = objects
          .expand((o) => o.labels)
          .firstWhere((l) => l.text.toLowerCase().contains("money") || l.text.toLowerCase().contains("bill") || l.text.toLowerCase().contains("currency"),
              orElse: () => Label(text: "not recognized", confidence: 0, index: 0));

      if (currency.text == "not recognized") {
        return "I can't identify the currency from this angle. Please hold it closer.";
      }
      return "I think I see some $currency.";
    } catch (e) {
      return "Offline currency detection failed.";
    }
  }

  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _objectDetector.close();
  }
}
