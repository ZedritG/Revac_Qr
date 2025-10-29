class TeamInfo {
  const TeamInfo({
    required this.code,
    required this.name,
    this.description,
    this.locationHint,
  });

  final String code;
  final String name;
  final String? description;
  final String? locationHint;
}
