import 'package:flutter/material.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/notification_service.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();

  List<UserModel> _users = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<UserModel> get users => _users;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Initialize provider na kuweka users
  Future<void> initializeUsers() async {
    try {
      setLoading(true);
      // You can load initial users here if needed
      setLoading(false);
    } catch (e) {
      setLoading(false);
      print('Error initializing users: $e');
    }
  }

  // List ya watu waliotafutwa
  List<UserModel> get searchedUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users
        .where((user) =>
    user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // List ya chats zilizotafutwa
  List<Map<String, dynamic>> searchedChats(
      List<Map<String, dynamic>> chats,
      String currentUserId,
      ) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      final otherUser = chat['otherUser'] as UserModel;
      return otherUser.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()) ||
          otherUser.email
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Initialize notifications
  Future<void> initializeNotifications(String userId) async {
    try {
      final token = await _notificationService.getFCMToken();
      if (token != null) {
        await _notificationService.updateUserFCMToken(userId, token);
        print('✅ Notifications initialized for user: $userId');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Stream ya users wote
  Stream<List<UserModel>> streamUsers() {
    return _chatService.getUsers();
  }

  // Stream ya messages kati ya watu wawili
  Stream<List<MessageModel>> streamMessages(
      String currentUserId,
      String otherUserId,
      ) {
    return _chatService.getMessages(currentUserId, otherUserId);
  }

  // Stream ya chats za user
  Stream<List<Map<String, dynamic>>> streamChats(String userId) {
    return _chatService.getChats(userId);
  }

  // Send message with reply functionality - COMPLETE IMPLEMENTATION
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    required UserModel receiver,
    String? replyToId,
  }) async {
    if (message.trim().isEmpty) {
      return; // prevent empty bubbles
    }
    try {
      setLoading(true);

      // First save message to Firestore
      await _chatService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        receiver: receiver,
        replyToId: replyToId,
      );

      // 🔥 SEND NOTIFICATION USING SIMPLE METHOD
      try {
        // Use the simple method that doesn't require UserModel
        await _notificationService.sendChatNotificationSimple(
          senderId: senderId,
          receiverId: receiverId,
          message: message,
        );

        print('📱 Notification sent to ${receiver.name}');
      } catch (e) {
        print('Error sending notification: $e');
        // Don't throw error here, just log it
      }

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      print('Error in chat provider sendMessage: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String currentUserId,
      String otherUserId,
      ) async {
    try {
      await _chatService.markMessagesAsRead(currentUserId, otherUserId);
      notifyListeners();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread count for a specific chat
  Stream<int> getUnreadCount(String currentUserId, String otherUserId) {
    return _chatService.getUnreadCount(currentUserId, otherUserId);
  }

  // EDIT MESSAGE - COMPLETE IMPLEMENTATION
  Future<void> editMessage({
    required String messageId,
    required String newMessage,
    required String editorId,
  }) async {
    try {
      setLoading(true);

      await _chatService.editMessage(
        messageId: messageId,
        newMessage: newMessage,
        editorId: editorId,
      );

      print('✅ Message edited successfully: $messageId');

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      print('Error editing message in provider: $e');
      rethrow;
    }
  }

  // DELETE MESSAGE - COMPLETE IMPLEMENTATION
  Future<void> deleteMessage({
    required String messageId,
    required String currentUserId,
    required String otherUserId,
    required bool deleteForEveryone,
  }) async {
    try {
      setLoading(true);

      await _chatService.deleteMessage(
        messageId: messageId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        deleteForEveryone: deleteForEveryone,
      );

      print('✅ Message deleted successfully: $messageId');

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      print('Error deleting message in provider: $e');
      rethrow;
    }
  }

  // Get specific message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      return await _chatService.getMessageById(messageId);
    } catch (e) {
      print('Error getting message by ID in provider: $e');
      return null;
    }
  }

  // Search messages in chat
  Stream<List<MessageModel>> searchMessagesInChat(
      String currentUserId,
      String otherUserId,
      String searchText,
      ) {
    return _chatService.searchMessagesInChat(
      currentUserId,
      otherUserId,
      searchText,
    );
  }

  // Set users (for updating user list)
  void setUsers(List<UserModel> users) {
    _users = users;
    notifyListeners();
  }

  // Set messages (for updating message list)
  void setMessages(List<MessageModel> messages) {
    _messages = messages;
    notifyListeners();
  }

  // Add single user
  void addUser(UserModel user) {
    _users.add(user);
    notifyListeners();
  }

  // Add single message
  void addMessage(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  // Update specific message
  void updateMessage(String messageId, MessageModel updatedMessage) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  // Remove message locally (for delete operations)
  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search query
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear all data (for logout)
  void clearAllData() {
    _users.clear();
    _messages.clear();
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }

  // Get user by ID
  UserModel? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.uid == userId);
    } catch (e) {
      return null;
    }
  }

  // Get message by reply ID (for reply functionality)
  MessageModel? getMessageByReplyId(String replyToId, List<MessageModel> allMessages) {
    try {
      return allMessages.firstWhere((msg) => msg.id == replyToId);
    } catch (e) {
      return null;
    }
  }

  // Get replies to a message
  Stream<List<MessageModel>> getRepliesToMessage(String messageId) {
    return _chatService.getRepliesToMessage(messageId);
  }

  // Check if message is deleted for user
  Future<bool> isMessageDeletedForUser(String messageId, String userId) async {
    try {
      return await _chatService.isMessageDeletedForUser(messageId, userId);
    } catch (e) {
      print('Error checking if message is deleted: $e');
      return false;
    }
  }
}