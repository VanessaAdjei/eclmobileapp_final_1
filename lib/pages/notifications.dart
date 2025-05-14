import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottomnav.dart';
import 'cart.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();

    if (keys.isNotEmpty) {
      for (var key in keys) {
        List<String>? notificationStrings = prefs.getStringList(key);
        if (notificationStrings != null) {
          List<Map<String, dynamic>> notifications = notificationStrings
              .map((item) {
            Map<String, dynamic> notification = Map<String, dynamic>.from(jsonDecode(item));
            // Convert string 'true'/'false' to boolean if needed
            notification['expanded'] = _convertToBoolean(notification['expanded']);
            notification['read'] = _convertToBoolean(notification['read']);
            return notification;
          })
              .toList();
          groupedNotifications[key] = notifications;
        }
      }
      setState(() {});
    } else {
      // Only add sample notifications if none exist
      _addSampleNotifications();
    }
  }

  // Helper method to convert string values to boolean
  bool _convertToBoolean(dynamic value) {
    if (value is bool) {
      return value;
    } else if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  void _saveNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    groupedNotifications.forEach((date, notifications) {
      List<String> notificationStrings = notifications.map((notif) => jsonEncode(notif)).toList();
      prefs.setStringList(date, notificationStrings);
    });
  }

  void _addSampleNotifications() {
    if (groupedNotifications.isNotEmpty) return;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("EEEE, MMM d").format(now);

    setState(() {
      if (groupedNotifications.length > 10) {
        groupedNotifications.remove(groupedNotifications.keys.first);
      }

      groupedNotifications.putIfAbsent(formattedDate, () => []);

      groupedNotifications[formattedDate]?.add({
        'title': 'Order Confirmation',
        'message': 'Your order for Pain Relief Tablets has been confirmed and is being processed. You will receive a tracking number soon.',
        'time': '2:15 PM',
        'expanded': false,  // Changed to boolean
        'read': false,      // Changed to boolean
        'icon': 'confirmation',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Shipping Update',
        'message': 'Your order has been shipped and is on its way! Track your package with the tracking number provided.',
        'time': '3:45 PM',
        'expanded': false,
        'read': false,
        'icon': 'shipping',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Product Available',
        'message': 'The Vitamin D3 Supplement you requested is now back in stock! Order now before it runs out again.',
        'time': '9:00 AM',
        'expanded': false,
        'read': false,
        'icon': 'product',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Order Delivered',
        'message': 'Your order has been delivered. Thank you for shopping with us! We hope you enjoy your purchase.',
        'time': '5:30 PM',
        'expanded': false,
        'read': false,
        'icon': 'delivered',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Restock Reminder',
        'message': 'It\'s time to refill your prescription for Blood Pressure Medication. Order now to avoid running out.',
        'time': '8:00 AM',
        'expanded': false,
        'read': false,
        'icon': 'reminder',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Payment Successful',
        'message': 'Your payment for the order Pain Relief Bundle has been successfully processed. Thank you!',
        'time': '2:50 PM',
        'expanded': false,
        'read': false,
        'icon': 'payment',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Order Cancellation',
        'message': 'Your order for Cough Syrup has been canceled due to an issue with payment. Please check your payment details.',
        'time': '6:30 PM',
        'expanded': false,
        'read': false,
        'icon': 'cancel',
      });

      groupedNotifications[formattedDate]?.add({
        'title': 'Order Status Update',
        'message': 'Your order is currently being processed. We will notify you once it ships.',
        'time': '7:45 PM',
        'expanded': false,
        'read': false,
        'icon': 'status',
      });
    });

    _saveNotifications();
  }

  void _toggleExpand(String group, int index) {
    setState(() {
      bool isCurrentlyExpanded = _convertToBoolean(groupedNotifications[group]?[index]['expanded']);
      groupedNotifications[group]?[index]['expanded'] = !isCurrentlyExpanded;
      groupedNotifications[group]?[index]['read'] = true;
    });

    _saveNotifications();
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text('Are you sure you want to clear all notifications?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear All'),
              onPressed: () {
                setState(() {
                  groupedNotifications.clear();
                });
                _saveNotifications();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForNotification(String? iconType) {
    switch (iconType) {
      case 'confirmation':
        return Icons.check_circle_outline;
      case 'shipping':
        return Icons.local_shipping;
      case 'product':
        return Icons.inventory;
      case 'delivered':
        return Icons.inventory_2;
      case 'reminder':
        return Icons.notification_important;
      case 'payment':
        return Icons.payments;
      case 'cancel':
        return Icons.cancel_outlined;
      case 'status':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForNotification(String? iconType) {
    switch (iconType) {
      case 'confirmation':
        return Colors.green;
      case 'shipping':
        return Colors.blue;
      case 'product':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'reminder':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'status':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          elevation: 0,
          centerTitle: true,
          leading: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                onPressed: _clearAllNotifications,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Cart(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: groupedNotifications.isNotEmpty
            ? ListView(
          padding: const EdgeInsets.all(12.0),
          children: [
            ...groupedNotifications.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...entry.value.asMap().entries.map((notification) {
                    int index = notification.key;
                    return _buildNotificationTile(entry.key, index, notification.value);
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        )
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No notifications yet",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "When you receive notifications, they'll appear here",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(),
      ),
    );
  }

  Widget _buildNotificationTile(String group, int index, Map<String, dynamic> notification) {
    bool isExpanded = _convertToBoolean(notification['expanded']);
    bool isRead = _convertToBoolean(notification['read']);
    IconData iconData = _getIconForNotification(notification['icon']);
    Color iconColor = _getColorForNotification(notification['icon']);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(group, index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isRead
              ? null
              : Border.all(color: Colors.green.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          onTap: () {
            _toggleExpand(group, index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['message'] ?? '',
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Handle action specific to this notification type
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: iconColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _getActionText(notification['icon']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      notification['time'] ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Divider(color: Colors.grey[300]),
                  ),
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _deleteNotification(group, index);
                        },
                        icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red[400], fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(120, 36),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNotification(String group, int index) {
    setState(() {
      groupedNotifications[group]?.removeAt(index);
      if (groupedNotifications[group]?.isEmpty ?? false) {
        groupedNotifications.remove(group);
      }
    });
    _saveNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getActionText(String? iconType) {
    switch (iconType) {
      case 'confirmation':
        return 'View Order';
      case 'shipping':
        return 'Track Package';
      case 'product':
        return 'Buy Now';
      case 'delivered':
        return 'Rate Product';
      case 'reminder':
        return 'Reorder';
      case 'payment':
        return 'View Receipt';
      case 'cancel':
        return 'Contact Support';
      case 'status':
        return 'Check Status';
      default:
        return '';
    }
  }
}