import 'package:flutter/material.dart';
import 'exam_preview_screen.dart';

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
  final Set<String> selectedTypes;
  final String itemCount;
  final String title;
  final String teacherName;
  final DateTime dueDate;

  const AddQuestionsScreen({
    super.key,
    required this.classCode,
    required this.selectedTypes,
    required this.itemCount,
    required this.title,
    required this.teacherName,
    required this.dueDate,
  });

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final List<Question> _questions = [];
  String? _currentlyAddingType;

  // Controllers for the form
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final TextEditingController _answerController = TextEditingController();
  bool _isTrue = true;

  void _addQuestion() {
    if (_questionController.text.isEmpty) return;

    setState(() {
      _questions.add(
        Question(
          type: _currentlyAddingType!,
          question: _questionController.text,
          options: _currentlyAddingType == 'MULTIPLE CHOICE'
              ? _optionControllers.map((c) => c.text).toList()
              : null,
          answer: _currentlyAddingType == 'TRUE OR FALSE'
              ? (_isTrue ? 'TRUE' : 'FALSE')
              : _answerController.text,
        ),
      );
      _currentlyAddingType = null;
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
    int maxItems = int.tryParse(widget.itemCount.split('-').last) ?? 10;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(_questions.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // TODO: Implement editing logic
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (_questions.length < maxItems && _currentlyAddingType == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_questions.length + 1}. ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showTypeSelection(),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_currentlyAddingType != null) _buildQuestionForm(),

            const SizedBox(height: 32),
            if (_questions.isNotEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamPreviewScreen(
                          classCode: widget.classCode,
                          title: widget.title,
                          teacherName: widget.teacherName,
                          dueDate: widget.dueDate,
                          questions: _questions,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTypeSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.selectedTypes.map((type) {
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
              child: const Text(
                'Add Question',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
