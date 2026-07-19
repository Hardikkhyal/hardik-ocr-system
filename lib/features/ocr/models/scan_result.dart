class ScanResult {
  final String id;
  final String text;
  final String imagePath;
  final DateTime timestamp;

  ScanResult({
    required this.id,
    required this.text,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String,
      text: json['text'] as String,
      imagePath: json['imagePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  ScanResult copyWith({
    String? id,
    String? text,
    String? imagePath,
    DateTime? timestamp,
  }) {
    return ScanResult(
      id: id ?? this.id,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
