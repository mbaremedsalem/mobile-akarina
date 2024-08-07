class Factures {
  int? id;
  String? nom;
  List<Facturier>? facturiers;

  Factures({
    this.id,
    this.nom,
    this.facturiers,
  });

  Factures.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nom = json['nom'];
    if (json['facturiers'] != null) {
      facturiers = new List<Facturier>.empty(growable: true);
      json['facturiers'].forEach((value) {
        facturiers!.add(new Facturier.fromJson(value));
      });
    }
  }
}

class Facturier {
  int? id;
  String? nom;
  List<Services>? services;

  Facturier({
    this.id,
    this.nom,
    this.services,
  });

  Facturier.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nom = json['nom'];
    if (json['services'] != null) {
      services = new List<Services>.empty(growable: true);
      json['services'].forEach((value) {
        services!.add(new Services.fromJson(value));
      });
    }
  }
}

class Services {
  int? id;
  String? nom;
  String? code;

  Services({
    this.id,
    this.nom,
    this.code,
  });

  Services.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nom = json['nom'];
    code = json['code'];
  }
}
