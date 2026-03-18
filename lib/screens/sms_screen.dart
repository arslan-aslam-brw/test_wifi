import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/router_provider.dart';
import '../models/sms_model.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final List<String> _selectedSmsIds = [];
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedSmsIds.length} selected'
              : 'SMS Messages',
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showComposeDialog,
            ),
        ],
      ),
      body: Consumer<RouterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.smsMessages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sms, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No SMS messages',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showComposeDialog,
                    child: const Text('Send New Message'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.smsMessages.length,
            itemBuilder: (context, index) {
              final sms = provider.smsMessages[index];
              return _buildSmsTile(sms);
            },
          );
        },
      ),
    );
  }

  Widget _buildSmsTile(SmsModel sms) {
    final isSelected = _selectedSmsIds.contains(sms.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sms.isInbox
              ? Colors.blue.shade100
              : Colors.green.shade100,
          child: Icon(
            sms.isInbox ? Icons.inbox : Icons.send,
            color: sms.isInbox ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(
          sms.phoneNumber,
          style: TextStyle(
            fontWeight: sms.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sms.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              _formatDate(sms.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(sms.id),
              )
            : PopupMenuButton(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog([sms.id]);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(sms.id);
          } else {
            _showSmsDialog(sms);
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _toggleSelection(sms.id);
          });
        },
      ),
    );
  }

  void _toggleSelection(String smsId) {
    setState(() {
      if (_selectedSmsIds.contains(smsId)) {
        _selectedSmsIds.remove(smsId);
      } else {
        _selectedSmsIds.add(smsId);
      }

      if (_selectedSmsIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _deleteSelected() {
    if (_selectedSmsIds.isNotEmpty) {
      _showDeleteDialog(_selectedSmsIds);
    }
  }

  void _showDeleteDialog(List<String> smsIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${smsIds.length} message${smsIds.length > 1 ? 's' : ''}',
        ),
        content: Text('Are you sure you want to delete these messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<RouterProvider>(
                context,
                listen: false,
              );
              await provider.deleteSms(smsIds);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = false;
                  _selectedSmsIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Messages deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSmsDialog(SmsModel sms) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sms.phoneNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(sms.message),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(sms.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showReplyDialog(sms.phoneNumber);
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showComposeDialog() {
    final phoneController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compose Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (phoneController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                final provider = Provider.of<RouterProvider>(
                  context,
                  listen: false,
                );
                await provider.sendSms(
                  phoneController.text,
                  messageController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message sent'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(String phoneNumber) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To: $phoneNumber'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.isNotEmpty) {
                final provider = Provider.of<RouterProvider>(
                  context,
                  listen: false,
                );
                await provider.sendSms(phoneNumber, messageController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reply sent'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
