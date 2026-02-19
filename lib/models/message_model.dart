// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToId;
  final bool isEdited;          // ADD THIS
  final DateTime? editedAt;     // ADD THIS
  final String? editedBy;       // ADD THIS

  MessageModel({
    this.id = '',
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.replyToId,
    this.isEdited = false,      // ADD THIS
    this.editedAt,              // ADD THIS
    this.editedBy,              // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'replyToId': replyToId,
      'isEdited': isEdited,     // ADD THIS
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'editedBy': editedBy,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      replyToId: map['replyToId'],
      isEdited: map['isEdited'] ?? false,         // ADD THIS
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : null,                                 // ADD THIS
      editedBy: map['editedBy'],                  // ADD THIS
    );
  }
}