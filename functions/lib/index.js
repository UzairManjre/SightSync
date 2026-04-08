"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyzeImage = void 0;
const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const generative_ai_1 = require("@google/generative-ai");
admin.initializeApp();
// ─────────────────────────────────────────────────────────────────────────────
// PROMPTS PER FEATURE
// Tuned for visually impaired users — short, spatial, actionable responses.
// ─────────────────────────────────────────────────────────────────────────────
const PROMPTS = {
    scene: {
        system: "You are a concise assistive vision AI for a visually impaired person. " +
            "Describe what you see in 2 short sentences. " +
            "Name people, objects, text signs, hazards, and spatial positions. " +
            "Never speculate or add opinions. Be factual and specific.",
        user: "Describe this scene.",
    },
    text: {
        system: "You are an OCR assistant for a visually impaired person. " +
            "Transcribe EVERY word of visible text exactly as it appears, preserving layout. " +
            "If no text is present, respond only with: No text found.",
        user: "Read all visible text in this image.",
    },
    currency: {
        system: "You are a currency identification assistant for a visually impaired person. " +
            "Identify any banknotes or coins visible. " +
            "State the denomination, currency name, and country for each. " +
            "If multiple notes are present, list all of them. " +
            "If no currency is visible, respond only with: No currency detected.",
        user: "Identify any currency in this image.",
    },
    face: {
        system: "You are a face description assistant for a visually impaired person. " +
            "Describe any people visible: approximate age range, gender, hair color/style, " +
            "any distinctive features like glasses or a beard. " +
            "Use friendly, respectful language. " +
            "If no person is visible, respond only with: No person detected.",
        user: "Describe any person visible in this image.",
    },
};
// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE FUNCTION: analyzeImage
//
// Accepts:
//   imageBase64: string  — JPEG image encoded as base64
//   featureType: string  — one of: 'scene' | 'text' | 'currency' | 'face'
//
// Returns:
//   { result: string }
//
// The Gemini API key is stored as a Firebase Secret, never exposed to clients.
// ─────────────────────────────────────────────────────────────────────────────
exports.analyzeImage = functions.https.onCall({
    // Read the API key from Firebase Secret Manager at runtime
    secrets: ["GEMINI_API_KEY"],
    // Allow unauthenticated calls so the app works even before sign-in
    // (Firebase Auth still prevents direct API abuse via rate limiting + rules)
    enforceAppCheck: false,
    timeoutSeconds: 30,
    memory: "256MiB",
    region: "us-central1",
}, async (request) => {
    const { imageBase64, featureType } = request.data;
    // ── Validate inputs ────────────────────────────────────────
    if (!imageBase64 || typeof imageBase64 !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "imageBase64 is required.");
    }
    if (!featureType || !PROMPTS[featureType]) {
        throw new functions.https.HttpsError("invalid-argument", `featureType must be one of: ${Object.keys(PROMPTS).join(", ")}`);
    }
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new functions.https.HttpsError("internal", "AI service not configured.");
    }
    // ── Call Gemini 1.5 Flash ──────────────────────────────────
    const genAI = new generative_ai_1.GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
        safetySettings: [
            { category: generative_ai_1.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: generative_ai_1.HarmBlockThreshold.BLOCK_ONLY_HIGH },
            { category: generative_ai_1.HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: generative_ai_1.HarmBlockThreshold.BLOCK_ONLY_HIGH },
        ],
    });
    const prompt = PROMPTS[featureType];
    try {
        const result = await model.generateContent([
            {
                inlineData: {
                    mimeType: "image/jpeg",
                    data: imageBase64,
                },
            },
            `${prompt.system}\n\n${prompt.user}`,
        ]);
        const text = result.response.text().trim();
        functions.logger.info(`[AI] ${featureType} → ${text.substring(0, 80)}...`);
        return { result: text };
    }
    catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        functions.logger.error(`[AI] Gemini error for ${featureType}:`, message);
        throw new functions.https.HttpsError("internal", `AI analysis failed: ${message}`);
    }
});
//# sourceMappingURL=index.js.map