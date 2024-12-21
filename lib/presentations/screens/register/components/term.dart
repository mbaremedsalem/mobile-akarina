import 'dart:convert';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:http/http.dart';

class Term extends StatefulWidget {
  const Term({this.password, this.tel});

  final String? password;
  final String? tel;

  @override
  _TermState createState() => _TermState();
}

class _TermState extends State<Term> {
  final storage = FlutterSecureStorage();

  String? lieuNaissanceAr;
  String? lieuNaissanceFr;
  String? nationaliteIso;
  String? nni;
  String? nomFamilleAr;
  String? nomFamilleFr;
  String? prenomAr;
  String? prenomFr;
  String? prenomPereAr;
  String? prenomPereFr;
  String? sexeFr;
  String? datenaissance;
  String? langue;
  String? pays;

  void ftetchinfo() async {
    String? datenaissancefetched = await storage.read(key: "dateNaissance");
    String? lieuNaissanceArfetched = await storage.read(key: "lieuNaissanceAr");
    String? lieuNaissanceFrfetched = await storage.read(key: "lieuNaissanceFr");
    String? nationaliteIsofetched = await storage.read(key: "nationaliteIso");
    String? nnifetched = await storage.read(key: "nni");
    String? nomFamilleArfetched = await storage.read(key: "nomFamilleAr");
    String? nomFamilleFrfetched = await storage.read(key: "nomFamilleFr");
    String? prenomArfetched = await storage.read(key: "prenomAr");
    String? prenomFrfetched = await storage.read(key: "prenomFr");
    String? prenomPereArfetched = await storage.read(key: "prenomPereAr");
    String? prenomPereFrfetched = await storage.read(key: "prenomPereFr");
    String? sexeFrfetched = await storage.read(key: "sexeFr");
    String? _pays = await storage.read(key: "country");
    setState(() {
      lieuNaissanceAr = lieuNaissanceArfetched;
      lieuNaissanceFr = lieuNaissanceFrfetched;
      nationaliteIso = nationaliteIsofetched;
      nni = nnifetched;
      nomFamilleAr = nomFamilleArfetched;
      nomFamilleFr = nomFamilleFrfetched;
      prenomAr = prenomArfetched;
      prenomFr = prenomFrfetched;
      prenomPereAr = prenomPereArfetched;
      prenomPereFr = prenomPereFrfetched;
      sexeFr = sexeFrfetched;
      datenaissance = datenaissancefetched;
      langue = getTranslated(context, "langue");
      pays = _pays;
    });
  }

