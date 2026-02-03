import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'take_exam_screen.dart';

class SubmissionsViewScreen extends StatelessWidget {
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
          assignmentTitle,
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
            .where('assignmentId', isEqualTo: assignmentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
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
              final email = data['studentEmail'] ?? 'Unknown Student';
              final submittedAt = data['submittedAt'] as Timestamp?;

              String dateStr = 'N/A';
              if (submittedAt != null) {
                dateStr = DateFormat(
                  'MMM dd, hh:mm a',
                ).format(submittedAt.toDate());
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, color: Color(0xFF1976D2)),
                ),
                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Submitted: $dateStr'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakeExamScreen(
                        assignmentId: assignmentId,
                        assignmentTitle: assignmentTitle,
                        isReadOnly: true,
                        studentId: data['studentId'],
                        collectionName: collectionName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
