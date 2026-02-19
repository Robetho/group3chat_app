import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.accentColor,
              child: Text(
                'U',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (!isMe) SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.senderMessage : AppColors.receiverMessage,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isMe ? Radius.circular(20) : Radius.circular(5),
                  bottomRight: isMe ? Radius.circular(5) : Radius.circular(20),
                ),
                boxShadow: [
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
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: 10),
          if (isMe)
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                'M',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}