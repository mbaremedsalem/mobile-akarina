import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/models/facture.dart';
import 'package:akarina/data/models/profile.dart';
import 'package:http/http.dart';


class Repository {
  final NetworkService? networkService;

  Repository({this.networkService});

  // Future<List<Transactionmodel>> ftechtransactions() async {
  //   final trans = await (networkService!.fetchtransactions());
  //   return trans!.map((e) => Transactionmodel.fromJson(e)).toList();
  // }

  // Future<List<Transactionmodel>> serash(
  //     String startDate, String endDate) async {
  //   final trans = await (networkService!.searsh(startDate, endDate));
  //   return trans!.map((e) => Transactionmodel.fromJson(e)).toList();
  // }

  Future<dynamic> validvendor(String qrcode) async {
    final validvendor = await networkService!.validvendor(qrcode);
    return validvendor;
  }

  Future<dynamic> payment(String qrcode) async {
    final payment = await networkService!.payment(qrcode);
    return payment;
  }

  Future<dynamic> envoi(String tel, double montant) async {
    final envoi = await networkService!.envoi(tel, montant);
    return envoi;
  }

  Future<dynamic> paycommercent(
      String? id, double montant, String labbel) async {
    final paycommercent =
        await networkService!.paycommercent(id, montant, labbel);
    return paycommercent;
  }

  Future<dynamic> confiremepayment(String? id, String codeComptable) async {
    final confirmepayment =
        await networkService!.confiremepayment(id, codeComptable);
    return confirmepayment;
  }

  // restore password
  Future<dynamic> restorePassword(String phone) async {
    Response restorePassword = await networkService!.restorePassword(phone);

    return restorePassword;
  }

  Future<dynamic> envoiclientnoraml(
      double montant, String? tel, String? libellle) async {
    final envoinormal =
        await networkService!.envoiclientnoraml(montant, tel, libellle);
    return envoinormal;
  }

  Future<dynamic> envoiclientdigi(
      double montant, String? id, String? libelle) async {
    final envoidigi = await networkService!.envoidigi(montant, id, libelle);
    return envoidigi;
  }

  Future<dynamic> retirer(double montant) async {
    final retirer = await networkService!.retirer(montant);
    return retirer;
  }

  Future<Response> envoicredit(String montant, String operateur,
      String telephone, String? langue) async {
    final credittel =
        await networkService!.credittel(montant, operateur, telephone, langue);
    return credittel;
  }

  Future<dynamic> fetchbalance() async {
    final fetchbalance = await networkService!.fetchbalance();
    return fetchbalance;
  }

  // Future<List<Notfications>> fetchnotfications() async {
  //   final trans = await (networkService!.fetchnotfications());

  //   return trans!.map((e) => Notfications.fromJson(e)).toList();
  // }

  // Future<List<Agence>> fetchagence() async {
  //   final agences = await (networkService!.fetchagences());

  //   return agences!.map((e) => Agence.fromJson(e)).toList();
  // }

  // Future<List<CagnoteModel>> fetchcagnotte() async {
  //   // print('fetching.............');
  //   final cagnottes = await (networkService!.fetchcagnotte());
  //   final prettyString = JsonEncoder.withIndent('  ').convert(cagnottes);

  //   // print(prettyString);
  //   return cagnottes!.map((e) => CagnoteModel.fromJson(e)).toList();
  // }

  Future<dynamic> checkclient(int tel) async {
    final checkclient = await networkService!.checkclient(tel);
    return checkclient;
  }

  Future<dynamic> confirmecagnottecreation(
      String? nom, int? ojectif, String? motif, int? benef) async {
    final checkclient = await networkService!
        .confirmecagnottecreation(nom, ojectif, motif, benef);
    return checkclient;
  }

  Future<dynamic> particpateCagnotte(String? idcagnotte) async {
    final participatecagnotte =
        await networkService!.particpateCagnotte(idcagnotte);

    return participatecagnotte;
  }

