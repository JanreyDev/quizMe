import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TakeExamScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final bool isReadOnly;
  final String? studentId;

  const TakeExamScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    this.isReadOnly = false,
    this.studentId,
  });

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  final Map<int, dynamic> _answers = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  List<dynamic> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadAssignmentData();
  }

  Future<void> _loadAssignmentData() async {
    try {
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();

      if (mounted) {
        if (!assignmentDoc.exists) {
          setState(() {
            _errorMessage = 'Assignment not found.';
            _isLoading = false;
          });
          return;
        }

        final data = assignmentDoc.data();
        final questions = (data?['questions'] as List? ?? []);

        // If read-only, fetch the student's submission
        if (widget.isReadOnly) {
          final targetStudentId =
              widget.studentId ?? FirebaseAuth.instance.currentUser?.uid;
          if (targetStudentId != null) {
            final submissionQuery = await FirebaseFirestore.instance
                .collection('submissions')
                .where('assignmentId', isEqualTo: widget.assignmentId)
                .where('studentId', isEqualTo: targetStudentId)
                .limit(1)
                .get();

            if (submissionQuery.docs.isNotEmpty) {
              final subData =
                  submissionQuery.docs.first.data() as Map<String, dynamic>?;
              final answers =
                  subData?['answers'] as Map<String, dynamic>? ?? {};

              // Convert String keys back to int for our internal map
              answers.forEach((key, value) {
                _answers[int.parse(key)] = value;
              });
            }
          }
          _isSubmitted = true; // For UI purposes
        }

        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading: $e';
          _isLoading = false;
        });
      }
    }
  }

  bool _allQuestionsAnswered() {
    if (_questions.isEmpty) return false;
    for (int i = 0; i < _questions.length; i++) {
      if (!_answers.containsKey(i) ||
          _answers[i] == null ||
          (_answers[i] is String && _answers[i].toString().trim().isEmpty)) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _getScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      if (q['type'] == 'MULTIPLE CHOICE' || q['type'] == 'TRUE OR FALSE') {
        if (_answers[i] == q['answer']) {
          score++;
        }
      } else if (q['type'] == 'IDENTIFICATION' || q['type'] == 'ENUMERATION') {
        final studentAns = _answers[i]?.toString().trim().toLowerCase();
        final correctAns = q['answer']?.toString().trim().toLowerCase();
        if (studentAns == correctAns) {
          score++;
        }
      }
    }
    return score;
  }

  int _getTotalGradable() {
    return _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacherViewing = widget.studentId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => _showExitConfirmation(),
        ),
        title: Text(
          widget.assignmentTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Column(
              children: [
                if (isTeacherViewing)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Auto-Calculated Score:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_getScore()} / ${_getTotalGradable()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    // Safer check for list content
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions found.'));
    }
    return _buildQuestionList();
  }

  Widget _buildQuestionList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index] as Map<String, dynamic>;
              return _buildQuestionCard(index, q);
            },
          ),
        ),
        if (widget.studentId == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildCompletionSection(),
          ),
      ],
    );
  }

  Widget _buildCompletionSection() {
    final showCompletedHeader = _allQuestionsAnswered() && !widget.isReadOnly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Header Box - Only show when all answered and not readonly
        if (showCompletedHeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 20, color: Colors.black),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "You've completed your exam!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D2428),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (showCompletedHeader) const SizedBox(height: 16),

        // Submit Button (Hidden in Read-Only)
        if (!widget.isReadOnly)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isSubmitting || _isSubmitted)
                  ? null
                  : _turnInAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5F3CA),
                disabledBackgroundColor: const Color(
                  0xFFA5F3CA,
                ).withOpacity(0.5),
                foregroundColor: const Color(0xFF1A1A40),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A1A40),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isSubmitted ? 'Turned in' : 'Turn in your answers',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          )
        else
          const Center(
            child: Text(
              'View Mode Only',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

        if (_isSubmitted && !widget.isReadOnly) ...[
          const SizedBox(height: 24),
          const Icon(
            Icons.check_circle_outline,
            size: 60,
            color: Color(0xFF1D2428),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    final type = q['type'] as String;
    final questionText = q['question'] as String;

    final studentAns = _answers[index];
    final correctAns = q['answer'];
    final isTeacherViewing = widget.studentId != null;
    final isGradable = type == 'MULTIPLE CHOICE' || type == 'TRUE OR FALSE';

    // For Identification/Enumeration, check equality
    bool isCorrect = false;
    if (isTeacherViewing) {
      if (isGradable) {
        isCorrect = studentAns == correctAns;
      } else {
        isCorrect =
            studentAns?.toString().trim().toLowerCase() ==
            correctAns?.toString().trim().toLowerCase();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: isTeacherViewing ? const EdgeInsets.all(16) : null,
      decoration: isTeacherViewing
          ? BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isTeacherViewing)
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            questionText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          if (isTeacherViewing && !isCorrect && isGradable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Correct: $correctAns',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (type == 'MULTIPLE CHOICE')
            _buildMultipleChoice(index, q['options'] as List? ?? [])
          else if (type == 'TRUE OR FALSE')
            _buildTrueFalse(index)
          else if (type == 'IDENTIFICATION')
            _buildIdentification(index)
          else if (type == 'ENUMERATION')
            _buildIdentification(
              index,
            ), // For now, use text input for enumeration
          if (!isTeacherViewing) const Divider(height: 40),
        ],
      ),
    );
  }

  Widget _buildMultipleChoice(int qIndex, List options) {
    final studentAns = _answers[qIndex];
    final correctAns = _questions[qIndex]['answer'];
    final isTeacherViewing = widget.studentId != null;

    return Column(
      children: options.map((opt) {
        final optionStr = opt.toString();
        bool isSelected = studentAns == optionStr;
        bool isCorrectChoice = optionStr == correctAns;

        Color? textColor;
        FontWeight? fontWeight;
        if (isTeacherViewing) {
          if (isCorrectChoice) {
            textColor = Colors.green[700];
            fontWeight = FontWeight.bold;
          } else if (isSelected && !isCorrectChoice) {
            textColor = Colors.red[700];
            fontWeight = FontWeight.bold;
          }
        }

        return RadioListTile(
          title: Text(
            optionStr,
            style: TextStyle(color: textColor, fontWeight: fontWeight),
          ),
          value: optionStr,
          groupValue: studentAns,
          activeColor: isTeacherViewing && isCorrectChoice
              ? Colors.green
              : isTeacherViewing && isSelected
              ? Colors.red
              : null,
          onChanged: widget.isReadOnly
              ? null
              : (val) => setState(() => _answers[qIndex] = val),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse(int qIndex) {
    return Row(
      children: [
        _buildChoiceChip(qIndex, 'TRUE'),
        const SizedBox(width: 12),
        _buildChoiceChip(qIndex, 'FALSE'),
      ],
    );
  }

  Widget _buildChoiceChip(int qIndex, String label) {
    final studentAns = _answers[qIndex];
    final correctAns = _questions[qIndex]['answer'];
    final isTeacherViewing = widget.studentId != null;
    final isSelected = studentAns == label;
    final isCorrectChoice = label == correctAns;

    Color? selectedColor = Colors.blue[100];
    Color? labelColor = isSelected ? Colors.blue[700] : Colors.black;

    if (isTeacherViewing) {
      if (isCorrectChoice) {
        selectedColor = Colors.green[200];
        labelColor = Colors.green[900];
      } else if (isSelected && !isCorrectChoice) {
        selectedColor = Colors.red[200];
        labelColor = Colors.red[900];
      }
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected || (isTeacherViewing && isCorrectChoice),
      onSelected: widget.isReadOnly
          ? null
          : (val) => setState(() => _answers[qIndex] = label),
      selectedColor: selectedColor,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: labelColor,
        fontWeight: isTeacherViewing && (isCorrectChoice || isSelected)
            ? FontWeight.bold
            : FontWeight.normal,
      ),
    );
  }

  Widget _buildIdentification(int qIndex) {
    if (!_controllers.containsKey(qIndex)) {
      _controllers[qIndex] = TextEditingController(
        text: _answers[qIndex]?.toString() ?? '',
      );
    }
    return TextField(
      controller: _controllers[qIndex],
      onChanged: widget.isReadOnly
          ? null
          : (val) => setState(() => _answers[qIndex] = val),
      enabled: !widget.isReadOnly,
      decoration: InputDecoration(
        hintText: 'Type your answer here',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _turnInAnswers() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      // Convert integer keys to Strings for Firestore compatibility
      final stringAnswers = _answers.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      // Save to submissions collection
      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': widget.assignmentId,
        'studentId': user.uid,
        'studentEmail': user.email,
        'answers': stringAnswers,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam turned in successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Optional: Pop after a delay to let them see the checkmark
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error turning in: $e')));
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text('Your answers will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit exam
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
