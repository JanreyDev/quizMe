import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'add_questions_screen.dart';

class MaterialPreviewScreen extends StatefulWidget {
  final String classCode;
  final String title;
  final String teacherName;
  final DateTime dueDate;
  final List<Question> questions;
  final String collectionName;
  final String materialTitle;
  final String? existingMaterialId;
  final File? pdfFile;
  final String? extractedText;

  const MaterialPreviewScreen({
    super.key,
    required this.classCode,
    required this.title,
    required this.teacherName,
    required this.dueDate,
    required this.questions,
    required this.collectionName,
    required this.materialTitle,
    this.existingMaterialId,
    this.pdfFile,
    this.extractedText,
  });

  @override
  State<MaterialPreviewScreen> createState() => _MaterialPreviewScreenState();
}

class _MaterialPreviewScreenState extends State<MaterialPreviewScreen> {
  bool _isSaving = false;

  Future<String?> _uploadPdf(File file) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
      final ref = FirebaseStorage.instance.ref().child(
        'materials/pdfs/$fileName',
      );
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('PDF Upload Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayLabel = widget.materialTitle;
    if (displayLabel.endsWith('s')) {
      displayLabel = displayLabel.substring(0, displayLabel.length - 1);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.classCode,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayLabel Type:',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                if (widget.pdfFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attached PDF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                widget.pdfFile!.path
                                    .split(Platform.pathSeparator)
                                    .last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.extractedText != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    constraints: const BoxConstraints(maxHeight: 400),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXTRACTED TEXT PREVIEW:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.extractedText!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ...widget.questions.map((q) {
                  if (q.type == 'MULTIPLE CHOICE') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Multiple Choice'),
                        _buildQuestionCard(
                          question: q.question,
                          options: q.options ?? [],
                          correctAnswer: q.answer,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  } else if (q.type == 'TRUE OR FALSE') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('TRUE or FALSE'),
                        Text(
                          q.question.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildToggleButton(
                              'TRUE',
                              isSelected: q.answer == 'TRUE',
                            ),
                            const SizedBox(width: 12),
                            _buildToggleButton(
                              'FALSE',
                              isSelected: q.answer == 'FALSE',
                            ),
                          ],
                        ),
                        if (q.answer == 'FALSE' &&
                            q.correction != null &&
                            q.correction!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'CORRECTION: ${q.correction}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    );
                  } else if (q.type == 'ENUMERATION') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Enumeration'),
                        Text(q.question, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            q.answer,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  } else {
                    // Identification
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Identification'),
                        _buildPillButton(q.question),
                        const SizedBox(height: 12),
                        _buildQuestionInput(
                          question: 'Answer:',
                          answer: q.answer,
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }
                }).toList(),

                const SizedBox(height: 48),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              try {
                                String? pdfUrl;
                                if (widget.pdfFile != null) {
                                  pdfUrl = await _uploadPdf(widget.pdfFile!);
                                }

                                final materialData = {
                                  'classCode': widget.classCode,
                                  'title': widget.title,
                                  'teacherName': widget.teacherName,
                                  'dueDate': widget.dueDate,
                                  'isPublished': true,
                                  'pdfUrl': pdfUrl, // Save the URL
                                  'extractedText': widget
                                      .extractedText, // Save the full text
                                  'questions': widget.questions
                                      .map(
                                        (q) => {
                                          'type': q.type,
                                          'question': q.question,
                                          'options': q.options,
                                          'answer': q.answer,
                                          'correction': q.correction,
                                        },
                                      )
                                      .toList(),
                                };

                                if (widget.existingMaterialId != null) {
                                  await FirebaseFirestore.instance
                                      .collection(widget.collectionName)
                                      .doc(widget.existingMaterialId)
                                      .update(materialData);
                                } else {
                                  materialData['createdAt'] =
                                      FieldValue.serverTimestamp();
                                  await FirebaseFirestore.instance
                                      .collection(widget.collectionName)
                                      .add(materialData);
                                }
                                if (mounted) {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error saving $displayLabel: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save as ${displayLabel.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isSaving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String question,
    required List<String> options,
    required String correctAnswer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    opt == correctAnswer
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: opt == correctAnswer ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    opt,
                    style: TextStyle(
                      color: opt == correctAnswer ? Colors.blue : Colors.black,
                      fontWeight: opt == correctAnswer
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              answer,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, {required bool isSelected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
