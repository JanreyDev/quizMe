import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a notification to all students enrolled in a specific class.
  static Future<void> sendToClass({
    required String classId,
    required String classCode,
    required String className,
    required String title,
    required String message,
    required String type, // 'assignment', 'module', 'quiz', 'activity'
    String? docId,
  }) async {
    try {
      // Get all students enrolled in the class
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      final batch = _firestore.batch();

      for (var studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'studentId': studentId,
          'title': title,
          'message': message,
          'type': type,
          'classId': classId,
          'classCode': classCode,
          'className': className,
          'docId': docId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  /// Fetches notifications for a specific student, sorted by newest first.
  static Stream<QuerySnapshot> getNotifications(String studentId) {
    return _firestore
        .collection('notifications')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  /// Returns a stream of unread notification count for a student.
  static Stream<int> getUnreadCountStream(String studentId) {
    return _firestore
        .collection('notifications')
        .where('studentId', isEqualTo: studentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marks a specific notification as read.
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Marks all notifications for a student as read.
  static Future<void> markAllAsRead(String studentId) async {
    try {
      final unreadSnapshot = await _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}
