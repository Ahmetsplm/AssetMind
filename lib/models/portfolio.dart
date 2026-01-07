class Portfolio {
  final int? id;
  final String name;
  final bool isDefault;
  final DateTime creationDate;

  Portfolio({
    this.id,
    required this.name,
    required this.isDefault,
    required this.creationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'creation_date': creationDate.toIso8601String(),
    };
  }

  factory Portfolio.fromMap(Map<String, dynamic> map) {
    return Portfolio(
      id: map['id'],
      name: map['name'],
      isDefault: map['is_default'] == 1,
      creationDate: DateTime.parse(map['creation_date']),
    );
  }
}
