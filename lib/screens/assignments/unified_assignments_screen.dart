import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'choose_assignment_type_screen.dart';
import 'submissions_view_screen.dart';
import 'create_material_details_screen.dart';
import '../../services/notification_service.dart';

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
  final Set<String> _selectedItems = {}; // Format: "collectionName/docId"
  bool _isPublishing = false;
  final List<Map<String, String>> _categories = [
    {'name': 'exams', 'title': 'Exams'},
    {'name': 'quizzes', 'title': 'Quizzes'},
    {'name': 'activities', 'title': 'Activities'},
    {'name': 'assignments', 'title': 'Assignments'},
  ];
  Map<String, Stream<QuerySnapshot>>? _streams;

  @override
  void initState() {
    super.initState();
    _streams = {
      for (var cat in _categories)
        cat['name']!: FirebaseFirestore.instance
            .collection(cat['name']!)
            .where('classCode', isEqualTo: widget.classCode)
            .snapshots(),
    };
  }

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
    if (_selectedItems.isEmpty) return;
    setState(() => _isPublishing = true);

    final batch = FirebaseFirestore.instance.batch();

    try {
      for (final itemIdentifier in _selectedItems) {
        final parts = itemIdentifier.split('/');
        if (parts.length != 2) continue;

        final coll = parts[0];
        final id = parts[1];

        batch.update(FirebaseFirestore.instance.collection(coll).doc(id), {
          'isPublished': true,
        });
      }

      await batch.commit();

      // Send notifications
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final className = classDoc.data()?['name'] ?? widget.classCode;

      for (var itemIdentifier in _selectedItems) {
        final parts = itemIdentifier.split('/');
        if (parts.length != 2) continue;
        final coll = parts[0];
        final id = parts[1];

        // Fetch item title
        final itemDoc = await FirebaseFirestore.instance
            .collection(coll)
            .doc(id)
            .get();
        final itemTitle = itemDoc.data()?['title'] ?? 'New Item';
        final typeLabel = coll.substring(0, coll.length - 1).toUpperCase();

        await NotificationService.sendToClass(
          classId: widget.classId,
          classCode: widget.classCode,
          className: className,
          title: 'New $typeLabel Available',
          message:
              'A new $coll, "$itemTitle", has been posted for ${widget.classCode}.',
          type: coll,
          docId: id,
        );
      }

      if (mounted) {
        setState(() {
          _selectedItems.clear();
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All items published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error publishing items: $e')));
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
          stream: _streams?[collectionName],
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

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
                final itemKey = '$collectionName/$docId';
                final isSelected = _selectedItems.contains(itemKey);
                final isPublished = data['isPublished'] ?? false;
                final dueDate = data['dueDate'] as Timestamp?;
                final formattedDate = dueDate != null
                    ? DateFormat('MMM dd, hh:mm a').format(dueDate.toDate())
                    : 'N/A';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (isPublished)
                        return; // Prevent selecting already published items
                      setState(() {
                        if (isSelected) {
                          _selectedItems.remove(itemKey);
                        } else {
                          _selectedItems.add(itemKey);
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
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF205072), // Darker blue on the edges
            const Color(0xFF5DADE2), // Lighter blue in the center
            const Color(0xFF205072),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: isSelected
            ? Border.all(color: const Color(0xFF007D6E), width: 3)
            : (isPublished
                  ? Border.all(color: Colors.greenAccent, width: 2)
                  : null),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF007D6E).withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
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
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Due: $dueDate',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isPublished)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
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
                selectedRanges: {
                  for (var t in types) t: '1-${questions.length}',
                },
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
              onPressed: (_selectedItems.isEmpty || _isPublishing)
                  ? null
                  : _publishMaterial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007D6E),
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
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
                  : Text(
                      _selectedItems.isEmpty
                          ? 'Upload'
                          : 'Upload (${_selectedItems.length})',
                      style: const TextStyle(
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChooseAssignmentTypeScreen(classCode: widget.classCode),
      ),
    );
  }
}
