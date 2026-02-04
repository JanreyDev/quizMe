import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Question {
  final String type;
  final String question;
  final List<String>? options;
  final String answer;
  final String? correction;

  Question({
    required this.type,
    required this.question,
    this.options,
    required this.answer,
    this.correction,
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

  int _currentPage = 0;
  static const int _itemsPerPage = 5;
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
      debugPrint('PDF Upload Error: $e');
      return null;
    }
  }

  Future<void> _saveExam() async {
    if (_questions.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      String? pdfUrl;
      if (_pickedFile != null) {
        pdfUrl = await _uploadPdf(_pickedFile!);
      }

      final materialData = {
        'classCode': widget.classCode,
        'title': widget.title,
        'teacherName': widget.teacherName,
        'dueDate': widget.dueDate,
        'isPublished': true,
        'pdfUrl': pdfUrl,
        'extractedText': widget.extractedText,
        'questions': _questions
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
        materialData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .add(materialData);
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving ${widget.materialTitle.toLowerCase()}: $e',
            ),
          ),
        );
      }
    }
  }

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
  final TextEditingController _correctionController = TextEditingController();
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
      correction: (_currentlyAddingType == 'TRUE OR FALSE' && !_isTrue)
          ? _correctionController.text
          : null,
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
    _correctionController.clear();
    _isTrue = true;
  }

  @override
  Widget build(BuildContext context) {
    final int totalPages = (_questions.length / _itemsPerPage).ceil();
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage < _questions.length)
        ? startIndex + _itemsPerPage
        : _questions.length;
    final List<Question> visibleQuestions = _questions.sublist(
      startIndex,
      endIndex,
    );

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

                ...List.generate(visibleQuestions.length, (index) {
                  final absoluteIndex = startIndex + index;
                  final q = visibleQuestions[index];
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
                          onTap: () => _editQuestion(absoluteIndex),
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
                                        '#${absoluteIndex + 1} • ${q.type}',
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: q.options!.asMap().entries.map((
                                      entry,
                                    ) {
                                      final idx = entry.key;
                                      final opt = entry.value;
                                      final isCorrect = opt == q.answer;
                                      final letter = String.fromCharCode(
                                        65 + idx,
                                      );

                                      // Clean option from existing "A)", "A.", etc.
                                      String cleanedOpt = opt.trim();
                                      final labelRegex = RegExp(
                                        r'^[A-D][\.\)\-\s]+',
                                        caseSensitive: false,
                                      );
                                      cleanedOpt = cleanedOpt
                                          .replaceFirst(labelRegex, '')
                                          .trim();

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCorrect
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isCorrect
                                                  ? Colors.green.withOpacity(
                                                      0.3,
                                                    )
                                                  : Colors.grey.withOpacity(
                                                      0.2,
                                                    ),
                                            ),
                                          ),
                                          child: Text(
                                            '$letter. $cleanedOpt',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isCorrect
                                                  ? Colors.green.shade700
                                                  : Colors.black87,
                                              fontWeight: isCorrect
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
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
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // Align with multiline items
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: () {
                                          if (q.type == 'MULTIPLE CHOICE') {
                                            final idx =
                                                q.options?.indexOf(q.answer) ??
                                                -1;
                                            final letter = idx != -1
                                                ? String.fromCharCode(65 + idx)
                                                : '';

                                            String cleanedAns = q.answer.trim();
                                            final labelRegex = RegExp(
                                              r'^[A-D][\.\)\-\s]+',
                                              caseSensitive: false,
                                            );
                                            cleanedAns = cleanedAns
                                                .replaceFirst(labelRegex, '')
                                                .trim();

                                            return Text(
                                              letter.isNotEmpty
                                                  ? '$letter. $cleanedAns'
                                                  : cleanedAns,
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            );
                                          }
                                          if (q.type == 'ENUMERATION') {
                                            // Handle various formats: [a, b], a, b, a; b etc.
                                            String clean = q.answer.trim();
                                            if (clean.startsWith('[') &&
                                                clean.endsWith(']')) {
                                              clean = clean.substring(
                                                1,
                                                clean.length - 1,
                                              );
                                            }
                                            // Split by comma OR semicolon
                                            final items = clean
                                                .split(RegExp(r'[,;]'))
                                                .map((e) => e.trim())
                                                .where((e) => e.isNotEmpty)
                                                .toList();

                                            if (items.length > 1) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: items
                                                    .map(
                                                      (item) => Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 2,
                                                            ),
                                                        child: Text(
                                                          '• $item',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .green
                                                                .shade700,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              );
                                            }
                                          }

                                          return Text(
                                            q.answer,
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          );
                                        }(),
                                      ),
                                    ],
                                  ),
                                ),
                                if (q.type == 'TRUE OR FALSE' &&
                                    q.answer == 'FALSE' &&
                                    q.correction != null &&
                                    q.correction!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Correction: ${q.correction}',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                if (totalPages > 1) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            color: const Color(0xFF42A5F5),
                            padding: EdgeInsets.zero,
                            onPressed: _currentPage > 0
                                ? () {
                                    setState(() => _currentPage--);
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Page ${_currentPage + 1} of $totalPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B1B4B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            color: const Color(0xFF42A5F5),
                            padding: EdgeInsets.zero,
                            onPressed: _currentPage < totalPages - 1
                                ? () {
                                    setState(() => _currentPage++);
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 80), // Space for FAB
                if (_questions.isNotEmpty)
                  Center(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveExam,
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
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save Exam',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isSaving)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
            ),
        ],
      ),
    );
  }

  int? _editingIndex;

  void _editQuestion(int index) {
    _editingIndex = index;
    final q = _questions[index];
    _currentlyAddingType = q.type;
    _questionController.text = q.question;
    _answerController.text = q.answer;
    _correctionController.text = q.correction ?? '';
    _isTrue = q.answer.toUpperCase() == 'TRUE';
    if (q.options != null && q.options!.length == 4) {
      for (int i = 0; i < 4; i++) {
        _optionControllers[i].text = q.options![i];
      }
    }
    _showQuestionModal();
  }

  void _showQuestionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return ListView(
                controller: controller,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingIndex != null
                            ? 'Edit Question'
                            : 'New Question',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Question Type Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentlyAddingType!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
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
                            labelText:
                                'Option ${String.fromCharCode(65 + index)}',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '${String.fromCharCode(65 + index)}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => _isTrue = true);
                              setState(
                                () => _isTrue = true,
                              ); // sync with parent
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _isTrue
                                    ? const Color(0xFF4FC3F7).withOpacity(0.2)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isTrue
                                      ? const Color(0xFF4FC3F7)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'TRUE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isTrue
                                        ? Colors.blue.shade900
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => _isTrue = false);
                              setState(
                                () => _isTrue = false,
                              ); // sync with parent
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_isTrue
                                    ? const Color(0xFF4FC3F7).withOpacity(0.2)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isTrue
                                      ? const Color(0xFF4FC3F7)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'FALSE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !_isTrue
                                        ? Colors.blue.shade900
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_isTrue) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _correctionController,
                        decoration: InputDecoration(
                          labelText: 'Correct Answer / Statement',
                          hintText: 'Provide the right statement',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
                      onPressed: () {
                        _addQuestion();
                        Navigator.pop(context);
                      },
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
                        _editingIndex != null
                            ? 'Update Question'
                            : 'Add Question',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
