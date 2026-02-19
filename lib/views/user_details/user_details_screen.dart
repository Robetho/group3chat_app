import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Profile Picture
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentColor,
                  width: 3,
                ),
              ),
              child: user.profileImage.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: CachedNetworkImage(
                  imageUrl: user.profileImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircleAvatar(
                    backgroundColor: AppColors.accentColor,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    backgroundColor: AppColors.accentColor,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
                  : CircleAvatar(
                backgroundColor: AppColors.accentColor,
                radius: 60,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // User Name
            Text(
              user.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 5),
            // Status Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: user.lastSeen.difference(DateTime.now()).inMinutes.abs() < 5
                        ? AppColors.onlineIndicator
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  user.lastSeen.difference(DateTime.now()).inMinutes.abs() < 5
                      ? 'Online'
                      : 'Last seen ${DateFormat('dd/MM/yyyy HH:mm').format(user.lastSeen)}',
                  style: TextStyle(
                    color: AppColors.subtitleColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            // User Info Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
                    _buildInfoItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: user.email,
                    ),
                    SizedBox(height: 15),
                    // Phone
                    _buildInfoItem(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: user.phone.isNotEmpty ? user.phone : 'Not provided',
                    ),
                    SizedBox(height: 15),
                    // Member Since
                    _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Member Since',
                      value: DateFormat('dd/MM/yyyy').format(user.createdAt),
                    ),
                    SizedBox(height: 15),
                    // User ID
                    _buildInfoItem(
                      icon: Icons.badge,
                      label: 'User ID',
                      value: user.uid,
                      showCopyButton: true,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: user.uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User ID copied to clipboard'),
                            backgroundColor: AppColors.successColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Message Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close details screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.message, color: Colors.white),
                  label: Text(
                    'Message',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                // Block Button
                ElevatedButton.icon(
                  onPressed: () {
                    _showBlockConfirmation(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.block, color: Colors.white),
                  label: Text(
                    'Block',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool showCopyButton = false,
    VoidCallback? onCopy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.subtitleColor,
                fontSize: 14,
              ),
            ),
            if (showCopyButton && onCopy != null) ...[
              Spacer(),
              IconButton(
                icon: Icon(Icons.content_copy, size: 18, color: AppColors.accentColor),
                onPressed: onCopy,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ],
        ),
        SizedBox(height: 5),
        Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User'),
        content: Text('Are you sure you want to block ${user.name}? You will not receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: Text('Block'),
          ),
        ],
      ),
    );
  }

  void _blockUser(BuildContext context) {
    // TODO: Implement block user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} has been blocked'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }
}