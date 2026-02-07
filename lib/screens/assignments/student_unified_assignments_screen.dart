import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'take_exam_screen.dart';

class StudentUnifiedAssignmentsScreen extends StatefulWidget {
  final String classCode;
  final String className;

  const StudentUnifiedAssignmentsScreen({
    super.key,
    required this.classCode,
    required this.className,
  });

  @override
  State<StudentUnifiedAssignmentsScreen> createState() =>
      _StudentUnifiedAssignmentsScreenState();
}

class _StudentUnifiedAssignmentsScreenState
    extends State<StudentUnifiedAssignmentsScreen> {
  late final Stream<QuerySnapshot> _submissionsStream;
  late final Map<String, Stream<QuerySnapshot>> _materialStreams;
  final Set<String> _expandedIds = {};

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
                final isExpanded = _expandedIds.contains(docId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedIds.remove(docId);
                            } else {
                              _expandedIds.add(docId);
                            }
                          });
                        },
                        child: _buildItemCard(
                          collectionName,
                          mTitle,
                          dueDateStr,
                          isDone,
                          isExpanded,
                          questions,
                          docId,
                          data['extractedText'] as String?,
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Preview:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (data['extractedText'] != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  constraints: const BoxConstraints(
                                    maxHeight: 300,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.description_outlined,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'EXTRACTED CONTENT / REFERENCE:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.blue,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            data['extractedText'] as String,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.5,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ...() {
                                // Group questions by type for section headers
                                final groupedQuestions =
                                    <String, List<Map<String, dynamic>>>{};
                                int questionNumber = 1;

                                for (var q in questions) {
                                  final qData = q as Map<String, dynamic>;
                                  final type = qData['type'] as String;

                                  if (!groupedQuestions.containsKey(type)) {
                                    groupedQuestions[type] = [];
                                  }

                                  // Add question number to data
                                  final qWithNumber = Map<String, dynamic>.from(
                                    qData,
                                  );
                                  qWithNumber['_questionNumber'] =
                                      questionNumber++;
                                  groupedQuestions[type]!.add(qWithNumber);
                                }

                                // Build widgets for each section
                                final List<Widget> sections = [];
                                int sectionNum = 1;

                                groupedQuestions.forEach((
                                  type,
                                  questionsInSection,
                                ) {
                                  // Section header
                                  final String sectionTitle =
                                      type == 'IDENTIFICATION'
                                      ? 'Section $sectionNum: Identification (Write the answer)'
                                      : type == 'ENUMERATION'
                                      ? 'Section $sectionNum: Enumeration'
                                      : type == 'MULTIPLE CHOICE'
                                      ? 'Section $sectionNum: Multiple Choice'
                                      : type == 'TRUE OR FALSE'
                                      ? 'Section $sectionNum: True or False'
                                      : 'Section $sectionNum: $type';

                                  sections.add(
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 20,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        sectionTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ),
                                  );

                                  // Questions in this section
                                  for (var qData in questionsInSection) {
                                    final questionText =
                                        qData['question'] ?? '';
                                    final options =
                                        qData['options'] as List? ?? [];
                                    final qNum =
                                        qData['_questionNumber'] as int;

                                    sections.add(
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Question formal text
                                            Text(
                                              '$qNum. $questionText',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B1B4B),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            // Options/Answer space
                                            if (type == 'MULTIPLE CHOICE')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: options.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    final idx = entry.key;
                                                    final opt = entry.value
                                                        .toString();
                                                    final letter =
                                                        String.fromCharCode(
                                                          97 + idx,
                                                        );
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            '$letter)',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .blue,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              opt,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            if (type == 'IDENTIFICATION' ||
                                                type == 'ENUMERATION')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 16,
                                                  top: 4,
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 150,
                                                    height: 2,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.blue.shade200,
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (type == 'TRUE OR FALSE')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 16,
                                                  top: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    _buildPreviewPill('True'),
                                                    const SizedBox(width: 8),
                                                    _buildPreviewPill('False'),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  sectionNum++;
                                });

                                return sections;
                              }(),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDone
                                        ? Colors.blue.shade100
                                        : Colors.blue.shade600,
                                    foregroundColor: isDone
                                        ? Colors.blue
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isDone
                                        ? 'View Submission'
                                        : 'Take ${collectionName.substring(0, collectionName.length - 1).toUpperCase()}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
    bool isExpanded,
    List questions,
    String docId,
    String? extractedText,
  ) {
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
          borderRadius: isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(24))
              : BorderRadius.circular(24),
          border: isExpanded
              ? Border.all(color: const Color(0xFF007D6E), width: 3)
              : Border.all(color: Colors.greenAccent, width: 2),
          boxShadow: [
            if (isExpanded)
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
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isDone ? Colors.grey[600] : Colors.white,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
