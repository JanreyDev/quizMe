import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'choose_assignment_type_screen.dart';
import 'submissions_view_screen.dart';
import 'create_exam_details_screen.dart';

class AssignmentsListScreen extends StatefulWidget {
  final String classCode;
  final String classId;

  const AssignmentsListScreen({
    super.key,
    required this.classCode,
    required this.classId,
  });

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  String? _selectedAssignmentId;
  bool _isPublishing = false;

  Future<void> _deleteAssignment(String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment?'),
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
            .collection('assignments')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Assignment deleted')));
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

  Future<void> _publishAssignment() async {
    if (_selectedAssignmentId == null) return;

    setState(() => _isPublishing = true);

    try {
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(_selectedAssignmentId)
          .update({'isPublished': true});

      if (mounted) {
        setState(() {
          _selectedAssignmentId = null;
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment published successfully!')),
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
          // Assignments Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'Assignments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Assignment Cards List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
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
                  return const Center(child: Text('No assignments found.'));
                }

                // Sorting client-side to avoid index error
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
                    final type = data['type'] ?? 'Assignment';
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
                          _selectedAssignmentId =
                              (_selectedAssignmentId == docId) ? null : docId;
                        });
                      },
                      child: _buildAssignmentCard(
                        docId: docId,
                        title: type,
                        subtitle: title,
                        dueDate: formattedDate,
                        isSelected: _selectedAssignmentId == docId,
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
                    onPressed: (_selectedAssignmentId == null || _isPublishing)
                        ? null
                        : _publishAssignment,
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
                          builder: (context) => ChooseAssignmentTypeScreen(
                            classCode: widget.classCode,
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

  Widget _buildAssignmentCard({
    required String docId,
    required String title,
    required String subtitle,
    required String dueDate,
    required bool isSelected,
    required bool isPublished,
    required Map<String, dynamic> fullData,
  }) {
    // Determine icon based on type
    IconData iconData = Icons.assignment;
    if (title.toUpperCase().contains('QUIZ')) {
      iconData = Icons.quiz;
    } else if (title.toUpperCase().contains('ACTIVITY')) {
      iconData = Icons.edit_document;
    } else if (title.toUpperCase().contains('EXAM')) {
      iconData = Icons.assignment;
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
            : isPublished
            ? Border.all(color: Colors.greenAccent, width: 2)
            : null,
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
          // Circular White Icon Container
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
          // Text Details
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
                    builder: (context) => CreateExamDetailsScreen(
                      classCode: widget.classCode,
                      selectedTypes: types,
                      itemCount: questions.length.toString(),
                      existingAssignmentId: docId,
                      existingData: fullData,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                _deleteAssignment(docId, subtitle);
              } else if (value == 'view') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmissionsViewScreen(
                      assignmentId: docId,
                      assignmentTitle: subtitle,
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