  Future<dynamic> confirmepartcipation(int? idcagnotte, int montant) async {
    final confirmepartcipation =
        await networkService!.confirmepartcipation(idcagnotte, montant);

    return confirmepartcipation;
  }

  Future<dynamic> deletecagnotte(int? idcagnotte) async {
    final deltecagnoote = await networkService!.deleteCagnotte(idcagnotte);

    return deltecagnoote;
  }

  // Future<List<Groupe>> listgroupe() async {
  //   final listgroupe = await (networkService!.listGroupe());
  //   return listgroupe!.map((e) => Groupe.fromJson(e)).toList();
  // }

  // Future<List<MembeModel>> fetchbenfecaires(int? groupepaiement) async {
  //   final fetchbenfecaires =
  //       await (networkService!.fetchbenfecaires(groupepaiement));
  //   return fetchbenfecaires!.map((e) => MembeModel.fromJson(e)).toList();
  // }

  Future<List<Factures>> facturier() async {
    final facturier = await (networkService!.facturier());
    // print(facturier);
    return facturier!.map((e) => Factures.fromJson(e)).toList();
  }

  // Future<List<Listparticipant>> fetchparticapnts(int? id) async {
  //   final fetchparticapnts = await (networkService!.fetchparticapnts(id));
  //   return fetchparticapnts!.map((e) => Listparticipant.fromJson(e)).toList();
  // }

  Future<dynamic> cloturer(int? id) async {
    final cloturer = await networkService!.cloturer(id);
    return cloturer;
  }

  Future<dynamic> updatedontaion(int? idcagnotte, int montant) async {
    final updatedontaion = await networkService!
        .updatedonation(idcagnotte: idcagnotte, montant: montant);
    return updatedontaion;
  }

  Future<dynamic> addgroupe(String? nom) async {
    final addgroupe = await networkService!.addgroupe(nom);
    return addgroupe;
  }

  Future<dynamic> addmembre(int number) async {
    final addmembre = await networkService!.addmembre(number);
    return addmembre;
  }

  Future<dynamic> confirmeaddingmembre(
      int? benefecaire, int? groupe, int montant, String motif) async {
    final confirmeaddingmembre = await networkService!
        .confirmeaddingmembre(benefecaire, groupe, montant, motif);
    return confirmeaddingmembre;
  }

  Future<dynamic> deletegrouoe(int? id) async {
    final deletegrouoe = await networkService!.deletegrouoe(id);
    return deletegrouoe;
  }

  Future<dynamic> updatemembre(
      int? id, int? group, int montant, String motif) async {
    final updatemembre =
        await networkService!.updatemembre(id, group, montant, motif);
    return updatemembre;
  }

  Future<dynamic> deletemembre(int? id) async {
    final deletemembre = await networkService!.deletemembre(id);
    return deletemembre;
  }

  Future<dynamic> paiementgroupe(int? id, String? motif) async {
    final paiementgroupe = await networkService!.paiementgroupe(id, motif);
    return paiementgroupe;
  }

  Future<Profil> profiledata() async {
    final profiledata = await networkService!.profiledata();
    return Profil.fromJson(profiledata);
  }

  Future<dynamic> updateprofile(Map body) async {
    final updateprofile = await networkService!.updateprofile(body);
    return updateprofile;
  }

  Future<dynamic> changepassword(Map body) async {
    final changepassword = await networkService!.changepassword(body);
    return changepassword;
  }

  Future<dynamic> logout(Map body) async {
    final logout = await networkService!.logout(body);
    return logout;
  }

  Future<dynamic> confirmecode(String? code) async {
    final confirmecode = await networkService!.confirmecode(code);
    return confirmecode;
  }

  Future<dynamic> checkrefrence(String? reference, String? service) async {
    final confirmecode =
        await networkService!.checkreferencefacture(reference, service);
    return confirmecode;
  }

