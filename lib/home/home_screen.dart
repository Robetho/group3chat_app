import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../views/chat/chat_screen.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';
import 'package:groupthree_chatapp/core/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  bool _isTestingNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        chatProvider.initializeNotifications(authProvider.currentUser!.uid);
        authProvider.updateUserLastSeen();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search users...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: TextStyle(color: Colors.white, fontSize: 16),
      onChanged: (value) {
        Provider.of<ChatProvider>(context, listen: false).setSearchQuery(value);
      },
    );
  }

  // METHOD FOR TESTING NOTIFICATIONS
  Future<void> _testNotifications() async {
    if (_isTestingNotifications) return;

    setState(() {
      _isTestingNotifications = true;
    });

    try {
      final notificationService = NotificationService();

      // Test 1: Check notification settings
      await notificationService.checkNotificationSettings();

      // Test 2: Send local notification
      await notificationService.sendTestNotification();

      // Test 3: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent! Check your status bar.'),
          duration: Duration(seconds: 3),
          backgroundColor: AppColors.successColor,
        ),
      );

      print('✅ Test completed successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing notifications: $e'),
          duration: Duration(seconds: 3),
          backgroundColor: AppColors.errorColor,
        ),
      );
      print('❌ Error testing notifications: $e');
    } finally {
      setState(() {
        _isTestingNotifications = false;
      });
    }
  }

  // UPDATED APP BAR ACTIONS WITHOUT BELL ICON
  List<Widget> _buildAppBarActions(BuildContext context) {
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              Provider.of<ChatProvider>(context, listen: false).clearSearch();
            });
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'logout') {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
            } else if (value == 'test_notifications') {
              _testNotifications();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'test_notifications',
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: AppColors.primaryColor),
                  SizedBox(width: 10),
                  Text('Test Notifications'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: _isSearching
            ? _buildSearchField()
            : Text(
          'Group 3 Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: _buildAppBarActions(context),
        leading: _isSearching
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              chatProvider.clearSearch();
            });
          },
        )
            : null,
      ),
      body: Stack(
        children: [
          _selectedIndex == 0
              ? _buildChatsTab(currentUser.uid)
              : _buildUsersTab(currentUser.uid),
          // SHOW LOADING WHEN TESTING NOTIFICATIONS
          if (_isTestingNotifications)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Testing Notifications...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1 && !_isSearching
          ? FloatingActionButton(
        heroTag: 'new_message',
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.message, color: Colors.white),
        onPressed: () {
          _showUserSelectionDialog(context, currentUser.uid);
        },
        tooltip: 'New Message',
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.accentColor,
        unselectedItemColor: AppColors.subtitleColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (_isSearching) {
              _isSearching = false;
              _searchController.clear();
              chatProvider.clearSearch();
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.chat),
                Positioned(
                  right: 0,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: chatProvider.streamChats(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final totalUnread = snapshot.data!.fold(
                            0, (sum, chat) => sum + (chat['unreadCount'] as int));

                        if (totalUnread > 0) {
                          return Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              totalUnread > 9 ? '9+' : totalUnread.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab(String currentUserId) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatProvider.streamChats(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allChats = snapshot.data ?? [];
        final chats = _isSearching
            ? chatProvider.searchedChats(allChats, currentUserId)
            : allChats;

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                  size: 80,
                  color: AppColors.subtitleColor,
                ),
                SizedBox(height: 20),
                Text(
                  _isSearching ? 'No results found' : 'No chats yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.subtitleColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _isSearching
                      ? 'Try different keywords'
                      : 'Start a conversation with someone!',
                  style: TextStyle(
                    color: AppColors.subtitleColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUser = chat['otherUser'] as dynamic;
            final lastMessageTime = chat['lastMessageTime'] as DateTime;
            final lastMessage = chat['lastMessage'] as String;
            final unreadCount = chat['unreadCount'] as int;

            return StreamBuilder<int>(
              stream: chatProvider.getUnreadCount(currentUserId, otherUser.uid),
              builder: (context, unreadSnapshot) {
                final currentUnreadCount = unreadSnapshot.data ?? unreadCount;

                return ListTile(
                  onTap: () async {
                    // Mark messages as read before opening chat
                    if (currentUnreadCount > 0) {
                      await chatProvider.markMessagesAsRead(
                          currentUserId, otherUser.uid);
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: currentUserId,
                          otherUser:
                          UserModel.fromMap(otherUser.toMap(), otherUser.uid),
                        ),
                      ),
                    );
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.accentColor,
                        child: otherUser.profileImage.isNotEmpty
                            ? CircleAvatar(
                          radius: 23,
                          backgroundImage:
                          NetworkImage(otherUser.profileImage),
                        )
                            : Text(
                          otherUser.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (currentUnreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              currentUnreadCount > 9
                                  ? '9+'
                                  : currentUnreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    otherUser.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentUnreadCount > 0
                          ? AppColors.primaryColor
                          : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: currentUnreadCount > 0
                          ? AppColors.primaryColor
                          : AppColors.subtitleColor,
                      fontWeight: currentUnreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab(String currentUserId) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return StreamBuilder<List<UserModel>>(
      stream: chatProvider.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allUsers = snapshot.data ?? [];
        final users = _isSearching
            ? chatProvider.searchedUsers
            : allUsers.where((user) => user.uid != currentUserId).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSearching ? Icons.search_off : Icons.people_outline,
                  size: 80,
                  color: AppColors.subtitleColor,
                ),
                SizedBox(height: 20),
                Text(
                  _isSearching ? 'No results found' : 'No other users',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.subtitleColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _isSearching
                      ? 'Try different keywords'
                      : 'Tell your friends to join!',
                  style: TextStyle(
                    color: AppColors.subtitleColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];

            return StreamBuilder<int>(
              stream: chatProvider.getUnreadCount(currentUserId, user.uid),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data ?? 0;

                return ListTile(
                  onTap: () async {
                    // Mark messages as read before opening chat
                    if (unreadCount > 0) {
                      await chatProvider.markMessagesAsRead(
                          currentUserId, user.uid);
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: currentUserId,
                          otherUser: user,
                        ),
                      ),
                    );
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.accentColor,
                        child: user.profileImage.isNotEmpty
                            ? CircleAvatar(
                          radius: 23,
                          backgroundImage: NetworkImage(user.profileImage),
                        )
                            : Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: user.lastSeen
                                .difference(DateTime.now())
                                .inMinutes
                                .abs() <
                                5
                                ? AppColors.onlineIndicator
                                : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                      unreadCount > 0 ? AppColors.primaryColor : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    user.email,
                    style: TextStyle(
                      color: AppColors.subtitleColor,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(user.lastSeen),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                      if (unreadCount > 0) SizedBox(height: 5),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showUserSelectionDialog(BuildContext context, String currentUserId) {
    showDialog(
      context: context,
      builder: (context) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        return StreamBuilder<List<UserModel>>(
          stream: chatProvider.streamUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AlertDialog(
                title: Text('Select User'),
                content: Center(child: CircularProgressIndicator()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ],
              );
            }

            final users = snapshot.data!
                .where((user) => user.uid != currentUserId)
                .toList();

            return AlertDialog(
              title: Text('Start New Chat'),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: users.isEmpty
                    ? Center(
                  child: Text(
                    'No other users available',
                    style: TextStyle(color: AppColors.subtitleColor),
                  ),
                )
                    : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentColor,
                        child: user.profileImage.isNotEmpty
                            ? CircleAvatar(
                          backgroundImage:
                          NetworkImage(user.profileImage),
                        )
                            : Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUserId: currentUserId,
                              otherUser: user,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}