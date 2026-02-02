import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../class/student_subject_view_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final TextEditingController _classCodeController = TextEditingController();
  bool _isEnrolling = false;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _enrollInClass() async {
    final classCode = _classCodeController.text.trim().toUpperCase();

    if (classCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class code')),
      );
      return;
    }

    setState(() => _isEnrolling = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Search for class by classCode
      final classQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('classCode', isEqualTo: classCode)
          .limit(1)
          .get();

      if (classQuery.docs.isEmpty) {
        throw Exception('Class not found. Please check the class code.');
      }

      final classDoc = classQuery.docs.first;
      final classId = classDoc.id;

      // Check if already enrolled
      final studentDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(user.uid)
          .get();

      if (studentDoc.exists) {
        throw Exception('You are already enrolled in this class');
      }

      // Enroll student
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(user.uid)
          .set({
            'studentId': user.uid,
            'enrolledAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });

      if (mounted) {
        _classCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully enrolled in class!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _getEnrolledClasses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collectionGroup('students')
        .where('studentId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> classes = [];

          for (var doc in snapshot.docs) {
            // Get class details
            final classId = doc.reference.parent.parent!.id;
            final classDoc = await FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .get();

            if (classDoc.exists) {
              final classData = classDoc.data()!;
              classData['id'] = classId;
              classes.add(classData);
            }
          }

          return classes;
        });
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    // TODO: Navigate to different pages based on index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'QuizMe',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A8C),
                            ),
                          ),
                        ),
                      ),
                      // Logout button
                      IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                        icon: const Icon(Icons.logout),
                        color: const Color(0xFF4A4A8C),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Enrolled Classes
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getEnrolledClasses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final classes = snapshot.data ?? [];

                  if (classes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No enrolled classes yet.\nEnter a class code below to enroll!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classData = classes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentSubjectViewScreen(
                                  classCode: classData['classCode'] ?? '',
                                  className: classData['name'] ?? '',
                                ),
                              ),
                            );
                          },
                          child: _buildClassCard(classData),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Enrollment Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _classCodeController,
                    decoration: InputDecoration(
                      hintText: 'Paste the link',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isEnrolling ? null : _enrollInClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isEnrolling
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ENROLL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A4A8C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'To do'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> data) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF37474F).withOpacity(0.8),
            const Color(0xFF455A64).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Word cloud background (simplified)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Opacity(
                opacity: 0.3,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'Software',
                            'Engineering',
                            'Code',
                            'Development',
                            'Design',
                            'Testing',
                            'Agile',
                          ]
                          .map(
                            (word) => Text(
                              word,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
          // Class info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data['classCode'] ?? 'Unknown'}: ${data['name'] ?? 'Unknown Class'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  data['teacherName'] ?? 'Unknown Teacher',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
