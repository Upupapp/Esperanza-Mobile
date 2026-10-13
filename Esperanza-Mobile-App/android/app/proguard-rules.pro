# Release shrinking (R8) rules for this app; Flutter's Gradle plugin applies
# this file to the release build.

# google_mlkit_text_recognition (Add ID reads the resident's ID photos on the
# phone, 2026-10-13). The plugin can start recognisers for Chinese,
# Devanagari, Japanese and Korean script, but the app bundles only the Latin
# model that Philippine IDs need, so those classes are absent on purpose.
# Without these lines R8 stops the release build on the missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
