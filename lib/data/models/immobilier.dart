class Immobilier {
  final int id;
  final String ville;
  final String superficie;
  final String type;
  final String adresse;
  final String prix;
  final String description;
  final int numReviews;
  final double ratings;
  final bool available;
  final List<String> images;

  Immobilier({
    required this.id,
    required this.ville,
    required this.superficie,
    required this.type,
    required this.adresse,
    required this.prix,
    required this.description,
    required this.numReviews,
    required this.ratings,
    required this.available,
    required this.images,
  });

  factory Immobilier.fromJson(Map<String, dynamic> json) {
    return Immobilier(
      id: json['id'],
      ville: json['ville'].toString(),
      superficie: json['superficie'],
      type: json['type'],
      adresse: json['adresse'],
      prix: json['prix'],
      description: json['description'],
      numReviews: json['numReviews'],
      ratings: double.parse(json['ratings']),
      available: json['available'],
      images: List<String>.from(
        json['images'].map((image) => 'https://akarina-location-b65cbbb9833c.herokuapp.com${image['image']}'),
      ),
    );
  }
}
