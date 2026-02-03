import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'take_exam_screen.dart';

class StudentUnifiedAssignmentsScreen extends StatelessWidget {
  final String classCode;
  final String className;

  const StudentUnifiedAssignmentsScreen({
    super.key,
    required this.classCode,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          classCode,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('submissions')
                  .where('studentId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, submissionSnapshot) {
                if (submissionSnapshot.hasError)
                  return Center(
                    child: Text(
                      'Submission Error: ${submissionSnapshot.error}',
                    ),
                  );
                if (submissionSnapshot.connectionState ==
                    ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final submittedIds = (submissionSnapshot.data?.docs ?? [])
                    .map((doc) => doc['assignmentId'] as String)
                    .toSet();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        className,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildCategorySection(
                      context,
                      'exams',
                      'Exams',
                      submittedIds,
                    ),
                    _buildCategorySection(
                      context,
                      'quizzes',
                      'Quizzes',
                      submittedIds,
                    ),
                    _buildCategorySection(
                      context,
                      'activities',
                      'Activities',
                      submittedIds,
                    ),
                    _buildCategorySection(
                      context,
                      'assignments',
                      'Assignments',
                      submittedIds,
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String collectionName,
    String title,
    Set<String> submittedIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collectionName)
              .where('classCode', isEqualTo: classCode)
              .where('isPublished', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting)
              return const SizedBox.shrink();

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Text(
                'No ${title.toLowerCase()} published yet.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                final mTitle = data['title'] ?? 'Untitled';
                final isDone = submittedIds.contains(docId);
                final dueDateStr = data['dueDate'] != null
                    ? DateFormat(
                        'MMM dd, hh:mm a',
                      ).format((data['dueDate'] as Timestamp).toDate())
                    : 'N/A';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakeExamScreen(
                            assignmentId: docId,
                            assignmentTitle: mTitle,
                            isReadOnly: isDone,
                            collectionName: collectionName,
                          ),
                        ),
                      );
                    },
                    child: _buildItemCard(
                      collectionName,
                      mTitle,
                      dueDateStr,
                      isDone,
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

  Widget _buildItemCard(
    String collectionName,
    String title,
    String dueDate,
    bool isDone,
  ) {
    IconData iconData = Icons.assignment;
    if (collectionName == 'quizzes')
      iconData = Icons.quiz;
    else if (collectionName == 'activities')
      iconData = Icons.edit_document;

    return Opacity(
      opacity: isDone ? 0.7 : 1.0,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDone
                ? [Colors.grey[300]!, Colors.grey[400]!]
                : [Colors.grey[400]!, Colors.grey[600]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
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
                    isDone ? 'COMPLETED' : 'Due: $dueDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone ? Colors.green[700] : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