  // Future<List<Benefecairelist>> benfecairelist(String? groupe) async {
  //   final benfecairelist = await (networkService!.benfecairelist(groupe));
  //   return benfecairelist!.map((e) => Benefecairelist.fromJson(e)).toList();
  // }

  Future<dynamic> consultmauritel(String? number) async {
    final consultmauritel = await networkService!.consultmauritel(number);
    return consultmauritel;
  }

  Future<dynamic> paiementmauritel(
      int? id, String? customercode, double? montant) async {
    final paiementmauritel =
        await networkService!.paiementmauritel(id, customercode, montant);
    return paiementmauritel;
  }

  Future<dynamic> login(String phone, String? password) async {
    final login = await networkService!.login(phone, password);
    // print('---------$login');
    return login;
  }

  Future<dynamic> somelecpayment(double? montant, String? ref, int? id,
      String? service, double? soldeFacture) async {
    final somelecpayment = await networkService!
        .somelecpayment(montant, ref, id, service, soldeFacture);
    return somelecpayment;
  }

  Future<dynamic> fetchFrais(double? montant, String transactionCode) async {
    final fetchfrais =
        await networkService!.fetchFrais(transactionCode, montant);
    return fetchfrais;
  }

  Future<dynamic> fetchsession() async {
    final fetchsession = await networkService!.fetchsession();
    return fetchsession;
  }

  Future<dynamic> operationbancaire(
      String? compteBancaire,
      String? note,
      int montant,
      String? banque,
      String typeComptable,
      String? nomBenfecaire) async {
    final operationbancaire = await networkService!.operationbancaire(
        compteBancaire, note, montant, banque, typeComptable, nomBenfecaire);
    return operationbancaire;
  }

  // reset password
  Future<dynamic> resetPassword(Map body) async {
    Response resetPassword = await networkService!.resetPassword(body);

    return resetPassword;
  }

  // Future<List<Notfications>> fetchnotficationsattents() async {
  //   final trans = await (networkService!.fetchnotficationsattents());

  //   return trans!.map((e) => Notfications.fromJson(e)).toList();
  // }

  Future<dynamic> retireAnnuler(Map body) async {
    Response annulerRetire = await networkService!.retireAnnuler(body);
    return annulerRetire;
  }

  Future<dynamic> developedBy() async {
    final message = await networkService!.developedBy();
    return message;
  }

  Future<dynamic> changeLangue(Map body) async {
    Response langue = await networkService!.changeLangue(body);
    return langue;
  }

  Future<dynamic> retraitgab(double montant) async {
    final retirer = await networkService!.retraitgab(montant);
    return retirer;
  }

  Future<Response> listeCartesRecharge(String? operateur) async {
    Response cartes = await (networkService!.listeCartesRecharge(operateur));
    return cartes;
  }

  Future<dynamic> rechargespackageTel(
      int montant, String? tel, String? operateur, String? service) async {
    final credittel = await networkService!
        .rechargespackageTel(montant, tel, operateur, service);
    return credittel;
  }

  Future<dynamic> checkrefrencesnde(String? ref) async {
    final confirmecode = await networkService!.checkreferencesnde(ref);
    return confirmecode;
  }

  Future<dynamic> sndepayment(
    double? montant,
    String? ref,
    int? id,
    double? soldeFacture,
    String? adresse,
  ) async {
    final sndepayment = await networkService!
        .sndepayment(montant, ref, id, soldeFacture, adresse);
    return sndepayment;
  }

  consultetat(String? service, String? reference) async {
    final payment = await networkService!.consultetat(service, reference);
    return payment;
  }

  Future<dynamic> paymentetat(
      String? service, String? reference, double? montant, int? id) async {
    final payment =
        await networkService!.payementetat(service, reference, montant, id);
    return payment;
  }

  Future<dynamic> checkagent() async {
    final agentVirtuel = await networkService!.checkagent();
    return agentVirtuel;
  }

