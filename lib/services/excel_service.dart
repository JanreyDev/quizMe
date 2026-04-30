import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class ExcelService {
  static const String _sessionFileName = 'session_data.xlsx';

  static const String _prompt = '''
Analyze this image carefully. Extract only the actual DATA FIELDS from it.

Return ONLY a valid JSON object in this format (no markdown, no extra text):
{
  "fields": [
    {"title": "Field Name 1", "value": "Field Value 1"},
    {"title": "Field Name 2", "value": "Field Value 2"}
  ]
}

Rules:
- SKIP: form titles, headings, section labels, instructions, and any decorative text.
- INCLUDE ONLY: actual fillable fields and their filled-in values.
- For CHECKBOX or MULTIPLE-CHOICE fields (e.g. Classification, Employment Status, Civil Status):
    - If a box/option is checked or marked, put only the selected option as the value.
    - If nothing is checked, put "None" as the value.
- For text fields: put the written text as the value. If blank, put "None".
- Return ONLY the JSON, no extra explanation.
''';

  static Future<String> get _sessionFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_sessionFileName';
  }

  /// Returns true if a session file already exists
  static Future<bool> hasSession() async {
    final path = await _sessionFilePath;
    return File(path).existsSync();
  }

  /// Returns how many data rows (excluding header) are in the session
  static Future<int> getSessionRowCount() async {
    final path = await _sessionFilePath;
    final file = File(path);
    if (!file.existsSync()) return 0;
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.first;
    final rows = sheet.rows;
    return rows.length > 1 ? rows.length - 1 : 0; // subtract header row
  }

  /// Returns all data in the current session as a list of maps (column -> value)
  static Future<List<Map<String, String>>> getSessionData() async {
    final path = await _sessionFilePath;
    final file = File(path);
    if (!file.existsSync()) return [];

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.first;
    if (sheet.rows.isEmpty) return [];

    final headers = sheet.rows.first.map<String>((cell) {
      final val = cell?.value;
      if (val == null) return '';
      // Handle excel 4.x CellValue types
      return val is TextCellValue ? val.value.toString() : val.toString();
    }).toList();

    final List<Map<String, String>> data = [];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final Map<String, String> rowData = {};
      for (int j = 0; j < headers.length; j++) {
        final header = headers[j];
        if (header.isEmpty) continue;

        final cell = j < row.length ? row[j] : null;
        final val = cell?.value;
        String stringVal = '';
        if (val != null) {
          // Handle excel 4.x CellValue types
          stringVal = val is TextCellValue ? val.value.toString() : val.toString();
        }
        rowData[header] = stringVal.isEmpty ? 'None' : stringVal;
      }
      data.add(rowData);
    }
    return data;
  }

  /// Deletes a specific row (by 0-based data index, i.e., index 0 is first data row)
  static Future<void> deleteRowFromSession(int index) async {
    final path = await _sessionFilePath;
    final file = File(path);
    if (!file.existsSync()) return;

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.first;

    // The data row is at index + 1 (because of header)
    if (index + 1 < sheet.rows.length) {
      sheet.removeRow(index + 1);
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }
    }
  }

  /// Extract fields from a single image
  static Future<List<Map<String, String>>> _extractFieldsFromImage(
    File imageFile,
    GenerativeModel model,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    final mimeType = imageFile.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    const maxRetries = 4;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await model.generateContent([
          Content.multi([TextPart(_prompt), DataPart(mimeType, imageBytes)]),
        ]);

        String? jsonText = response.text;
        if (jsonText == null || jsonText.isEmpty) {
          throw Exception('AI returned empty response. Please try again.');
        }

        final String cleanJson = _sanitizeJson(jsonText);
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        final List<dynamic> fields = data['fields'] as List<dynamic>;
        return fields
            .map(
              (f) => {
                'title': (f['title'] ?? '').toString(),
                'value': (f['value'] ?? '').toString(),
              },
            )
            .toList();
      } catch (e) {
        final errStr = e.toString();
        // Quota / rate limit exceeded (429) — wait 35s
        final isQuotaError =
            errStr.contains('429') ||
            errStr.contains('quota') ||
            errStr.contains('Quota') ||
            errStr.contains('RESOURCE_EXHAUSTED');
        // Server overloaded (503) — wait a few seconds
        final isServerError =
            errStr.contains('503') ||
            errStr.contains('UNAVAILABLE') ||
            errStr.contains('high demand');

        if ((isQuotaError || isServerError) && attempt < maxRetries) {
          int waitSeconds;
          if (isQuotaError) {
            // Try to parse "Please retry in X.XXXs." from error message
            final retryMatch = RegExp(
              r'retry in (\d+(?:\.\d+)?)s',
            ).firstMatch(errStr);
            final parsedSeconds = retryMatch != null
                ? double.tryParse(retryMatch.group(1) ?? '') ?? 60.0
                : 60.0;
            waitSeconds = parsedSeconds.ceil() + 5; // add 5s buffer
          } else {
            waitSeconds = 3 * attempt;
          }
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed after $maxRetries attempts. Please try again.');
  }

  static String _sanitizeJson(String input) {
    String jsonText = input;
    if (jsonText.contains('```json')) {
      jsonText = jsonText.split('```json').last.split('```').first.trim();
    } else if (jsonText.contains('```')) {
      jsonText = jsonText.split('```')[1].trim();
    }
    // Remove any trailing/leading non-json characters if they still exist
    final start = jsonText.indexOf('{');
    final end = jsonText.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      jsonText = jsonText.substring(start, end + 1);
    }
    return jsonText;
  }

  /// Process a batch of images and APPEND to the persistent session Excel.
  /// Creates a new session file if none exists.
  /// Returns the total number of data rows after appending.
  static Future<int> addBatchToSession(
    List<File> imageFiles, {
    void Function(int current, int total)? onProgress,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: Secrets.geminiApiKey,
    );

    // 1. Extract fields from all new images
    // Delay 3s between requests to stay under 20 RPM free-tier limit
    final List<List<Map<String, String>>> allImageFields = [];
    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);
      if (i > 0) await Future.delayed(const Duration(seconds: 3));
      final fields = await _extractFieldsFromImage(imageFiles[i], model);
      allImageFields.add(fields);
    }

    final sessionPath = await _sessionFilePath;
    final sessionFile = File(sessionPath);

    // 2. Load or create Excel
    Excel excel;
    Sheet sheet;
    List<String> masterHeaders;

    if (sessionFile.existsSync()) {
      // Load existing session
      final bytes = await sessionFile.readAsBytes();
      excel = Excel.decodeBytes(bytes);
      sheet = excel.sheets.values.first;
      masterHeaders = sheet.rows.isNotEmpty
          ? sheet.rows.first
                .map<String>((cell) {
                  final val = cell?.value;
                  if (val == null) return '';
                  // Handle excel 4.x CellValue types
                  return val is TextCellValue 
                    ? val.value.toString() 
                    : val.toString();
                })
                .toList()
          : [];

      // Add any new headers that don't already exist (case-insensitive match)
      for (final fields in allImageFields) {
        for (final f in fields) {
          final title = f['title']!.trim();
          final alreadyExists = masterHeaders.any(
            (h) => h.trim().toLowerCase() == title.toLowerCase(),
          );
          if (!alreadyExists) {
            masterHeaders.add(title);
          }
        }
      }
    } else {
      // New session: collect all unique headers from this batch
      excel = Excel.createExcel();
      sheet = excel['Sheet1'];
      masterHeaders = [];
      for (final fields in allImageFields) {
        for (final f in fields) {
          final title = f['title']!.trim();
          final alreadyExists = masterHeaders.any(
            (h) => h.trim().toLowerCase() == title.toLowerCase(),
          );
          if (!alreadyExists) {
            masterHeaders.add(title);
          }
        }
      }
      // Write header row once
      sheet.appendRow(masterHeaders.map((h) => TextCellValue(h)).toList());
    }

    // 3. Append one value row per new image
    //    Match values case-insensitively so 'First Name' == 'first name'
    for (final fields in allImageFields) {
      // Build a normalized lookup map: lowercase(title) → value
      final fieldMap = {
        for (var f in fields) f['title']!.trim().toLowerCase(): f['value']!,
      };
      final valueRow = masterHeaders
          .map((h) => TextCellValue(fieldMap[h.trim().toLowerCase()] ?? 'None'))
          .toList();
      sheet.appendRow(valueRow);
    }

    // 4. Save back to session file
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await sessionFile.writeAsBytes(fileBytes);
    }

    // Return total data rows (rows - 1 header)
    return (sheet.rows.length - 1).clamp(0, 999999);
  }

  /// Share the current session Excel file
  static Future<void> shareSession() async {
    final path = await _sessionFilePath;
    final file = File(path);
    if (!file.existsSync()) throw Exception('No session data to export.');
    await Share.shareXFiles([XFile(path)], text: 'Exported data');

  }

  /// Delete the session file (clear all accumulated data)
  static Future<void> clearSession() async {
    final path = await _sessionFilePath;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
