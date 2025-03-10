class Profil {
  dynamic payements;
  dynamic remboursements;
  dynamic envoiesRecus;
  dynamic envoiesFaits;
  dynamic recharges;
  dynamic retraits;
  dynamic retraitsParSms;

  Profil(
      {this.payements,
      this.remboursements,
      this.envoiesRecus,
      this.envoiesFaits,
      this.recharges,
      this.retraits,
      this.retraitsParSms});

  Profil.fromJson(Map<String, dynamic> json) {
    payements = json['payements'];
    remboursements = json['remboursements'];
    envoiesRecus = json['envoies_recus'];
    envoiesFaits = json['envoies_faits'];
    recharges = json['recharges'];
    retraits = json['retraits'];
    retraitsParSms = json['retraits_par_sms'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['payements'] = this.payements;
    data['remboursements'] = this.remboursements;
    data['envoies_recus'] = this.envoiesRecus;
    data['envoies_faits'] = this.envoiesFaits;
    data['recharges'] = this.recharges;
    data['retraits'] = this.retraits;
    data['retraits_par_sms'] = this.retraitsParSms;
    return data;
  }
}
