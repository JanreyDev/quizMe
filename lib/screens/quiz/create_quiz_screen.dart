import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleController = TextEditingController();
  final List<QuestionModel> _questions = [QuestionModel()];
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionModel());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
      });
    }
  }

  Future<void> _saveQuiz() async {
    if (_selectedClassId == null) {
      _showError('Please select a class for this quiz');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a quiz title');
      return;
    }

    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].isValid()) {
        _showError('Please complete question #${i + 1}');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final quizData = {
        'title': _titleController.text.trim(),
        'classId': _selectedClassId,
        'className': _selectedClassName,
        'teacherId': user?.uid,
        'teacherName': user?.displayName ?? 'Teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'questions': _questions.map((q) => q.toMap()).toList(),
      };

      await FirebaseFirestore.instance.collection('quizzes').add(quizData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to save quiz: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Create New Quiz',
          style: TextStyle(
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3A5C)),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveQuiz,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5DADE2),
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Class
            const Text(
              'Assign to Class',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .where('teacherId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const LinearProgressIndicator();

                final classes = snapshot.data?.docs ?? [];
                if (classes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No classes found. Please create a class first.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5DADE2).withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a class'),
                      value: _selectedClassId,
                      items: classes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(data['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                          _selectedClassName =
                              (classes.firstWhere((doc) => doc.id == val).data()
                                  as Map<String, dynamic>)['name'];
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Quiz Title
            const Text(
              'Quiz Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(_titleController, 'e.g. Science Midterm'),
            const SizedBox(height: 32),

            // Questions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                    color: Color(0xFF5DADE2),
                  ),
                  label: const Text(
                    'Add Question',
                    style: TextStyle(color: Color(0xFF5DADE2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionCard(index);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5DADE2).withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                'Question #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5DADE2),
                ),
              ),
              if (_questions.length > 1)
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(question.textController, 'Enter the question'),
          const SizedBox(height: 16),
          const Text(
            'Options',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (optIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: question.correctOptionIndex,
                    onChanged: (val) {
                      setState(() {
                        question.correctOptionIndex = val!;
                      });
                    },
                    activeColor: const Color(0xFF5DADE2),
                  ),
                  Expanded(
                    child: _buildTextField(
                      question.optionControllers[optIndex],
                      'Option ${optIndex + 1}',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class QuestionModel {
  final textController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int correctOptionIndex = 0;

  void dispose() {
    textController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
  }

  bool isValid() {
    if (textController.text.trim().isEmpty) return false;
    for (var c in optionControllers) {
      if (c.text.trim().isEmpty) return false;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': textController.text.trim(),
      'options': optionControllers.map((c) => c.text.trim()).toList(),
      'correctAnswerIndex': correctOptionIndex,
    };
  }
}
