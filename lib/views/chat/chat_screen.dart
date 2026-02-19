import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../user_details/user_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final UserModel otherUser;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.otherUser,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  MessageModel? _selectedMessage;
  MessageModel? _replyingToMessage;
  final Map<String, MessageModel> _messageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
      _scrollToBottom();
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.markMessagesAsRead(widget.currentUserId, widget.otherUser.uid);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      _messageController.clear();

      // Send message with reply if exists
      await chatProvider.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.otherUser.uid,
        message: messageText,
        receiver: widget.otherUser,
        replyToId: _replyingToMessage?.id, // Pass reply message ID
      );

      // Clear reply if exists
      if (_replyingToMessage != null) {
        setState(() {
          _replyingToMessage = null;
        });
      }

      _scrollToBottom();
    } catch (e) {
      _messageController.text = messageText;
      _showErrorSnackBar('Failed to send message. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToUserDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(
          user: widget.otherUser,
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    setState(() {
      _selectedMessage = message;
    });

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _buildMessageOptionsSheet(message);
      },
    ).then((_) {
      setState(() {
        _selectedMessage = null;
      });
    });
  }

  Widget _buildMessageOptionsSheet(MessageModel message) {
    final bool isMyMessage = message.senderId == widget.currentUserId;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply Option
          ListTile(
            leading: Icon(Icons.reply, color: AppColors.primaryColor),
            title: Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              _setReplyMessage(message);
            },
          ),
          Divider(height: 1),

          // Copy Option
          ListTile(
            leading: Icon(Icons.content_copy, color: AppColors.primaryColor),
            title: Text('Copy'),
            onTap: () {
              Navigator.pop(context);
              _copyMessage(message);
            },
          ),
          Divider(height: 1),

          // Edit Option (only for my messages)
          if (isMyMessage)
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primaryColor),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditMessageDialog(message);
              },
            ),
          if (isMyMessage) Divider(height: 1),

          // Delete Options
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.orange),
            title: Text('Delete for me'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(message, deleteForEveryone: false);
            },
          ),
          Divider(height: 1),

          if (isMyMessage)
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.errorColor),
              title: Text('Delete for everyone'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(message, deleteForEveryone: true);
              },
            ),
          if (isMyMessage) Divider(height: 1),

          // Cancel
          ListTile(
            leading: Icon(Icons.close, color: AppColors.subtitleColor),
            title: Text('Cancel', style: TextStyle(color: AppColors.subtitleColor)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _setReplyMessage(MessageModel message) {
    setState(() {
      _replyingToMessage = message;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _copyMessage(MessageModel message) {
    Clipboard.setData(ClipboardData(text: message.message));
    _showSuccessSnackBar('Message copied to clipboard');
  }

  void _showEditMessageDialog(MessageModel message) {
    final TextEditingController editController =
    TextEditingController(text: message.message);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;

              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              try {
                await chatProvider.editMessage(
                  messageId: message.id,
                  newMessage: editController.text.trim(),
                  editorId: widget.currentUserId,
                );
                Navigator.pop(context);
                _showSuccessSnackBar('Message edited');
              } catch (e) {
                _showErrorSnackBar('Failed to edit message');
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MessageModel message, {required bool deleteForEveryone}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteForEveryone ? 'Delete for everyone?' : 'Delete for you?'),
        content: Text(
          deleteForEveryone
              ? 'This message will be deleted for everyone in this chat. This action cannot be undone.'
              : 'This message will be deleted from your chat. Other people in this chat will still be able to see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, deleteForEveryone: deleteForEveryone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: deleteForEveryone ? AppColors.errorColor : Colors.orange,
            ),
            child: Text(deleteForEveryone ? 'Delete for all' : 'Delete for me'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(MessageModel message, {required bool deleteForEveryone}) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.deleteMessage(
        messageId: message.id,
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUser.uid,
        deleteForEveryone: deleteForEveryone,
      );

      _showSuccessSnackBar(
          deleteForEveryone ? 'Message deleted for everyone' : 'Message deleted for you'
      );
    } catch (e) {
      _showErrorSnackBar('Failed to delete message: $e');
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  String _getMessageDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, y').format(timestamp);
    }
  }

  MessageModel? _getRepliedMessage(String? replyToId, List<MessageModel> allMessages) {
    if (replyToId == null || replyToId.isEmpty) return null;

    if (_messageCache.containsKey(replyToId)) {
      return _messageCache[replyToId];
    }

    for (final message in allMessages) {
      if (message.id == replyToId) {
        _messageCache[replyToId] = message;
        return message;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _navigateToUserDetails,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentColor,
                child: widget.otherUser.profileImage.isNotEmpty
                    ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(widget.otherUser.profileImage),
                )
                    : Text(
                  widget.otherUser.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.otherUser.lastSeen
                        .difference(DateTime.now())
                        .inMinutes
                        .abs() <
                        5
                        ? 'Online'
                        : 'Last seen ${DateFormat('HH:mm').format(widget.otherUser.lastSeen)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: _navigateToUserDetails,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingToMessage == null) return SizedBox.shrink();

    final message = _replyingToMessage!;
    final isMyMessage = message.senderId == widget.currentUserId;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chatBackground,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyMessage ? 'Replying to yourself' : 'Replying to ${widget.otherUser.name}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 30,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMyMessage ? 'You' : widget.otherUser.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              message.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.subtitleColor),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return StreamBuilder<List<MessageModel>>(
          stream: chatProvider.streamMessages(
            widget.currentUserId,
            widget.otherUser.uid,
          ),
          builder: (context, snapshot) {
            if (_isInitialLoad && snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              _isInitialLoad = false;
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              _isInitialLoad = false;
              return _buildEmptyState();
            }

            final messages = snapshot.data!;
            _isInitialLoad = false;

            if (messages.isEmpty) {
              return _buildEmptyState();
            }

            return _buildMessagesListView(messages);
          },
        );
      },
    );
  }

  Widget _buildMessagesListView(List<MessageModel> messages) {
    // Sort messages by timestamp ascending (oldest → newest)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Filter out empty messages
    final validMessages = messages.where((m) => m.message.trim().isNotEmpty).toList();

    // Group messages by date header
    Map<String, List<MessageModel>> groupedMessages = {};
    Map<String, DateTime> headerDates = {}; // keep actual date for sorting

    for (final message in validMessages) {
      final dateHeader = _getMessageDateHeader(message.timestamp);
      groupedMessages.putIfAbsent(dateHeader, () => []).add(message);

      // Normalize to midnight for consistent sorting
      final normalizedDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      headerDates[dateHeader] = normalizedDate;
    }

    // Sort headers by actual date ascending (oldest first, newest last)
    final dateHeaders = headerDates.keys.toList()
      ..sort((a, b) => headerDates[a]!.compareTo(headerDates[b]!));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: dateHeaders.length,
      itemBuilder: (context, dateIndex) {
        final dateHeader = dateHeaders[dateIndex];
        final dateMessages = groupedMessages[dateHeader]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateHeader(dateHeader),
            const SizedBox(height: 10),
            ...dateMessages.map((message) {
              final isMyMessage = message.senderId == widget.currentUserId;
              final isReplying = _replyingToMessage?.id == message.id;
              final repliedMessage = _getRepliedMessage(message.replyToId, validMessages);

              return Column(
                children: [
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(message),
                    child: _buildMessageBubble(
                      message,
                      isMyMessage,
                      isReplying,
                      repliedMessage,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              );
            }).toList(),
          ],
        );
      },
    );
  }


  Widget _buildDateHeader(String dateText) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      MessageModel message,
      bool isMe,
      bool isReplying,
      MessageModel? repliedMessage,
      ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            GestureDetector(
              onTap: _navigateToUserDetails,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accentColor,
                child: widget.otherUser.profileImage.isNotEmpty
                    ? CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(widget.otherUser.profileImage),
                )
                    : Text(
                  widget.otherUser.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isReplying
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : isMe ? AppColors.messageBubbleSent : AppColors.messageBubbleReceived,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: isMe ? Radius.circular(12) : Radius.circular(4),
                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(12),
                ),
                border: isReplying
                    ? Border.all(color: AppColors.primaryColor, width: 1.5)
                    : null,
                boxShadow: [
                  if (!isReplying)
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repliedMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 12,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                repliedMessage.senderId == widget.currentUserId
                                    ? 'You'
                                    : widget.otherUser.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            repliedMessage.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.black87 : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.black54 : Colors.black54,
                        ),
                      ),
                      SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? AppColors.messageRead
                              : AppColors.messageSent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined,
                        color: AppColors.primaryColor),
                    onPressed: () {
                      // TODO: Add emoji picker
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _replyingToMessage != null
                            ? 'Reply to message...'
                            : 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file, color: AppColors.primaryColor),
                    onPressed: () {
                      // TODO: Add file attachment
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.accentColor,
                ],
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.errorColor,
          ),
          SizedBox(height: 20),
          Text(
            'Unable to load messages',
            style: TextStyle(
              color: AppColors.errorColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please check your connection',
            style: TextStyle(
              color: AppColors.subtitleColor,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isInitialLoad = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: AppColors.subtitleColor,
          ),
          SizedBox(height: 20),
          Text(
            'No messages yet',
            style: TextStyle(
              color: AppColors.subtitleColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Start the conversation!',
            style: TextStyle(
              color: AppColors.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}