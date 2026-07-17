class AdDomainGroup {
  const AdDomainGroup({
    required this.distinguishedName,
    required this.name,
    this.description,
  });

  final String distinguishedName;
  final String name;
  final String? description;
}
