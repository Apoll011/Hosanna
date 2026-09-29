/// A collaborative note on a worship service, separate from the replicated
/// `Service.elements[].notes` string and from RxDB sync.
class ServiceNoteAuthor {
  const ServiceNoteAuthor({
    required this.id,
    required this.name,
    this.image,
  });

  final String id;
  final String name;
  final String? image;

  factory ServiceNoteAuthor.fromJson(Map<String, dynamic> json) {
    return ServiceNoteAuthor(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      image: json['image'] as String?,
    );
  }
}

class ServiceNote {
  const ServiceNote({
    required this.id,
    required this.serviceId,
    required this.body,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
    this.elementId,
    this.author,
  });

  final String id;
  final String serviceId;

  /// Null when the note belongs to the service itself.
  final String? elementId;
  final String body;
  final bool isPrivate;
  final ServiceNoteAuthor? author;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isAuthoredBy(String? userId) =>
      userId != null && author != null && author!.id == userId;

  factory ServiceNote.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    return ServiceNote(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      elementId: json['elementId'] as String?,
      body: (json['body'] as String?) ?? '',
      isPrivate: json['private'] == true,
      author: authorJson is Map<String, dynamic>
          ? ServiceNoteAuthor.fromJson(authorJson)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
