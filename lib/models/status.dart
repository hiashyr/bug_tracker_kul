class Status {
  final String id;
  final String display;

  Status({
    required this.id,
    required this.display
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'],
      display: json['display']
    );
  }
}