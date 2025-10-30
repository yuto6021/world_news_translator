class Country {
  final String name;
  final String code;

  Country({required this.name, required this.code});

  factory Country.fromMap(MapEntry<String, String> entry) {
    return Country(name: entry.key, code: entry.value);
  }
}