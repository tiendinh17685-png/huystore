class AppNotification {
  final String id;  
  final String title;
  final String message;
  final Map<String, dynamic> payload; 
  final DateTime  createdDate;  
  bool isRead; 

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdDate,
    this.payload = const {}, 
    this.isRead = false,
  });
}