  Future<dynamic> agentupdate(String? telephone, double? longitude,
      double? latitude, String? adresse, bool online) async {
    final agent = await networkService!
        .agentupdate(telephone, longitude, latitude, adresse, online);
    return agent;
  }

  // Future<List<AgentVirtuel>> fetchagents() async {
  //   final agents = await (networkService!.fetchagents());

  //   return agents!.map((e) => AgentVirtuel.fromJson(e)).toList();
  // }

  Future<dynamic> retraitvirtuelconsult(
    String? telephone,
    double? montant,
    String? code,
  ) async {
    final consult =
        await networkService!.retraitvirtuelconsult(telephone, montant, code);
    return consult;
  }

  Future<dynamic> retraitvirtuel(
    int? retraitId,
    String? code,
  ) async {
    final consult = await networkService!.retraitvirtuel(retraitId, code);
    return consult;
  }

  // Future<List<Reference>> historiquesReference(String? facturierId) async {
  //   final references =
  //       await (networkService!.historiquesReference(facturierId));

  //   return references!.map((e) => Reference.fromJson(e)).toList();
  // }

  // Future<List<Identifiant>> listDernierBeneficiaire(String? type) async {
  //   final identifiant = await (networkService!.listDernierBeneficiaire(type));

  //   return identifiant!.map((e) => Identifiant.fromJson(e)).toList();
  // }

  // Future<dynamic> rechargeTelAutresPays(
  //     int montant, String? tel, String? operateur, String? service) async {
  //   final credittel = await networkService!
  //       .rechargeTelAutresPays(montant, tel, operateur, service);
  //   return credittel;
  // }

  // Future<List<Region?>> consultGuineeInfo(Map body) async {
  //   final data = await networkService!.consultGuineeInfo(body);
  //   return data.map<Region>((e) => Region.fromJson(e)).toList();
  // }

  Future<dynamic> consultVignetteGuinee(Map body) async {
    final consult = await networkService!.consultVignetteGuinee(body);
    return consult;
  }

  Future<dynamic> paiementVignetteGuinee(Map body) async {
    final payment = await networkService!.paiementVignetteGuinee(body);
    return payment;
  }

  Future<Response> fetchcomptes() async {
    final compte = await networkService!.fetchcompte();
    return compte;
  }

  Future<Response> walletcompte(double montant, String? note) async {
    final compte = await networkService!.walletcompte(montant, note);
    return compte;
  }

  Future<Response> comptewallet(double montant, String? note) async {
    final compte = await networkService!.comptewallet(montant, note);
    return compte;
  }

  // Future<List<Transactionmodel>> searchTransactions(String code) async {
  //   final trans = await (networkService!.searchTransaction(code));
  //   List<Transactionmodel> list = [Transactionmodel.fromJson(trans)];
  //   print(list[0].id);
  //   return list;
  // }
  Future<Response> searchTransaction(String code) async {
    final trans = await (networkService!.searchTransaction(code));
    return trans;
  }
  Future<Response> listeBanques() async {
    Response banques = await (networkService!.listeBanques());
    return banques;
  }

  Future<Response> envoiClientInteroperable(
      double montant, String? tel, String? bank, String? typeComptable) async {
    final envoinormal = await networkService!
        .envoiClientInteroperable(montant, tel, bank, typeComptable);
    return envoinormal;
  }

  Future<Response> retraitClientInteroperable(double montant, String? tel,
      String? bank, String? typeComptable, bool isScanned) async {
    final envoinormal = await networkService!.retraitClientInteroperable(
        montant, tel, bank, typeComptable, isScanned);
    return envoinormal;
  }

  Future<Response> paiementClientInteroperable(double montant, String? tel,
      String? bank, String? typeComptable, bool isScanned) async {
    final envoinormal = await networkService!.paiementClientInteroperable(
        montant, tel, bank, typeComptable, isScanned);
    return envoinormal;
  }

}
