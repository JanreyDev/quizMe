import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'take_exam_screen.dart';

class SubmissionsViewScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String collectionName;

  const SubmissionsViewScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.collectionName,
  });

  @override
  State<SubmissionsViewScreen> createState() => _SubmissionsViewScreenState();
}

class _SubmissionsViewScreenState extends State<SubmissionsViewScreen> {
  bool _showScores = false;

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
          widget.assignmentTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('assignmentId', isEqualTo: widget.assignmentId)
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
            return const Center(
              child: Text(
                'No submissions yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final studentId = data['studentId'];
              final email = data['studentEmail'] ?? 'Unknown Student';
              final score = data['score'] ?? 0;
              final total = data['totalQuestions'] ?? 0;
              final submittedAt = data['submittedAt'] as Timestamp?;

              String dateStr = 'N/A';
              if (submittedAt != null) {
                dateStr = DateFormat(
                  'MMM dd, hh:mm a',
                ).format(submittedAt.toDate());
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .get(),
                builder: (context, userSnapshot) {
                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;
                  final name = userData?['name'] ?? email;
                  final photoUrl = userData?['photoUrl'] as String?;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE3F2FD),
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(Icons.person, color: Color(0xFF1976D2))
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userData?['name'] != null)
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        Text('Submitted: $dateStr'),
                        if (_showScores)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Score: $score / $total',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakeExamScreen(
                            assignmentId: widget.assignmentId,
                            assignmentTitle: widget.assignmentTitle,
                            isReadOnly: true,
                            studentId: data['studentId'],
                            collectionName: widget.collectionName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showScores = !_showScores),
            icon: Icon(_showScores ? Icons.visibility_off : Icons.visibility),
            label: Text(_showScores ? 'HIDE SCORES' : 'SHOW SCORES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.blue.shade900,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
