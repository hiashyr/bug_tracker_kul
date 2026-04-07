class Issue {
  final String id;
  final String self;
  final String? summary;
  final String? description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String? qaEngineer;

  Issue({
    required this.id,
    required this.self,
    required this.summary,
    this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.qaEngineer,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'],
      self: json['self'],
      summary: json['summary'],
      description: json['description'],
      status: json['status']?['display'],
      priority: json['priority']?['display'],
      
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      
      createdBy: json['createdBy']['display'],
          
      qaEngineer: json['qaEngineer']?['display'],
    );
  }
}