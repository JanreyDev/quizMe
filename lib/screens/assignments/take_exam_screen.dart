import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TakeExamScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final bool isReadOnly;
  final String? studentId;
  final String collectionName;

  const TakeExamScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    this.isReadOnly = false,
    this.studentId,
    required this.collectionName,
  });

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  final Map<int, dynamic> _answers = {};
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _tfControllers = {};
  bool _isSubmitting = false;

  List<dynamic> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitted = false;
  String? _pdfUrl;
  String? _extractedText;
  final Map<int, bool?> _manualGrades = {};

  @override
  void initState() {
    super.initState();
    _loadAssignmentData();
  }

  Future<void> _loadAssignmentData() async {
    try {
      final assignmentDoc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
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
        _pdfUrl = data?['pdfUrl']; // Fetch the PDF URL
        _extractedText = data?['extractedText']; // Fetch the full text

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
              final existingManualGrades =
                  subData?['manualGrades'] as Map<String, dynamic>? ?? {};

              // Convert String keys back to int for our internal map
              answers.forEach((key, value) {
                _answers[int.parse(key)] = value;
              });

              // Initialize manual grades and load corrections
              for (int i = 0; i < questions.length; i++) {
                final q = questions[i] as Map<String, dynamic>;
                final type = q['type'];

                // Load corrections if they exist
                if (_answers[i] is Map) {
                  final tfAns = _answers[i] as Map;
                  if (tfAns.containsKey('correction')) {
                    _tfControllers[i] = TextEditingController(
                      text: tfAns['correction'],
                    );
                  }
                }

                // If we have saved manual grades, use them
                if (existingManualGrades.containsKey(i.toString())) {
                  _manualGrades[i] =
                      existingManualGrades[i.toString()] as bool?;
                } else {
                  // Otherwise, auto-grade if objective
                  if (type == 'MULTIPLE CHOICE' || type == 'TRUE OR FALSE') {
                    if (type == 'TRUE OR FALSE') {
                      final studentAns = _answers[i];
                      if (studentAns is Map) {
                        final choice = studentAns['choice'];
                        final correction = studentAns['correction'];
                        final isChoiceCorrect = choice == q['answer'];
                        if (choice == 'FALSE') {
                          // For FALSE, both choice and correction must be right (basic auto-grade)
                          final isCorrectionCorrect =
                              correction?.toString().toLowerCase() ==
                              q['correction']?.toString().toLowerCase();
                          _manualGrades[i] =
                              isChoiceCorrect && isCorrectionCorrect;
                        } else {
                          _manualGrades[i] = isChoiceCorrect;
                        }
                      } else {
                        _manualGrades[i] = studentAns == q['answer'];
                      }
                    } else {
                      _manualGrades[i] = _answers[i] == q['answer'];
                    }
                  } else {
                    _manualGrades[i] = null; // Pending
                  }
                }
              }
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open PDF')));
      }
    }
  }

  bool _allQuestionsAnswered() {
    if (_questions.isEmpty) return false;
    for (int i = 0; i < _questions.length; i++) {
      final ans = _answers[i];
      final q = _questions[i] as Map<String, dynamic>;

      if (!_answers.containsKey(i) || ans == null) return false;

      if (q['type'] == 'TRUE OR FALSE') {
        if (ans is Map) {
          final choice = ans['choice'];
          final correction = ans['correction'];
          if (choice == null) return false;
          if (choice == 'FALSE' && (correction == null || correction.isEmpty)) {
            return false;
          }
        } else if (ans is String) {
          if (ans.isEmpty) return false;
          if (ans == 'FALSE') return false; // Need correction
        }
      } else if (ans is String && ans.trim().isEmpty) {
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
    try {
      if (_manualGrades.isEmpty) return 0;
      return _manualGrades.values.where((v) => v == true).length;
    } catch (e) {
      debugPrint('Error in _getScore: $e');
      return 0;
    }
  }

  int _getTotalGradable() {
    return _questions.length;
  }

  Future<void> _saveGrades() async {
    setState(() => _isSubmitting = true);
    try {
      final targetStudentId =
          widget.studentId ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetStudentId == null) throw 'No student identified';

      final submissionQuery = await FirebaseFirestore.instance
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.assignmentId)
          .where('studentId', isEqualTo: targetStudentId)
          .limit(1)
          .get();

      if (submissionQuery.docs.isEmpty) throw 'Submission not found';

      final docId = submissionQuery.docs.first.id;

      // Convert manualGrades to String keys for Firestore
      final stringGrades = _manualGrades.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      await FirebaseFirestore.instance
          .collection('submissions')
          .doc(docId)
          .update({
            'manualGrades': stringGrades,
            'score': _getScore(),
            'gradedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grades saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving grades: $e')));
      }
    }
  }

  void _showGradingModal(int index, Map<String, dynamic> q) {
    final studentAns = _answers[index];
    final correctAns = q['answer']?.toString() ?? 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isCorrect = _manualGrades[index];

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Answer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Question ${index + 1}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(q['question'] ?? ''),
                  const SizedBox(height: 16),
                  const Text(
                    'Student\'s Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  () {
                    if (studentAns is Map) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHOICE: ${studentAns['choice']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CORRECTION: ${studentAns['correction']}',
                              style: TextStyle(
                                color: isCorrect == true
                                    ? Colors.green
                                    : isCorrect == false
                                    ? Colors.red
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Text(
                      studentAns?.toString() ?? 'No answer',
                      style: TextStyle(
                        color: isCorrect == true
                            ? Colors.green
                            : isCorrect == false
                            ? Colors.red
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  }(),
                  const SizedBox(height: 16),
                  const Text(
                    'Teacher\'s Correct Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  () {
                    if (q['type'] == 'MULTIPLE CHOICE') {
                      final options = q['options'] as List? ?? [];
                      final idx = options.indexOf(correctAns);
                      if (idx != -1) {
                        final letter = String.fromCharCode(65 + idx);

                        String cleanedAns = correctAns.trim();
                        final labelRegex = RegExp(
                          r'^[A-D][\.\)\-\s]+',
                          caseSensitive: false,
                        );
                        cleanedAns = cleanedAns
                            .replaceFirst(labelRegex, '')
                            .trim();

                        return Text(
                          '$letter. $cleanedAns',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      }
                    } else if (q['type'] == 'ENUMERATION') {
                      String clean = correctAns.trim();
                      if (clean.startsWith('[') && clean.endsWith(']')) {
                        clean = clean.substring(1, clean.length - 1);
                      }
                      final items = clean
                          .split(RegExp(r'[,;]'))
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      if (items.length > 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: items
                                .map(
                                  (item) => Text(
                                    '• $item',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      }
                    }

                    return Text(
                      correctAns,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  }(),
                  if (q['type'] == 'TRUE OR FALSE' && q['answer'] == 'FALSE')
                    Text(
                      'CORRECTION: ${q['correction'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _manualGrades[index] = false);
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Mark Wrong'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _manualGrades[index] = true);
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Mark Correct'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
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
        actions: [
          if (_pdfUrl != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => _launchUrl(_pdfUrl!),
              tooltip: 'View Reference PDF',
            ),
        ],
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
                if (isTeacherViewing)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _saveGrades,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSubmitting ? 'Saving...' : 'Save Grading Changes',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
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
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions found.'));
    }

    // Group questions by type for sections
    final groupedQuestions = <String, List<Map<String, dynamic>>>{};
    int questionNumber = 1;
    for (var q in _questions) {
      final qData = q as Map<String, dynamic>;
      final type = qData['type'] as String;
      if (!groupedQuestions.containsKey(type)) {
        groupedQuestions[type] = [];
      }
      final qWithNumber = Map<String, dynamic>.from(qData);
      qWithNumber['_questionNumber'] = questionNumber++;
      groupedQuestions[type]!.add(qWithNumber);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_extractedText != null) _buildReferenceMaterial(),
              const SizedBox(height: 16),
              ...() {
                final List<Widget> widgets = [];
                int sectionNum = 1;
                groupedQuestions.forEach((type, questionsInSection) {
                  // Section Header
                  final sectionTitle = type == 'IDENTIFICATION'
                      ? 'Section $sectionNum: Identification (Write the answer)'
                      : type == 'ENUMERATION'
                      ? 'Section $sectionNum: Enumeration'
                      : type == 'MULTIPLE CHOICE'
                      ? 'Section $sectionNum: Multiple Choice'
                      : type == 'TRUE OR FALSE'
                      ? 'Section $sectionNum: True or False'
                      : 'Section $sectionNum: $type';

                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Text(
                        sectionTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32), // Green like in PDF
                        ),
                      ),
                    ),
                  );

                  for (var qData in questionsInSection) {
                    final qIndex = _questions.indexOf(qData);
                    final qNum = qData['_questionNumber'] as int;
                    widgets.add(
                      _buildStructuredQuestionCard(qNum, qIndex, qData),
                    );
                  }
                  sectionNum++;
                });
                return widgets;
              }(),
            ],
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

  Widget _buildStructuredQuestionCard(
    int qNum,
    int originalIndex,
    Map<String, dynamic> q,
  ) {
    final type = q['type'] as String;
    final questionText = q['question'] as String;
    final isTeacherViewing = widget.studentId != null;

    bool isCorrect = false;
    bool isWrong = false;

    try {
      final manualGrade = _manualGrades[originalIndex];
      isCorrect = manualGrade == true;
      isWrong = manualGrade == false;
    } catch (e) {}

    return InkWell(
      onTap: isTeacherViewing
          ? () => _showGradingModal(originalIndex, q)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: isTeacherViewing
            ? BoxDecoration(
                color: isCorrect
                    ? Colors.green.shade50
                    : isWrong
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green.shade200
                      : isWrong
                      ? Colors.red.shade200
                      : Colors.grey.shade300,
                  width: 2,
                ),
              )
            : null,
        child: Column(
          children: [
            // Question number and premium pill
            _buildMockupQuestion('$qNum. $questionText'),
            const SizedBox(height: 24),
            if (type == 'MULTIPLE CHOICE')
              _buildStructuredMultipleChoice(
                originalIndex,
                q['options'] as List? ?? [],
              )
            else if (type == 'TRUE OR FALSE')
              _buildTrueFalse(originalIndex)
            else if (type == 'IDENTIFICATION' || type == 'ENUMERATION')
              _buildIdentification(originalIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildMockupQuestion(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold, // Formal bold
          color: Color(0xFF1B1B4B),
        ),
      ),
    );
  }

  Widget _buildReferenceMaterial() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'STUDY MATERIAL / REFERENCE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            _extractedText!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredMultipleChoice(int qIndex, List options) {
    final studentAns = _answers[qIndex];
    return Column(
      children: options.asMap().entries.map((entry) {
        final idx = entry.key;
        final optStr = entry.value.toString();
        final letter = String.fromCharCode(65 + idx); // A, B, C, D
        final isSelected = studentAns == optStr;

        // Clean option from existing "A)", "A.", etc.
        String cleanedOpt = optStr.trim();
        final labelRegex = RegExp(r'^[A-D][\.\)\-\s]+', caseSensitive: false);
        cleanedOpt = cleanedOpt.replaceFirst(labelRegex, '').trim();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: widget.isReadOnly
                ? null
                : () => setState(() => _answers[qIndex] = optStr),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4285F4)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4285F4)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cleanedOpt,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected
                            ? const Color(0xFF1B1B4B)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4285F4),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletionSection() {
    final showCompletedHeader = _allQuestionsAnswered() && !widget.isReadOnly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

  Widget _buildTrueFalse(int qIndex) {
    final studentAns = _answers[qIndex];
    String? choice;
    if (studentAns is Map) {
      choice = studentAns['choice'];
    } else if (studentAns is String) {
      choice = studentAns;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildChoiceChip(qIndex, 'TRUE'),
            const SizedBox(width: 12),
            _buildChoiceChip(qIndex, 'FALSE'),
          ],
        ),
        if (choice == 'FALSE') ...[
          const SizedBox(height: 16),
          const Text(
            'Correction:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tfControllers.putIfAbsent(
              qIndex,
              () => TextEditingController(
                text: (studentAns is Map) ? studentAns['correction'] : '',
              ),
            ),
            onChanged: widget.isReadOnly
                ? null
                : (val) {
                    setState(() {
                      _answers[qIndex] = {'choice': 'FALSE', 'correction': val};
                    });
                  },
            enabled: !widget.isReadOnly,
            decoration: InputDecoration(
              hintText: 'Provide the correct statement...',
              filled: true,
              fillColor: Colors.blue.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChoiceChip(int qIndex, String label) {
    final studentAns = _answers[qIndex];
    Map<String, dynamic>? q;
    if (qIndex >= 0 && qIndex < _questions.length) {
      q = _questions[qIndex] as Map<String, dynamic>?;
    }
    final correctAns = q?['answer'];
    final isTeacherViewing = widget.studentId != null;
    final manualGrade = _manualGrades[qIndex];
    final isSelected = studentAns == label;
    final isCorrectChoice = label == correctAns;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;

    if (isSelected) {
      bgColor = const Color(0xFFF0F7FF);
      borderColor = const Color(0xFF4285F4);
      textColor = const Color(0xFF1B1B4B);
    }

    if (isTeacherViewing) {
      if (isCorrectChoice) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade900;
      } else if (isSelected && manualGrade == false) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade900;
      } else if (isSelected && manualGrade == true) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade900;
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: widget.isReadOnly
            ? null
            : () {
                setState(() {
                  if (label == 'FALSE') {
                    final existing = _answers[qIndex];
                    _answers[qIndex] = {
                      'choice': 'FALSE',
                      'correction': (existing is Map)
                          ? (existing['correction'] ?? '')
                          : '',
                    };
                  } else {
                    _answers[qIndex] = 'TRUE';
                  }
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected || (isTeacherViewing && isCorrectChoice)
                    ? FontWeight.bold
                    : FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentification(int qIndex) {
    Map<String, dynamic>? q;
    if (qIndex >= 0 && qIndex < _questions.length) {
      q = _questions[qIndex] as Map<String, dynamic>?;
    }

    if (!_controllers.containsKey(qIndex)) {
      _controllers[qIndex] = TextEditingController(
        text: _answers[qIndex]?.toString() ?? '',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controllers[qIndex],
          onChanged: widget.isReadOnly
              ? null
              : (val) => setState(() => _answers[qIndex] = val),
          enabled: !widget.isReadOnly,
          maxLines: null, // Allow multiline
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: (q?['type'] == 'ENUMERATION')
                ? 'List your answers here...'
                : 'Type your answer...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        Container(
          height: 2,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue,
                Colors.blue.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _turnInAnswers() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      final stringAnswers = _answers.map(
        (key, value) => MapEntry(key.toString(), value),
      );

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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
