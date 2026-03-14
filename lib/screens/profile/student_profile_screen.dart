import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/saved_accounts_service.dart';
import '../auth/login_screen.dart';
import '../dashboard/todo_screen.dart';
import '../../widgets/student_bottom_navbar.dart';
import 'settings_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(role: 'STUDENT'),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _showChangeUserSheet(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    List<SavedAccount> allAccounts = const <SavedAccount>[];
    try {
      allAccounts = await SavedAccountsService.getSavedAccounts();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load saved accounts right now.'),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;

    final accounts = allAccounts
        .where(
          (a) =>
              a.role.toUpperCase() == 'STUDENT' && a.uid != currentUser?.uid,
        )
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Switch Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (accounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No saved accounts yet. Log in at least once to save an account.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      ...accounts.map((account) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: account.photoUrl != null
                                ? NetworkImage(account.photoUrl!)
                                : null,
                            child: account.photoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.blueGrey,
                                  )
                                : null,
                          ),
                          title: Text(account.name),
                          subtitle: Text(account.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove account',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final shouldRemove =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Remove account'),
                                            content: Text(
                                              'Remove ${account.email} from saved accounts?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          );
                                        },
                                      ) ??
                                      false;

                                  if (!shouldRemove) return;

                                  await SavedAccountsService.removeByUid(
                                    account.uid,
                                  );
                                  accounts.removeWhere(
                                    (a) => a.uid == account.uid,
                                  );
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.of(sheetContext).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  role: 'STUDENT',
                                  prefilledEmail: account.email,
                                ),
                              ),
                              (route) => false,
                            );
                          },
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? user?.displayName ?? 'User';
        final age = userData?['age']?.toString() ?? 'Age not set';
        final course = userData?['course'] ?? 'Course not set';
        final photoUrl = userData?['photoUrl'] as String?;
        final role = userData?['role']?.toString().toUpperCase() ?? 'STUDENT';

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
              'Profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              age == 'Age not set' ? age : '$age years old',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey[300],
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (role == 'STUDENT')
                              Text(
                                course,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueGrey[300],
                                  height: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Menu Items
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.person_add_alt,
                  title: 'Change User',
                  onTap: () => _showChangeUserSheet(context),
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  onTap: () => _handleLogout(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),
          bottomNavigationBar: role == 'STUDENT'
              ? StudentBottomNavBar(
                  currentIndex: 3, // Profile tab
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TodoScreen(),
                        ),
                      );
                    } else if (index == 2) {
                      Navigator.pop(
                        context,
                      ); // Go back if we came from notifications, usually though we'd want a proper nav stack
                      // For now, consistent with other screens:
                      Navigator.pushReplacementNamed(
                        context,
                        '/notifications',
                      ); // This is a placeholder for better routing
                    }
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(width: 16),
            ] else
              const SizedBox(width: 40), // Alignment with icons
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.black : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
