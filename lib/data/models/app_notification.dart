class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? reference;
  final String? imageUrl;
  final DateTime receivedAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.reference,
    this.imageUrl,
    required this.receivedAt,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        reference: reference,
        imageUrl: imageUrl,
        receivedAt: receivedAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'reference': reference,
        'imageUrl': imageUrl,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        reference: json['reference'] as String?,
        imageUrl: json['imageUrl'] as String?,
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
        read: json['read'] as bool? ?? false,
      );
}
