class SmsModel {
  final String id;
  final String phoneNumber;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isInbox;

  SmsModel({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.isInbox,
  });

  factory SmsModel.fromJson(Map<String, dynamic> json) {
    return SmsModel(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone'] ?? json['mobile'] ?? '',
      message: json['content'] ?? json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json['date']?.toString() ?? '0') ?? 0,
      ),
      isRead: json['read'] == '1' || json['isRead'] == true,
      isInbox: json['type'] == 'inbox' || json['isInbox'] == true,
    );
  }
}
