import 'package:flutter/material.dart';
import 'create_exam_details_screen.dart';

class ChooseExamTypeScreen extends StatefulWidget {
  final String classCode;

  const ChooseExamTypeScreen({super.key, required this.classCode});

  @override
  State<ChooseExamTypeScreen> createState() => _ChooseExamTypeScreenState();
}

class _ChooseExamTypeScreenState extends State<ChooseExamTypeScreen> {
  final Set<String> _selectedTypes = {};
  String _selectedItemCount = '1-10';

  final List<String> _examTypes = [
    'MULTIPLE CHOICE',
    'IDENTIFICATION',
    'ENUMERATION',
    'TRUE OR FALSE',
  ];

  final List<String> _itemCounts = ['1-10', '1-20', '1-50'];

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'CHOOSE A TYPE OF EXAM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                ..._examTypes.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildExamTypeToggle(type),
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 40,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'NO. OF ITEMS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _itemCounts
                      .map((count) => _buildItemCountPill(count))
                      .toList(),
                ),
                const SizedBox(height: 140), // Space for bottom button
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            right: 24,
            child: SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedTypes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select at least one exam type'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateExamDetailsScreen(classCode: widget.classCode),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTypeToggle(String type) {
    bool isSelected = _selectedTypes.contains(type);
    return InkWell(
      onTap: () => _toggleType(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF00796B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, color: Colors.black, size: 36),
            if (isSelected) const SizedBox(width: 16),
            Expanded(
              child: Center(
                child: Text(
                  type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            if (isSelected)
              const SizedBox(
                width: 52,
              ), // Offset for checkmark to keep text centered
          ],
        ),
      ),
    );
  }

  Widget _buildItemCountPill(String count) {
    bool isSelected = _selectedItemCount == count;
    return GestureDetector(
      onTap: () => setState(() => _selectedItemCount = count),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF4FC3F7),
          borderRadius: BorderRadius.circular(25),
          border: isSelected
              ? Border.all(color: Colors.blue.shade900, width: 3)
              : null,
        ),
        child: Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }
}
