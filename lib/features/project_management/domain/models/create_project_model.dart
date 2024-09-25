class Project {
  String id;
  String name;
  String description;
  String template;
  String projectKey;
  String fileUrl; // URL for the uploaded file
  DateTime date; // New property to store the last modified date

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    required this.projectKey,
    required this.fileUrl,
    required this.date, // Include date in constructor
  });

  // Convert a Project object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'projectKey': projectKey,
      'fileUrl': fileUrl,
      'date': date
          .toIso8601String(), // Convert DateTime to ISO 8601 string for Firestore
    };
  }

  // Convert a Map object into a Project object
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      template: map['template'],
      projectKey: map['projectKey'],
      fileUrl: map['fileUrl'],
      date: DateTime.parse(map['date']), // Parse ISO 8601 string to DateTime
    );
  }
}
