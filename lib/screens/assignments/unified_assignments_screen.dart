import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'choose_questions_type_screen.dart';
import 'submissions_view_screen.dart';
import 'create_material_details_screen.dart';

class UnifiedAssignmentsScreen extends StatefulWidget {
  final String classCode;
  final String classId;

  const UnifiedAssignmentsScreen({
    super.key,
    required this.classCode,
    required this.classId,
  });

  @override
  State<UnifiedAssignmentsScreen> createState() =>
      _UnifiedAssignmentsScreenState();
}

class _UnifiedAssignmentsScreenState extends State<UnifiedAssignmentsScreen> {
  String? _selectedMaterialId;
  String? _selectedCollection;
  bool _isPublishing = false;

  final List<Map<String, String>> _categories = [
    {'name': 'exams', 'title': 'Exams'},
    {'name': 'quizzes', 'title': 'Quizzes'},
    {'name': 'activities', 'title': 'Activities'},
    {'name': 'assignments', 'title': 'Assignments'},
  ];

  Future<void> _deleteMaterial(
    String collectionName,
    String docId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
          'Are you sure you want to delete "$title"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
      }
    }
  }

  Future<void> _publishMaterial() async {
    if (_selectedMaterialId == null || _selectedCollection == null) return;
    setState(() => _isPublishing = true);
    try {
      await FirebaseFirestore.instance
          .collection(_selectedCollection!)
          .doc(_selectedMaterialId)
          .update({'isPublished': true});

      if (mounted) {
        setState(() {
          _selectedMaterialId = null;
          _selectedCollection = null;
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error publishing: $e')));
      }
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _categories
                  .map(
                    (cat) => _buildCategorySection(cat['name']!, cat['title']!),
                  )
                  .toList(),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String collectionName, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collectionName)
              .where('classCode', isEqualTo: widget.classCode)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting)
              return const SizedBox.shrink();

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Text(
                'No ${title.toLowerCase()} found.',
                style: const TextStyle(color: Colors.grey),
              );
            }

            final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
            sortedDocs.sort((a, b) {
              final aTime =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            return Column(
              children: sortedDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final isSelected =
                    _selectedMaterialId == docId &&
                    _selectedCollection == collectionName;
                final isPublished = data['isPublished'] ?? false;
                final dueDate = data['dueDate'] as Timestamp?;
                final formattedDate = dueDate != null
                    ? DateFormat('MMM dd, hh:mm a').format(dueDate.toDate())
                    : 'N/A';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMaterialId = null;
                          _selectedCollection = null;
                        } else {
                          _selectedMaterialId = docId;
                          _selectedCollection = collectionName;
                        }
                      });
                    },
                    child: _buildItemCard(
                      collectionName: collectionName,
                      docId: docId,
                      title: data['title'] ?? 'Untitled',
                      dueDate: formattedDate,
                      isSelected: isSelected,
                      isPublished: isPublished,
                      fullData: data,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required String collectionName,
    required String docId,
    required String title,
    required String dueDate,
    required bool isSelected,
    required bool isPublished,
    required Map<String, dynamic> fullData,
  }) {
    IconData iconData = Icons.assignment;
    if (collectionName == 'quizzes')
      iconData = Icons.quiz;
    else if (collectionName == 'activities')
      iconData = Icons.edit_document;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [const Color(0xFF4FC3F7), const Color(0xFF03A9F4)]
              : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : (isPublished
                  ? Border.all(color: Colors.greenAccent, width: 2)
                  : null),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: Colors.grey[700], size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Due: $dueDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isPublished)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 24,
              ),
            ),
          _buildPopupMenu(collectionName, docId, title, fullData),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(
    String collectionName,
    String docId,
    String title,
    Map<String, dynamic> fullData,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        if (value == 'edit') {
          final questions = fullData['questions'] as List? ?? [];
          final types = questions
              .map((q) => q['type'] as String?)
              .whereType<String>()
              .toSet();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMaterialDetailsScreen(
                classCode: widget.classCode,
                selectedTypes: types,
                itemCount: questions.length.toString(),
                collectionName: collectionName,
                materialTitle: _categories.firstWhere(
                  (c) => c['name'] == collectionName,
                )['title']!,
                existingMaterialId: docId,
                existingData: fullData,
              ),
            ),
          );
        } else if (value == 'delete') {
          _deleteMaterial(collectionName, docId, title);
        } else if (value == 'view') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmissionsViewScreen(
                assignmentId: docId,
                assignmentTitle: title,
                collectionName: collectionName,
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.people, size: 20),
              SizedBox(width: 8),
              Text('View Submissions'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: (_selectedMaterialId == null || _isPublishing)
                  ? null
                  : _publishMaterial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81D4FA),
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _showCreateOptions,
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
                'Create',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to create?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._categories
                .map(
                  (cat) => ListTile(
                    leading: Icon(
                      cat['name'] == 'quizzes'
                          ? Icons.quiz
                          : cat['name'] == 'activities'
                          ? Icons.edit_document
                          : Icons.assignment,
                    ),
                    title: Text(cat['title']!),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChooseQuestionsTypeScreen(
                            classCode: widget.classCode,
                            collectionName: cat['name']!,
                            materialTitle: cat['title']!,
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
