import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../screens/assignments/add_questions_screen.dart';

class AiResult {
  final List<Question> questions;
  final String extractedText;

  AiResult({required this.questions, required this.extractedText});
}

class AiQuestionService {
  // IMPORTANT: For production, store this securely (e.g., environment variables)
  // Get your API key from: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBsqFgD_ymtW0Tjy4-3x10gJ3rHiGoKJdg';

  static Future<AiResult> generateQuestions({
    required Uint8List fileBytes,
    required String fileName,
    required Map<String, String> selectedRanges,
  }) async {
    try {
      if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
        throw Exception(
          'Please set your Gemini API key in lib/services/ai_question_service.dart',
        );
      }

      String text = '';
      DataPart? filePart;

      // 1. Handle File Extraction / Preparation
      if (fileName.toLowerCase().endsWith('.pdf')) {
        try {
          final PdfDocument document = PdfDocument(inputBytes: fileBytes);
          text = PdfTextExtractor(document).extractText();
          document.dispose();
        } catch (e) {
          // Fallback to DataPart if PDF text extraction fails
          filePart = DataPart('application/pdf', fileBytes);
        }
      } else {
        // For DOCX, PPTX etc, we use DataPart since we don't have local extractors
        String mimeType = 'application/octet-stream';
        if (fileName.endsWith('.docx'))
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        else if (fileName.endsWith('.doc'))
          mimeType = 'application/msword';
        else if (fileName.endsWith('.pptx'))
          mimeType =
              'application/vnd.openxmlformats-officedocument.presentationml.presentation';
        else if (fileName.endsWith('.ppt'))
          mimeType = 'application/vnd.ms-powerpoint';

        filePart = DataPart(mimeType, fileBytes);
      }

      // 2. Initialize Gemini AI
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      // 3. Prepare the Prompt with Range details
      String rangeDetails = selectedRanges.entries
          .map((e) => "- ${e.key}: ${e.value}")
          .join('\n');

      final prompt =
          '''
You are a teacher's assistant. I will provide you with a file/text.

TASK:
1. Scan the content and generate/extract questions based on these EXACT requested ranges:
$rangeDetails

2. For each range, ensure the question numbers match the range (e.g., if Multiple Choice is 1-15, the first question should be #1).
3. If the content has existing questions, prioritize extracting them. If not enough exist, generate new ones based on the context.
4. ENSURE the types are strictly followed as requested.

Supported Question Types: MULTIPLE CHOICE, TRUE OR FALSE, IDENTIFICATION, ENUMERATION

Return the result as a raw JSON array of objects with this structure:
{
  "type": "MULTIPLE CHOICE" | "TRUE OR FALSE" | "IDENTIFICATION" | "ENUMERATION",
  "question": "The question text",
  "options": ["Option A", "Option B", "Option C", "Option D"], // Only for MULTIPLE CHOICE.
  "answer": "The correct answer"
}

IMPORTANT: Return ONLY the JSON array. Do not include any extra text.
''';

      // 4. Call Gemini
      final List<Content> content = [
        Content.multi([
          TextPart(prompt),
          if (filePart != null) filePart else TextPart("Text Content:\n$text"),
        ]),
      ];
      final response = await model.generateContent(content);

      String? jsonResponse = response.text;
      if (jsonResponse == null)
        throw Exception('AI failed to generate a response.');

      // Clean the response if it contains markdown code blocks
      if (jsonResponse.contains('```json')) {
        jsonResponse = jsonResponse
            .split('```json')
            .last
            .split('```')
            .first
            .trim();
      } else if (jsonResponse.contains('```')) {
        jsonResponse = jsonResponse.split('```').last.split('```').first.trim();
      }

      // 5. Parse JSON into Question objects
      final List<dynamic> data = jsonDecode(jsonResponse);
      final questions = data.map((item) {
        return Question(
          type: item['type'] as String,
          question: item['question'] as String,
          options: item['options'] != null
              ? List<String>.from(item['options'])
              : null,
          answer: item['answer'].toString(),
        );
      }).toList();

      return AiResult(
        questions: questions,
        extractedText: text.isNotEmpty
            ? text
            : "Content extracted from ${fileName}",
      );
    } catch (e) {
      rethrow;
    }
  }
}
