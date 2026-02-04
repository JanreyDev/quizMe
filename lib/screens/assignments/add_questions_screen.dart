import 'package:flutter/material.dart';
import 'dart:io';
import 'material_preview_screen.dart';

class Question {
  final String type;
  final String question;
  final List<String>? options;
  final String answer;

  Question({
    required this.type,
    required this.question,
    this.options,
    required this.answer,
  });
}

class AddQuestionsScreen extends StatefulWidget {
  final String classCode;
  final Map<String, String> selectedRanges;
  final String title;
  final String teacherName;
  final DateTime dueDate;
  final String collectionName;
  final String materialTitle;
  final String? existingMaterialId;
  final List<Question>? existingQuestions;
  final File? pickedFile;
  final String? extractedText;
  final List<Question>? initialQuestions;

  const AddQuestionsScreen({
    super.key,
    required this.classCode,
    required this.selectedRanges,
    required this.title,
    required this.teacherName,
    required this.dueDate,
    required this.collectionName,
    required this.materialTitle,
    this.existingMaterialId,
    this.existingQuestions,
    this.pickedFile,
    this.extractedText,
    this.initialQuestions,
  });

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final List<Question> _questions = [];
  String? _currentlyAddingType;
  File? _pickedFile;

  @override
  void initState() {
    super.initState();
    _pickedFile = widget.pickedFile;
    if (widget.initialQuestions != null) {
      _questions.addAll(widget.initialQuestions!);
    } else if (widget.existingQuestions != null) {
      _questions.addAll(widget.existingQuestions!);
    }
  }

  // Controllers for the form
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final TextEditingController _answerController = TextEditingController();
  bool _isTrue = true;
  final ScrollController _scrollController = ScrollController();

  void _addQuestion() {
    if (_questionController.text.isEmpty) return;

    final newQuestion = Question(
      type: _currentlyAddingType!,
      question: _questionController.text,
      options: _currentlyAddingType == 'MULTIPLE CHOICE'
          ? _optionControllers.map((c) => c.text).toList()
          : null,
      answer: _currentlyAddingType == 'TRUE OR FALSE'
          ? (_isTrue ? 'TRUE' : 'FALSE')
          : _answerController.text,
    );

    setState(() {
      if (_editingIndex != null) {
        _questions[_editingIndex!] = newQuestion;
      } else {
        _questions.add(newQuestion);
      }
      _currentlyAddingType = null;
      _editingIndex = null;
      _resetForm();
    });
  }

  void _resetForm() {
    _questionController.clear();
    for (var c in _optionControllers) {
      c.clear();
    }
    _answerController.clear();
    _isTrue = true;
  }

  @override
  Widget build(BuildContext context) {
    int maxItems =
        50; // We can remove the range restriction or calculate it from selectedRanges if needed

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
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pickedFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attached: ${_pickedFile!.path.split(RegExp(r'[/\\]')).last}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _pickedFile = null),
                        ),
                      ],
                    ),
                  ),
                if (widget.extractedText != null &&
                    widget.extractedText!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
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
                          'EXTRACTED REFERENCE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: SingleChildScrollView(
                            child: Text(
                              widget.extractedText!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ...List.generate(_questions.length, (index) {
                  final q = _questions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _editQuestion(index),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${index + 1} • ${q.type}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  q.question,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (q.options != null &&
                                    q.options!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: q.options!.map((opt) {
                                      final isCorrect = opt == q.answer;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCorrect
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isCorrect
                                                ? Colors.green.withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          opt,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isCorrect
                                                ? Colors.green.shade700
                                                : Colors.black54,
                                            fontWeight: isCorrect
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          q.answer,
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Removed 'Add' link as per user request
                if (_currentlyAddingType != null) _buildQuestionForm(),

                const SizedBox(height: 32),
                if (_questions.isNotEmpty)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaterialPreviewScreen(
                              classCode: widget.classCode,
                              title: widget.title,
                              teacherName: widget.teacherName,
                              dueDate: widget.dueDate,
                              questions: _questions,
                              collectionName: widget.collectionName,
                              materialTitle: widget.materialTitle,
                              existingMaterialId: widget.existingMaterialId,
                              pdfFile: _pickedFile,
                              extractedText: widget.extractedText,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Submit',
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
        ],
      ),
    );
  }

  int? _editingIndex;

  void _editQuestion(int index) {
    setState(() {
      _editingIndex = index;
      final q = _questions[index];
      _currentlyAddingType = q.type;
      _questionController.text = q.question;
      _answerController.text = q.answer;
      if (q.options != null && q.options!.length == 4) {
        for (int i = 0; i < 4; i++) {
          _optionControllers[i].text = q.options![i];
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showTypeSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.selectedRanges.keys.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () {
                  setState(() {
                    _currentlyAddingType = type;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildQuestionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentlyAddingType!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _currentlyAddingType = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Question',
              hintText: 'Enter your question here',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_currentlyAddingType == 'MULTIPLE CHOICE') ...[
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Option ${String.fromCharCode(65 + index)}',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${String.fromCharCode(65 + index)}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Correct Answer',
                hintText: 'e.g. A',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else if (_currentlyAddingType == 'TRUE OR FALSE') ...[
            const Text(
              'Select Correct Answer:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeRadioButton(label: 'TRUE', value: true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTypeRadioButton(label: 'FALSE', value: false),
                ),
              ],
            ),
          ] else if (_currentlyAddingType == 'ENUMERATION') ...[
            TextField(
              controller: _answerController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Answers',
                hintText: 'Enter items separated by commas',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            // Identification
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Correct Answer',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _editingIndex != null ? 'Update Question' : 'Add Question',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRadioButton({required String label, required bool value}) {
    bool isSelected = _isTrue == value;
    return GestureDetector(
      onTap: () => setState(() => _isTrue = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4FC3F7).withOpacity(0.2)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4FC3F7) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue.shade900 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
