import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/todo_screen.dart';
import 'take_exam_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/student_profile_screen.dart';
import '../../widgets/student_bottom_navbar.dart';

class StudentUnifiedAssignmentsScreen extends StatefulWidget {
  final String classCode;
  final String className;
  final String classId;

  const StudentUnifiedAssignmentsScreen({
    super.key,
    required this.classCode,
    required this.className,
    required this.classId,
  });

  @override
  State<StudentUnifiedAssignmentsScreen> createState() =>
      _StudentUnifiedAssignmentsScreenState();
}

class _StudentUnifiedAssignmentsScreenState
    extends State<StudentUnifiedAssignmentsScreen> {
  late final Stream<QuerySnapshot> _submissionsStream;
  late final Map<String, Stream<QuerySnapshot>> _materialStreams;

  void _startAssignment({
    required String collectionName,
    required String docId,
    required String title,
    required bool isDone,
  }) {
    if (isDone) {
      _navigateToExam(collectionName, docId, title, isDone);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Ready to start?'),
          ],
        ),
        content: Text(
          'You are about to start your ${collectionName.substring(0, collectionName.length - 1).toUpperCase()}.\n\n'
          'IMPORTANT:\n'
          '• Once you begin, you cannot exit until you submit your answers.\n'
          '• Your progress will not be saved if you leave early.\n'
          '• Make sure you have a stable internet connection.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NOT YET',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToExam(collectionName, docId, title, isDone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('START NOW'),
          ),
        ],
      ),
    );
  }

  void _navigateToExam(
    String collectionName,
    String docId,
    String title,
    bool isDone,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeExamScreen(
          assignmentId: docId,
          assignmentTitle: title,
          isReadOnly: isDone,
          collectionName: collectionName,
          classId: widget.classId,
        ),
      ),
    );
  }

  final List<Map<String, String>> _categories = [
    {'name': 'exams', 'title': 'Exams'},
    {'name': 'quizzes', 'title': 'Quizzes'},
    {'name': 'activities', 'title': 'Activities'},
    {'name': 'assignments', 'title': 'Assignments'},
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    _submissionsStream = FirebaseFirestore.instance
        .collection('submissions')
        .where('studentId', isEqualTo: user?.uid ?? '')
        .snapshots();

    _materialStreams = {
      for (var cat in _categories)
        cat['name']!: FirebaseFirestore.instance
            .collection(cat['name']!)
            .where('classCode', isEqualTo: widget.classCode)
            .where('isPublished', isEqualTo: true)
            .snapshots(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        final bool isEnrolled =
            enrollmentSnapshot.hasData && enrollmentSnapshot.data!.exists;

        if (enrollmentSnapshot.connectionState == ConnectionState.waiting &&
            !enrollmentSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!isEnrolled) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Access Denied',
                style: TextStyle(color: Colors.black),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_person_outlined,
                      size: 80,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Access Revoked',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are no longer enrolled in ${widget.className}. Please contact your teacher if you believe this is an error.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'BACK TO DASHBOARD',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
          body: user == null
              ? const Center(child: Text('Please log in'))
              : StreamBuilder<QuerySnapshot>(
                  stream: _submissionsStream,
                  builder: (context, submissionSnapshot) {
                    if (submissionSnapshot.hasError)
                      return Center(
                        child: Text(
                          'Submission Error: ${submissionSnapshot.error}',
                        ),
                      );

                    final submittedIds = (submissionSnapshot.data?.docs ?? [])
                        .map((doc) => doc['assignmentId'] as String)
                        .toSet();

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            widget.className,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._categories
                            .map(
                              (cat) => _buildCategorySection(
                                context,
                                cat['name']!,
                                cat['title']!,
                                submittedIds,
                              ),
                            )
                            .toList(),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
          bottomNavigationBar: StudentBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 0) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TodoScreen()),
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentProfileScreen(),
                  ),
                );
              }
            },
          ),
        );
      },
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
          stream: _materialStreams[collectionName],
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

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
                final questions = (data['questions'] as List? ?? []);
                // final isExpanded = _expandedIds.contains(docId); // Removed

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildItemCard(
                    collectionName: collectionName,
                    title: mTitle,
                    dueDate: dueDateStr,
                    isDone: isDone,
                    // isExpanded: isExpanded, // Removed
                    questions: questions,
                    docId: docId,
                    extractedText: data['extractedText'] as String?,
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
    required String title,
    required String dueDate,
    required bool isDone,
    required List questions,
    required String docId,
    String? extractedText,
  }) {
    return Opacity(
      opacity: isDone ? 0.7 : 1.0,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDone
                ? [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!]
                : [
                    const Color(0xFF205072),
                    const Color(0xFF5DADE2),
                    const Color(0xFF205072),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.greenAccent, width: 2),
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
                    isDone ? 'COMPLETED' : 'Due: $dueDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone ? Colors.green[800] : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'take') {
                  _startAssignment(
                    collectionName: collectionName,
                    docId: docId,
                    title: title,
                    isDone: isDone,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'take',
                  child: Text(
                    isDone
                        ? 'View Submission'
                        : () {
                            String cat = collectionName.toLowerCase();
                            if (cat == 'quizzes') return 'Take QUIZ';
                            if (cat == 'activities') return 'Take ACTIVITY';
                            return 'Take ${cat.substring(0, cat.length - 1).toUpperCase()}';
                          }(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
