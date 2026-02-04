import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'choose_questions_type_screen.dart';
import 'submissions_view_screen.dart';
import 'create_material_details_screen.dart';

class MaterialsListScreen extends StatefulWidget {
  final String classCode;
  final String classId;
  final String collectionName;
  final String title;

  const MaterialsListScreen({
    super.key,
    required this.classCode,
    required this.classId,
    required this.collectionName,
    required this.title,
  });

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  String? _selectedMaterialId;
  bool _isPublishing = false;

  Future<void> _deleteMaterial(String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.title}?'),
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
            .collection(widget.collectionName)
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${widget.title} deleted')));
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
    if (_selectedMaterialId == null) return;

    setState(() => _isPublishing = true);

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(_selectedMaterialId)
          .update({'isPublished': true});

      if (mounted) {
        setState(() {
          _selectedMaterialId = null;
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.title} published successfully!')),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Cards List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collectionName)
                  .where('classCode', isEqualTo: widget.classCode)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No ${widget.title.toLowerCase()} found.'),
                  );
                }

                final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                sortedDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: sortedDocs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = sortedDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final title = data['title'] ?? 'Untitled';
                    final dueDate = data['dueDate'] as Timestamp?;
                    final isPublished = data['isPublished'] ?? false;

                    String formattedDate = 'N/A';
                    if (dueDate != null) {
                      formattedDate = DateFormat(
                        'MMM dd, hh:mm a',
                      ).format(dueDate.toDate());
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMaterialId = (_selectedMaterialId == docId)
                              ? null
                              : docId;
                        });
                      },
                      child: _buildMaterialCard(
                        docId: docId,
                        subtitle: title,
                        dueDate: formattedDate,
                        isSelected: _selectedMaterialId == docId,
                        isPublished: isPublished,
                        fullData: data,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Bottom Buttons
          Padding(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChooseQuestionsTypeScreen(
                            classCode: widget.classCode,
                            collectionName: widget.collectionName,
                            materialTitle: widget.title,
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
                      'Create',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard({
    required String docId,
    required String subtitle,
    required String dueDate,
    required bool isSelected,
    required bool isPublished,
    required Map<String, dynamic> fullData,
  }) {
    IconData iconData = Icons.assignment;
    if (widget.collectionName == 'quizzes') {
      iconData = Icons.quiz;
    } else if (widget.collectionName == 'activities') {
      iconData = Icons.edit_document;
    }

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
          if (isSelected)
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
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
                  subtitle,
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
          PopupMenuButton<String>(
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
                      selectedRanges: {
                        for (var t in types) t: '1-${questions.length}',
                      },
                      collectionName: widget.collectionName,
                      materialTitle: widget.title,
                      existingMaterialId: docId,
                      existingData: fullData,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                _deleteMaterial(docId, subtitle);
              } else if (value == 'view') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmissionsViewScreen(
                      assignmentId: docId,
                      assignmentTitle: subtitle,
                      collectionName: widget.collectionName,
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
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
