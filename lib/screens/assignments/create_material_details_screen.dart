import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'add_questions_screen.dart';
import '../../services/ai_question_service.dart';

class CreateMaterialDetailsScreen extends StatefulWidget {
  final String classCode;
  final Map<String, String> selectedRanges; // Map instead of Set/String
  final String collectionName;
  final String materialTitle;
  final String? existingMaterialId;
  final Map<String, dynamic>? existingData;

  const CreateMaterialDetailsScreen({
    super.key,
    required this.classCode,
    required this.selectedRanges,
    required this.collectionName,
    required this.materialTitle,
    this.existingMaterialId,
    this.existingData,
  });

  @override
  State<CreateMaterialDetailsScreen> createState() =>
      _CreateMaterialDetailsScreenState();
}

class _CreateMaterialDetailsScreenState
    extends State<CreateMaterialDetailsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  File? _pickedFile; // Changed from _pdfFile to support other types
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _nameController.text = widget.existingData!['teacherName'] ?? '';
      final dueDate = widget.existingData!['dueDate'] as Timestamp?;
      if (dueDate != null) {
        _selectedDate = dueDate.toDate();
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFileAndGenerateQuestions() async {
    if (_titleController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the title, name, and due date first.'),
        ),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );

      if (result != null) {
        setState(() {
          _isAiLoading = true;
          _pickedFile = File(result.files.single.path!);
        });

        final bytes =
            result.files.single.bytes ??
            await File(result.files.single.path!).readAsBytes();

        final fileName = result.files.single.name;

        final aiResult = await AiQuestionService.generateQuestions(
          fileBytes: bytes, // Changed parameter name
          fileName: fileName,
          selectedRanges: widget.selectedRanges,
        );

        if (mounted) {
          setState(() => _isAiLoading = false);
          _navigateToQuestions(aiResult.questions, aiResult.extractedText);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Generation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToQuestions([
    List<Question>? aiQuestions,
    String? extractedText,
  ]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionsScreen(
          classCode: widget.classCode,
          selectedRanges: widget.selectedRanges,
          title: _titleController.text,
          teacherName: _nameController.text,
          dueDate: _selectedDate!,
          collectionName: widget.collectionName,
          materialTitle: widget.materialTitle,
          existingMaterialId: widget.existingMaterialId,
          pickedFile: _pickedFile,
          extractedText: extractedText ?? widget.existingData?['extractedText'],
          initialQuestions: aiQuestions,
          existingQuestions: (widget.existingData?['questions'] as List?)
              ?.map(
                (q) => Question(
                  type: q['type'] ?? '',
                  question: q['question'] ?? '',
                  options: (q['options'] as List?)?.cast<String>(),
                  answer: q['answer'] ?? '',
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.materialTitle.toLowerCase();
    if (displayTitle.endsWith('s')) {
      displayTitle = displayTitle.substring(0, displayTitle.length - 1);
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Create a Title and Name of your $displayTitle:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _titleController,
                  label: 'Title:',
                  hint: 'Enter $displayTitle title',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Name:',
                  hint: 'Enter your name',
                ),
                const SizedBox(height: 32),
                Text(
                  'Add the due date of the $displayTitle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Enter date:'
                              : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      // Magic AI Section
                      if (_pickedFile == null)
                        InkWell(
                          onTap: _pickFileAndGenerateQuestions,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF42A5F5).withOpacity(0.5),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Color(0xFF42A5F5),
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Upload File to Magic Generate',
                                  style: TextStyle(
                                    color: Color(0xFF42A5F5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AI will generate the exam from your PDF',
                                  style: TextStyle(
                                    color: Colors.blue.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedFile!.path
                                          .split(RegExp(r'[/\\]'))
                                          .last,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'File uploaded successfully',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _pickedFile = null),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a due date'),
                                ),
                              );
                              return;
                            }
                            _navigateToQuestions();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isAiLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text(
                          'AI is reading your PDF...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Generating questions and answers.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