  @override
  void initState() {
    super.initState();
    ftetchinfo();
  }

  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              // gradient: RadialGradient(
              //   center: Alignment.center,
              //   colors: [
              //     Color.fromRGBO(255, 255, 255, 0.59),
              //     Color.fromRGBO(255, 255, 255, 0.59),
              //     Color.fromRGBO(222, 235, 255, 0.59)
              //   ],
              //   stops: [0, 0.5, 1],
              //   radius: 0.8,
              // ),
              ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(16)),
            child: ListView(
              children: [
                spaceHeight(20),
                Text(
                  getTranslated(context, "Termes et Conditions")!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: pdarkcolor,
                      fontSize: getProportionateScreenWidth(24),
                      fontWeight: FontWeight.bold),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 1. Préambule",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Banque Pour Le Commerce et l’industrie (BCI) est une société anonyme aucapital de 1000 000 000 Ouguiyas-Siège social, 57 AVENUE GAMAL ABDEL ANSSER - Nouakchott Mauritanie. Elle met à disposition de ses clients le produit mobile banking appelé « BCIP@Y » qui fait l’objet des présentes Conditions Générales.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Article 2. Définitions",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« La Banque » : désigne Banque Pour Le commerce Et L’industrie",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Client désigne toute personne titulaire d'un compte bancaire ouvert à la Banque Pour Le commerce Et L’industrie ayant souscrit au service mobile de la Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Service » : désigne le service mobile de la BCI « BCIP@Y ».",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« BCIP@Y » est la solution de mobile Banking de la Banque Pour Le commerce Et L’industrie qui permet une ouverture de compte à distance et la réalisation d’un ensemble d’opérations bancaires.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Code à usage unique » OTP : désigne un authentifiant répondant aux critères de sécurité instaurés par la Banque Pour Le commerce Et L’industrie et destiné à sécuriser l'opération pour laquelle il a été généré. Ce code ne peut être utilisé qu’une fois.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Code d'accès » : désigne indifféremment l'identifiant et le mot de passe ainsi que tout autre code ou clé répondant aux critères de sécurité instaurés par la Banque Pour Le commerce Et L’industrie A pour objet d'identifier et d'authentifier l'utilisateur pour les besoins de son accès à son espace personnel.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 3. Objet",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les présentes Conditions Générales ont pour objet de  définir les conditions d’utilisation et d'accès du produit BCIP@Y, conformément aux dispositions de la réglementation en vigueur.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 4. Modalités des connexion",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Client ne peut bénéficier des services qui lui sont proposés que sous réserve de son acceptation des présentes Conditions Générales et après la validation de son numéro de téléphone personnel et de son Numéro National d’Identification (NNI) qui permettent de l’identifier conformément à la législation en vigueur.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "L'accès au Service nécessite que le Client ait accepté, au préalable, les présentes Conditions générales d'utilisation ainsi que leurs évolutions éventuelles.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Un Compte est ouvert dans les livres de la société Banque Pour Le commerce Et L’industrie   après acceptation des présentes Conditions Générales.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque se réserve le droit de modifier, à tout moment, son application en fonction de l'évolution de la technologie et de la réglementation en vigueur.De meme qu’elle se reserve le droit de cloturer tout compte dont le fonctionnement n’est pas conforme a la reglementation ou qui presente un risque de reputation pour la banque ,",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque se réserve le droit de modifier, à tout moment, son application en fonction de l'évolution de la technologie et de la réglementation en vigueur.De meme qu’elle se reserve le droit de cloturer tout compte dont le fonctionnement n’est pas conforme a la reglementation ou qui presente un risque de reputation pour la banque ,",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque ne saurait être tenue responsable de l'impossibilité d'accéder au service.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "L’accès au Service est également lié à l’acceptation du dossier de connaissance du client (KYC) : les Clients qui ont ouvert leurs comptes à distance ne  peuvent effectuer les transactions proposées dans le cadre du Service « BCIP@Y » .",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Afin d’accéder à l’ensemble des services « BCIP@Y » les clients ayant ouverts des comptes à distance doivent se présenter aux guichets d’une des agences de la Banque ou à l’un de ses agents afin de s’identifier, présenter leurs pièces d’identité, fournir quelques informations exigées par la réglementation en vigueur et signer une convention d’ouverture de compte. La Banque se réserve le droit de modifier, à tout moment, les plafonds définis dans le cadre du Service.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 5. Fonctionnement",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le compte doit accuser un solde créditeur minimum de 1000  permettant les retraits, paiements et transferts (frais compris) dans la limite du solde disponible.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En application de la réglementation en vigueur, la Banque conserve les documents comptables relatifs aux opérations enregistrées sur le compte pendant 10 ans.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Service est lié à un numéro de téléphone et un appareil unique, identifiés lors de l’entrée en relation",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le changement du numéro de téléphone requiert l’accès au numéro de téléphone initial sur lequel un code de confirmation sera transmis par sms.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 6. Opposabilité",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les présentes Conditions Générales sont opposables au Client dès leur acceptation, matérialisée par la validation électronique via l’application mobile.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque se réserve le droit d'apporter aux présentes Conditions Générales toutes les modifications qu'elle juge nécessaires et/ou utiles. Elle se réserve également la possibilité de modifier en tout ou partie le document afin de l'adapter, notamment, aux évolutions de son exploitation, et/ou à l'évolution de la législation et/ou aux évolutions des services proposés.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les présentes Conditions Générales sont opposables pendant toute la durée d'utilisation du produit et jusqu'à ce que de nouvelles conditions générales d'utilisation remplacent les présentes.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque communiquera au client les nouvelles conditions générales d'utilisation par tout moyen, et ce, dès leur date d'entrée en vigueur.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les Conditions Générales figurant en ligne sur le site www.bci-banque.com  prévalent sur toute version imprimée de date antérieure.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 7. saisit arrêt ",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le compte du client peut être bloqué par voie de saisie-arrêt ou saisie conservatoire notifiées à la Banque par exploit d’huissier ou par voie d’avis au tiers détenteur (ATD) notifié par le Trésor Public pour les créances fiscales. Dans ces cas de figure la Banque informera le Client pour lui permettre de contester la mesure de saisie ou ATD et éventuellement obtenir une mainlevée. A défaut d’une mainlevée signifiée à la Banque dans les 8 jours suivant les formes de la notification de la saisie ou ATD, la Banque est obligée à se conformer aux prescriptions aux actes de saisie et /ou ATD.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 8. Lutte contre le blanchiment d’argent",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Client reconnait être Informé qu’en raison des dispositions pénales spécifiques au blanchiment des capitaux provenant du trafic de stupéfiants ou au blanchiment du produit de tout crime ou délit, la Banque peut demander des informations relatives aux objectifs et conditions de réalisation de toute opération qui lui semblerait inhabituelle en raison notamment de son montant et de ses modalités ou de son caractère exceptionnel. La Banque est autorisée à dénoncer les opérations douteuses aux autorités compétentes.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 9 Operations ",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La souscription au Service Mobile permet au Client de :",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Effectuer, à partir de son compte « BCIP@Y », des opérations bancaires vers des comptes Banque pour le commerce et l’industrie et des comptes d’autres banques installées en Mauritanie.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Effectuer des mises à disposition de fonds au profit de bénéficiaires au niveau des agences de la Banque de son réseau d’agents.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Effectuer des retraits d’espèces au niveau des agences de la Banque,  de son réseau d’agents.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Effectuer des versements d’espèces sur le compte ouvert à la Banque au niveau des agences de la Banque et de son réseau d’agents.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Régler des factures fournisseurs (SNDE/SOMELEC) et autre.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Acheter des recharges téléphoniques",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Consulter le solde de son compte à la Banque BCI",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Obtenir un relevé bancaire reprenant les dernières opérations.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 10. Bonne foi",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les parties conviennent d'exécuter leurs obligations avec une parfaite bonne foi.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 11. Responsabilités",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Sachant qu’aucune opération ne peut être réalisée sur l’application en l’absence de connexion avec l’identifiant et le mot de passe du client, puis après validation, en seconde étape, de cette opération par une nouvelle saisie du même mot de passe, à titre de confirmation.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les identifiants, mot de passe et Code à usage unique et, en général, tout autre Code d'accès sont strictement personnels et confidentiels. Le Client est seul responsable de la préservation et de la confidentialité de son identifiant, de son Code d’accès et de son Code à usage unique et, par conséquent, des conséquences d'une divulgation volontaire ou involontaire à l’égard de toute personne tierce.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le client est le seul responsable de toute opération exécutée à partir de son espace personnel, en utilisant son identifiant, son mot de passe ou son code à usage unique. Toute utilisation de l'espace personnel et, en conséquence, toute opération réalisée à partir de cet espace, par l’usage de l'identifiant, du mot de passe ou du Code à usage unique attribués au Client est présumée être exécutée par ce dernier et sous sa seule responsabilité. . Il assume, seul, l’entière responsabilité d’erreurs de manipulation par ses soins ou de divulgation par ses soins de ses mots de passe et codes à des tiers et il déclare qu’il décharge expressément la banque de toute responsabilité à cet égard.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Client a l'obligation de notifier à la Banque, sans délai, toute compromission de la confidentialité de son identifiant et/ou de son mot de passe ou toute utilisation dont il aurait connaissance de ses données confidentielles par un tiers.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque se réserve le droit de suspendre l'accès au Service BCIP@Y nécessitant l'identification du Client si elle relève des faits laissant présumer une utilisation frauduleuse ou une tentative d'utilisation frauduleuse de ses services ou que le Client a communiqué des informations inexactes se rapportant à son identité. Elle en informe aussitôt le Client, par tout moyen à sa convenance, ce qui est expressément accepté par ce dernier.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Client est également responsable des informations qu’il fournit, à distance, à la Banque. La banque se réserve le droit d’entamer toute procédure judiciaire à l’encontre du Client dans le cas où celui-ci fournit de fausses déclarations pour l’accès à ses services.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 12. Propriété intellectuelle",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les présentes Conditions Générales n'emportent aucune cession d'aucune sorte de droits de propriété intellectuelle sur les éléments appartenant à La Banque au bénéfice du Client.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En conséquence, le Client s'interdit tout agissement et tout acte susceptible de porter atteinte directement ou non aux droits de propriété intellectuelle de La Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 13. Sécurité",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Tout accès frauduleux à l’application est interdit et sanctionné pénalement.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Client accepte de prendre toutes les mesures appropriées de façon à protéger son téléphone de la contamination par des éventuels virus.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 14. Résiliation",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En cas de manquement aux obligations des présentes, clôture du compte du Client, utilisation frauduleuse et fonctionnement irrégulier du service dus aux manœuvres du Client, sans que cette liste ne soit exhaustive, La Banque peut résilier de plein droit et sans préavis le Service.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Par ailleurs, le Client pourra mettre fin, à tout moment, aux présentes. La Banque aura le droit d’exercer un droit de rétention sur le solde créditeur du compte clôturé de l’ensemble des montants dus par le Client au titre de l’utilisation du Service ou d’autres produits ou services de la Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Enfin, la Banque se réserve le droit de résilier, sans préavis, tout compte dont le solde est nul et sur lequel aucune transaction n’a été effectuée depuis plus de 3 mois.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En cas de désabonnement du Service, la Banque se réserve le droit de procéder à la clôture du compte bancaire associé. Le clôture du compte doit être effectuée dans l’une des agences de la Banque, après prélèvement des frais tels que décrits précédemment.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Décès du Client",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontStyle: FontStyle.italic,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w600,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Dès que la Banque est avisée par un document officiel du décès du Client, le compte est bloqué et aucune opération initiée postérieurement au décès ne peut intervenir sur le compte jusqu’à justification des ayants droit du défunt ou instructions du Juge chargé de la succession.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article15. Intégralité",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les termes contractuels expriment l'intégralité des obligations des parties.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 16. Convention de Preuve",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "L'acceptation des Conditions Générales par voie électronique a, entre les parties, la même valeur probante que l'accord sur support papier.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les registres informatisés et conservés dans les systèmes considérés comme les preuves des communications intervenues entre les parties.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Article 17. Loi Applicable et Juridiction Compétente",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le présent contrat est régi par la loi mauritanienne.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Tout litige portant sur l'interprétation ou l'exécution des présentes sera soumis à la compétence exclusive des tribunaux de Nouakchott.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                SizedBox(
                  height: getProportionateScreenHeight(30),
                ),
                loading
                    ? spiner()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MaterialButton(
                              minWidth: getProportionateScreenWidth(300),
                              shape: buttonshape,
                              height: buttonheight,
                              onPressed: () async {
                                setState(() {
                                  loading = true;
                                });
                                Map body = {
                                  "username": widget.tel,
                                  "first_name": prenomFr,
                                  "last_name": nomFamilleFr,
                                  "password": widget.password,
                                  "date_naissance": datenaissance,
                                  "middle_name": prenomPereFr,
                                  "lieu_naissance": lieuNaissanceFr,
                                  "nationalite": nationaliteIso,
                                  "sexe": sexeFr,
                                  "middle_name_ar": prenomPereAr,
                                  "first_name_ar": prenomAr,
                                  "last_name_ar": nomFamilleAr,
                                  "lieu_naissance_ar": lieuNaissanceAr,
                                  "nni": nni,
                                  "email": "",
                                  "adresse": "",
                                  "langue": langue
                                };
                                // print(datenaissance);
                                var url = Uri.parse(baseParPays(pays!) +
                                    "api/user/client_digiPay/register/");
                                try {
                                  var response = await post(url,
                                          headers: {
                                            'Content-Type':
                                                'application/json; charset=utf-8'
                                          },
                                          body: jsonEncode(body))
                                      .timeout(Duration(seconds: 20));

                                  // print(response.statusCode);

                                  // print(response.body);

                                  if (response.statusCode == 201) {
                                    setState(() {
                                      loading = false;
                                    });

                                    await storage.write(
                                        key: "tel", value: widget.tel);

                                    Navigator.pushNamedAndRemoveUntil(context,
                                        'indexLogin', (route) => false);
                                  }
                                  if (response.statusCode == 400 &&
                                      response.body.contains("username")) {
                                    setState(() {
                                      loading = false;
                                    });
                                    showToast(
                                      getTranslated(context,
                                          "user with this username already exists"),
                                      textPadding: EdgeInsets.only(
                                          right: getProportionateScreenWidth(4),
                                          left: getProportionateScreenWidth(4)),
                                      context: context,
                                      position: StyledToastPosition.top,
                                      textStyle: maintextstyle.copyWith(
                                        fontSize:
                                            getProportionateScreenWidth(16),
                                      ),
                                      backgroundColor: Colors.red,
                                      animation:
                                          StyledToastAnimation.slideFromRight,
                                      reverseAnimation:
                                          StyledToastAnimation.slideFromRight,
                                      duration: Duration(seconds: 7),
                                      animDuration: Duration(milliseconds: 350),
                                      fullWidth: false,
                                      isHideKeyboard: false,
                                    );

                                  }
                                } catch (e) {
                                  setState(() {
                                    loading = false;
                                  });
                                  showToast(
                                    getTranslated(context, "nonetwork"),
                                    textPadding: EdgeInsets.only(
                                        right: getProportionateScreenWidth(4),
                                        left: getProportionateScreenWidth(4)),
                                    context: context,
                                    position: StyledToastPosition.top,
                                    textStyle: maintextstyle.copyWith(
                                      fontSize: getProportionateScreenWidth(16),
                                    ),
                                    backgroundColor: Colors.red,
                                    animation:
                                        StyledToastAnimation.slideFromRight,
                                    reverseAnimation:
                                        StyledToastAnimation.slideFromRight,
                                    duration: Duration(seconds: 7),
                                    animDuration: Duration(milliseconds: 350),
                                    fullWidth: false,
                                    isHideKeyboard: false,
                                  );
                                  // print(e);
                                }
                              },
                              color: pcolor,
                              child: Text(
                                getTranslated(context, "Accepter")!,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              )),
                        ],
                      ),
                spaceHeight(30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
