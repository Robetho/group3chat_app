// lib/core/services/chat_service.dart - COMPLETE FIXED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users except current user
  Stream<List<UserModel>> getUsers() {
    try {
      return _firestore
          .collection('users')
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return [];

        return snapshot.docs
            .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromMap(data, doc.id);
          } catch (e) {
            print('Error parsing user document ${doc.id}: $e');
            return null;
          }
        })
            .where((user) => user != null)
            .cast<UserModel>()
            .toList();
      });
    } catch (e) {
      print('Error creating getUsers stream: $e');
      return Stream.value([]);
    }
  }

  // FIXED: Get messages between two users
  Stream<List<MessageModel>> getMessages(
      String currentUserId, String otherUserId) {
    try {
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        return Stream.value([]);
      }

      return _firestore
          .collection('messages')
          .where('senderId', whereIn: [currentUserId, otherUserId])
          .where('receiverId', whereIn: [currentUserId, otherUserId])
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return [];

        final messages = <MessageModel>[];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final message = MessageModel.fromMap(data, doc.id);
            messages.add(message);
          } catch (e) {
            print('Error parsing message document ${doc.id}: $e');
          }
        }

        return messages;
      });
    } catch (e) {
      print('Error creating getMessages stream: $e');
      return Stream.value([]);
    }
  }

  // Send message with reply functionality
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    UserModel? receiver,
    String? replyToId,
  }) async {
    try {
      if (senderId.isEmpty || receiverId.isEmpty || message.trim().isEmpty) {
        throw Exception('Invalid message data');
      }

      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'replyToId': replyToId,
        'isEdited': false,
        'editedAt': null,
        'editedBy': null,
      };

      final docRef = await _firestore.collection('messages').add(messageData);

      print('✅ Message sent with ID: ${docRef.id}');
      if (replyToId != null) {
        print('   Replying to message: $replyToId');
      }

      await _updateChatMetadata(senderId, receiverId, message.trim());
      await _updateChatMetadata(receiverId, senderId, message.trim());

    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String currentUserId, String otherUserId) async {
    try {
      if (currentUserId.isEmpty || otherUserId.isEmpty) return;

      final messagesQuery = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in messagesQuery.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
        print('✅ Marked ${messagesQuery.docs.length} messages as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a chat
  Stream<int> getUnreadCount(String currentUserId, String otherUserId) {
    try {
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        return Stream.value(0);
      }

      return _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error creating getUnreadCount stream: $e');
      return Stream.value(0);
    }
  }

  // Get all chats for a user
  Stream<List<Map<String, dynamic>>> getChats(String userId) {
    try {
      if (userId.isEmpty) {
        return Stream.value([]);
      }

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        if (snapshot.docs.isEmpty) return [];

        final List<Map<String, dynamic>> chats = [];

        for (final doc in snapshot.docs) {
          try {
            final chatData = doc.data();
            final otherUserId = chatData['otherUserId'] as String?;

            if (otherUserId == null || otherUserId.isEmpty) continue;

            final userDoc = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final otherUser = UserModel.fromMap(userData, userDoc.id);

              final unreadCount =
              await _getUnreadCountForChat(userId, otherUserId);

              chats.add({
                'id': doc.id,
                'otherUser': otherUser,
                'lastMessage': chatData['lastMessage']?.toString() ?? '',
                'lastMessageTime': chatData['lastMessageTime'] != null
                    ? (chatData['lastMessageTime'] as Timestamp).toDate()
                    : DateTime.now(),
                'unreadCount': unreadCount,
              });
            }
          } catch (e) {
            print('Error processing chat document ${doc.id}: $e');
            continue;
          }
        }

        return chats;
      });
    } catch (e) {
      print('Error creating getChats stream: $e');
      return Stream.value([]);
    }
  }

  // Delete message
  Future<void> deleteMessage({
    required String messageId,
    required String currentUserId,
    required String otherUserId,
    required bool deleteForEveryone,
  }) async {
    try {
      if (messageId.isEmpty) {
        throw Exception('Invalid message ID');
      }

      final messageDoc =
      await _firestore.collection('messages').doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final senderId = messageData['senderId'] as String;

      if (deleteForEveryone) {
        if (currentUserId != senderId) {
          throw Exception('Only sender can delete message for everyone');
        }

        await _firestore.collection('messages').doc(messageId).delete();

        await _updateChatMetadata(senderId, otherUserId, 'Message deleted');
        await _updateChatMetadata(otherUserId, senderId, 'Message deleted');

        print('🗑️ Message deleted for everyone: $messageId');
      } else {
        await _firestore
            .collection('messages')
            .doc(messageId)
            .collection('deletedFor')
            .doc(currentUserId)
            .set({
          'deletedAt': FieldValue.serverTimestamp(),
          'userId': currentUserId,
        });

        print('🗑️ Message deleted for user $currentUserId: $messageId');
      }
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Get deleted status for a message
  Future<bool> isMessageDeletedForUser(String messageId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .doc(messageId)
          .collection('deletedFor')
          .doc(userId)
          .get();

      return snapshot.exists;
    } catch (e) {
      print('Error checking if message is deleted: $e');
      return false;
    }
  }

  // Get a specific message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final doc = await _firestore.collection('messages').doc(messageId).get();

      if (doc.exists && doc.data() != null) {
        return MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting message by ID: $e');
      return null;
    }
  }

  // Get messages that are replies to a specific message
  Stream<List<MessageModel>> getRepliesToMessage(String messageId) {
    try {
      if (messageId.isEmpty) {
        return Stream.value([]);
      }

      return _firestore
          .collection('messages')
          .where('replyToId', isEqualTo: messageId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return [];

        final messages = <MessageModel>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final message = MessageModel.fromMap(data, doc.id);
            messages.add(message);
          } catch (e) {
            print('Error parsing reply document ${doc.id}: $e');
          }
        }
        return messages;
      });
    } catch (e) {
      print('Error getting replies: $e');
      return Stream.value([]);
    }
  }

  // Edit message
  Future<void> editMessage({
    required String messageId,
    required String newMessage,
    required String editorId,
  }) async {
    try {
      if (messageId.isEmpty || newMessage.trim().isEmpty) {
        throw Exception('Invalid data');
      }

      final messageDoc =
      await _firestore.collection('messages').doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final senderId = messageData['senderId'] as String;

      if (editorId != senderId) {
        throw Exception('Only sender can edit message');
      }

      await _firestore.collection('messages').doc(messageId).update({
        'message': newMessage.trim(),
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': editorId,
        'isEdited': true,
      });

      print('✏️ Message edited: $messageId');
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  // Search messages in a chat
  Stream<List<MessageModel>> searchMessagesInChat(
      String currentUserId,
      String otherUserId,
      String searchText,
      ) {
    try {
      if (searchText.isEmpty) {
        return Stream.value([]);
      }

      return _firestore
          .collection('messages')
          .where('senderId', whereIn: [currentUserId, otherUserId])
          .where('receiverId', whereIn: [currentUserId, otherUserId])
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return [];

        final messages = <MessageModel>[];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final message = MessageModel.fromMap(data, doc.id);
            final messageText = message.message.toLowerCase();
            final searchLower = searchText.toLowerCase();

            if (messageText.contains(searchLower)) {
              messages.add(message);
            }
          } catch (e) {
            print('Error parsing message document ${doc.id}: $e');
          }
        }

        return messages;
      });
    } catch (e) {
      print('Error searching messages: $e');
      return Stream.value([]);
    }
  }

  // Helper method to get unread count for a chat
  Future<int> _getUnreadCountForChat(String userId, String otherUserId) async {
    try {
      if (userId.isEmpty || otherUserId.isEmpty) return 0;

      final snapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Update chat metadata
  Future<void> _updateChatMetadata(
      String userId,
      String otherUserId,
      String lastMessage,
      ) async {
    try {
      if (userId.isEmpty || otherUserId.isEmpty || lastMessage.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(otherUserId)
          .set({
        'otherUserId': otherUserId,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating chat metadata: $e');
    }
  }
}
