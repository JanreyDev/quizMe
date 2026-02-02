import 'package:flutter/material.dart';

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
      body: SingleChildScrollView(
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
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'NO. OF ITEMS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _itemCounts
                  .map((count) => _buildItemCountPill(count))
                  .toList(),
            ),
            const SizedBox(height: 48),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to Step 4.4
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    foregroundColor: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFF00E5FF), const Color(0xFF00B8D4)]
                : [const Color(0xFF00BFA5), const Color(0xFF00796B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 24),
            if (isSelected) const SizedBox(width: 8),
            Text(
              type,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4FC3F7) : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue.shade900 : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }
}
