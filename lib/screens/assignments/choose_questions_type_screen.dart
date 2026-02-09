import 'package:flutter/material.dart';
import 'create_material_details_screen.dart';

class ChooseQuestionsTypeScreen extends StatefulWidget {
  final String classCode;
  final String collectionName;
  final String materialTitle;

  const ChooseQuestionsTypeScreen({
    super.key,
    required this.classCode,
    required this.collectionName,
    required this.materialTitle,
  });

  @override
  State<ChooseQuestionsTypeScreen> createState() =>
      _ChooseQuestionsTypeScreenState();
}

class _ChooseQuestionsTypeScreenState extends State<ChooseQuestionsTypeScreen> {
  // Store selected ranges: { 'MULTIPLE CHOICE': '1-15', 'ENUMERATION': '16-20' }
  final Map<String, String> _selectedRanges = {};

  // Controllers for text fields
  final Map<String, TextEditingController> _controllers = {};

  final List<String> _examTypes = [
    'MULTIPLE CHOICE',
    'IDENTIFICATION',
    'ENUMERATION',
    'TRUE OR FALSE',
  ];

  @override
  void initState() {
    super.initState();
    for (var type in _examTypes) {
      _controllers[type] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedRanges.containsKey(type)) {
        _selectedRanges.remove(type);
        _controllers[type]!.clear();
      } else {
        _selectedRanges[type] = ''; // Will be updated by controller
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.materialTitle.toUpperCase();
    if (displayTitle.endsWith('S')) {
      displayTitle = displayTitle.substring(0, displayTitle.length - 1);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
            Text(
              'CHOOSE TYPES FOR $displayTitle',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Specify the item range for each type (e.g. 1-15)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ..._examTypes.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildTypeInputRow(type),
              ),
            ),
            const SizedBox(height: 48), // Space before button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Validate selections
                  if (_selectedRanges.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select at least one type')),
                    );
                    return;
                  }

                  // Check if all selected types have ranges
                  bool allValid = true;
                  _selectedRanges.forEach((type, _) {
                    final range = _controllers[type]!.text.trim();
                    if (range.isEmpty ||
                        !RegExp(r'^\d+-\d+$').hasMatch(range)) {
                      allValid = false;
                    } else {
                      _selectedRanges[type] = range;
                    }
                  });

                  if (!allValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid ranges (e.g. 1-15)'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateMaterialDetailsScreen(
                        classCode: widget.classCode,
                        selectedRanges:
                            _selectedRanges, // Pass Map instead of Set
                        collectionName: widget.collectionName,
                        materialTitle: widget.materialTitle,
                      ),
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
                  'PROCEED',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildTypeInputRow(String type) {
    bool isSelected = _selectedRanges.containsKey(type);
    return Column(
      children: [
        InkWell(
          onTap: () => _toggleType(type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF00796B)],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade200, Colors.grey.shade300],
                    ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.black : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
            child: Row(
              children: [
                const Text(
                  'Set Item Range:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _controllers[type],
                    decoration: InputDecoration(
                      hintText: 'e.g. 1-15',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
