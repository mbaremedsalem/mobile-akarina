


class PropertyType {
  int? count;
  String? name;

  PropertyType({
    this.count,
    this.name,
  });

  // Méthode pour créer un objet à partir du JSON
  PropertyType.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    name = json['name'];
  }

  // Méthode pour convertir l'objet en JSON (utile si nécessaire)
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'name': name,
    };
  }
}


class PropertyTypes {
  PropertyType? appartements;
  PropertyType? duplexes;
  PropertyType? commerciaux;
  PropertyType? terrains;
  PropertyType? residentiels;

  PropertyTypes({
    this.appartements,
    this.duplexes,
    this.commerciaux,
    this.terrains,
    this.residentiels,
  });

  // Méthode pour créer un objet à partir du JSON
  PropertyTypes.fromJson(Map<String, dynamic> json) {
    appartements = PropertyType.fromJson(json['appartements']);
    duplexes = PropertyType.fromJson(json['duplexes']);
    commerciaux = PropertyType.fromJson(json['commerciaux']);
    terrains = PropertyType.fromJson(json['terrains']);
    residentiels = PropertyType.fromJson(json['residentiels']);
  }

  // Méthode pour convertir l'objet en JSON (utile si nécessaire)
  Map<String, dynamic> toJson() {
    return {
      'appartements': appartements?.toJson(),
      'duplexes': duplexes?.toJson(),
      'commerciaux': commerciaux?.toJson(),
      'terrains': terrains?.toJson(),
      'residentiels': residentiels?.toJson(),
    };
  }
}
