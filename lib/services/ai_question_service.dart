import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../screens/assignments/add_questions_screen.dart';

import 'package:archive/archive.dart';

class AiResult {
  final List<Question> questions;
  final String extractedText;

  AiResult({required this.questions, required this.extractedText});
}

class OfficeTextExtractor {
  static String extractPptxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final sb = StringBuffer();

      final slideFiles = archive
          .where(
            (f) =>
                f.name.startsWith('ppt/slides/slide') &&
                f.name.endsWith('.xml'),
          )
          .toList();

      // Sort slides numerically slide1, slide2, etc.
      slideFiles.sort((a, b) {
        final aNum =
            int.tryParse(RegExp(r'\d+').firstMatch(a.name)?.group(0) ?? '0') ??
            0;
        final bNum =
            int.tryParse(RegExp(r'\d+').firstMatch(b.name)?.group(0) ?? '0') ??
            0;
        return aNum.compareTo(bNum);
      });

      for (var file in slideFiles) {
        final content = utf8.decode(file.content as List<int>);
        // Extract text inside <a:t> tags (Standard PPTX text tags)
        final regex = RegExp(r'<a:t>(.*?)</a:t>', dotAll: true);
        final matches = regex.allMatches(content);
        for (var match in matches) {
          String t = match.group(1) ?? '';
          // Basic entity decoding
          t = t
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'");
          sb.write('$t ');
        }
        sb.write('\n');
      }
      return sb.toString().trim();
    } catch (e) {
      return "Extraction failed: $e";
    }
  }

  static String extractDocxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file == null) return '';

      final content = utf8.decode(file.content as List<int>);
      final sb = StringBuffer();
      // Extract text inside <w:t> tags (Standard Word text tags)
      final regex = RegExp(r'<w:t.*?>(.*?)</w:t>', dotAll: true);
      final matches = regex.allMatches(content);
      for (var match in matches) {
        String t = match.group(1) ?? '';
        t = t
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'");
        sb.write(t);
      }
      return sb.toString().trim();
    } catch (e) {
      return "Extraction failed: $e";
    }
  }
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
      final nameLower = fileName.toLowerCase();
      if (nameLower.endsWith('.pdf')) {
        try {
          final PdfDocument document = PdfDocument(inputBytes: fileBytes);
          text = PdfTextExtractor(document).extractText();
          document.dispose();
        } catch (e) {
          // Fallback to DataPart if PDF text extraction fails
          filePart = DataPart('application/pdf', fileBytes);
        }
      } else if (nameLower.endsWith('.pptx')) {
        text = OfficeTextExtractor.extractPptxText(fileBytes);
      } else if (nameLower.endsWith('.docx')) {
        text = OfficeTextExtractor.extractDocxText(fileBytes);
      } else {
        // Fallback for other types - Use DataPart if supported, else text extraction if possible
        String mimeType = 'application/octet-stream';
        if (nameLower.endsWith('.doc'))
          mimeType = 'application/msword';
        else if (nameLower.endsWith('.ppt'))
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
