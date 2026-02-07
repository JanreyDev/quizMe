import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class StudentBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StudentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4A4A8C),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          activeIcon: Icon(Icons.list_alt),
          label: 'To do',
        ),
        BottomNavigationBarItem(
          icon: user == null
              ? const Icon(Icons.notifications_outlined)
              : StreamBuilder<int>(
                  stream: NotificationService.getUnreadCountStream(user.uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Badge(
                      label: Text(count.toString()),
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.notifications_outlined),
                    );
                  },
                ),
          activeIcon: user == null
              ? const Icon(Icons.notifications)
              : StreamBuilder<int>(
                  stream: NotificationService.getUnreadCountStream(user.uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Badge(
                      label: Text(count.toString()),
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.notifications),
                    );
                  },
                ),
          label: 'Notification',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
