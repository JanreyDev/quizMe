import 'package:flutter/material.dart';

class PeopleListScreen extends StatelessWidget {
  final String classCode;
  final String classId;

  const PeopleListScreen({
    super.key,
    required this.classCode,
    required this.classId,
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
          classCode,
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
          // People Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'People',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // People List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildPersonItem(
                  name: 'Julia Lyde Q. Dulog',
                  role: 'Student',
                  context: context,
                ),
                _buildPersonItem(
                  name: 'Jeanne Mhikaela S. Linan',
                  role: 'Student',
                  context: context,
                ),
                _buildPersonItem(
                  name: 'Mark Anthony F. Araracap',
                  role: 'Student',
                  context: context,
                ),
                _buildPersonItem(
                  name: 'Iratus Glenn Cruz',
                  role: 'Teacher',
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonItem({
    required String name,
    required String role,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[400],
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Three-dot menu
          PopupMenuButton<String>(
            icon: Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(left: 3),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            onSelected: (String result) {
              // TODO: Handle menu actions
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$result for $name')));
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'View Profile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'Remove',
                child: Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
