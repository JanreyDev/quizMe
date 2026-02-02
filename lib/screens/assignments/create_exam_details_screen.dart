import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_questions_screen.dart';

class CreateExamDetailsScreen extends StatefulWidget {
  final String classCode;
  final Set<String> selectedTypes;
  final String itemCount;
  final String? existingAssignmentId;
  final Map<String, dynamic>? existingData;

  const CreateExamDetailsScreen({
    super.key,
    required this.classCode,
    required this.selectedTypes,
    required this.itemCount,
    this.existingAssignmentId,
    this.existingData,
  });

  @override
  State<CreateExamDetailsScreen> createState() =>
      _CreateExamDetailsScreenState();
}

class _CreateExamDetailsScreenState extends State<CreateExamDetailsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

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

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Create a Title and Name of your exam:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _titleController,
              label: 'Title:',
              hint: 'Enter exam title',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Name:',
              hint: 'Enter your name',
            ),
            const SizedBox(height: 32),
            const Text(
              'Add the due date of the exam',
              style: TextStyle(
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
              child: SizedBox(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddQuestionsScreen(
                          classCode: widget.classCode,
                          selectedTypes: widget.selectedTypes,
                          itemCount: widget.itemCount,
                          title: _titleController.text,
                          teacherName: _nameController.text,
                          dueDate: _selectedDate!,
                          existingAssignmentId: widget.existingAssignmentId,
                          existingQuestions:
                              (widget.existingData?['questions'] as List?)
                                  ?.map(
                                    (q) => Question(
                                      type: q['type'] ?? '',
                                      question: q['question'] ?? '',
                                      options: (q['options'] as List?)
                                          ?.cast<String>(),
                                      answer: q['answer'] ?? '',
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    );
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
