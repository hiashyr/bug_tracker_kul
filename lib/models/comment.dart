class Comment {
  final String text;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
 

  Comment({
    required this.text,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
   
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy']['display'],
      updatedAt: DateTime.tryParse(json['updatedAt']),
      updatedBy: json['updatedBy']?['display'] ?? '', 
    );
  }
}