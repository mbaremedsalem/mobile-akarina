import 'dart:io';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/services.dart';
import 'package:akarina/presentations/components/showToast.dart';
import 'package:akarina/presentations/components/spiner.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TermAutre extends StatefulWidget {
  const TermAutre({
    this.password,
    this.tel,
    this.nni,
    this.prenom,
    this.nom,
    this.photoIdentite,
    this.photoVisage,
    this.photoIdentiteVerso,
  });

  final String? password;
  final String? tel;
  final String? prenom;
  final String? nom;
  final String? nni;
  final File? photoVisage;
  final File? photoIdentite;
  final File? photoIdentiteVerso;

  @override
  _TermAutreState createState() => _TermAutreState();
}

class _TermAutreState extends State<TermAutre> {
  final storage = FlutterSecureStorage();

  String? langue;
  String? pays;

  void fetchinfo() async {
    Mylocalstorage().getStringValue("country").then((value) => setState(() {
          pays = value;
        }));
  }

  @override
  void initState() {
    super.initState();
    fetchinfo();
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
                  "Les présentes conditions générales d’utilisation ci-après les « CGU » ont pour objet de définir les modalités d’utilisation du service «BCIP@Y», proposé par la Banque pour le Commerce et l’Industrie-Guinée SA (BCI-Guinée SA), ayant sonsiège social au 6ème Avenu de la République, Immeuble BCI, Sandervalia, Kaloum ; BP : 359, Conakry, immatriculée au Registre du Commerce et du Crédit Mobilier de ladite ville sous le numéro GC-KAL/034.718 A/2011, conformément aux dispositions de la réglementation en vigueur.",
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
                  "« La Banque » : désigne Banque pour le Commerce et l’Industrie Guinée SA",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Conditions Générales » : désigne le présent document.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Service » : désigne le service mobile de la BCI « BCIP@Y ».",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« BCIP@Y » est la solution de mobile Banking de la Banque Pour Le commerce Et L’industrie qui permet une ouverture de compte à distance et la réalisation d’unensemble d’opérations bancaires.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Le Client » ou « utilisateur » « donneur d’ordre » désigne toute personne titulaire d'un compte bancaire ouvert à la Banque Pour Le commerce et l’industrie ayant souscrit auservice mobile de la Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Bénéficiaire » : fait référence à la personne que vous désignez pour recevoir les fonds provenant du transfert d'argent via BCIP@Y.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les mots « vous » et « votre » font référence à la personne qui accepte les termes et conditions du présent Contrat.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Les mots « nous » et « notre » désignent « la banque »",
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
                spaceHeight(8),
                Text(
                  "« Code PIN » : code personnel et secret à quatre (4) chiffres unique et spécifique, choisi par le Client lors de la procédure d’activation de son compte sur son téléphone mobile.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« SMS » : désigne un service de messages courts se composant d'un message texte.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Transaction (s)» : les opérations disponibles et effectuées via le service BCIP@Y.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Force Majeure » : a le sens défini par le droit commun et consiste notamment en tout évènement imprévisible, irrésistible et hors du contrôle d’une Partie agissant de façon diligente et professionnelle et qui affecte de façon significative l’exécution de ses obligations dans le cadre des présentes.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "« Période d’indisponibilité » : désigne la période pendant laquelle le système BCIP@Y n’est pas disponible pour effectuer les Transactions relatives au Service.",
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
                  "L'acte d'enregistrement et d'utilisation de l'Application BCIP@Y signifie que vous consentez expressément d'être lié par le présent Contrat. Si vous n'êtes pas d'accord sur les termes et conditions du présent Contrat énoncés ci-dessous, veuillez ne pas accéder à l’Application BCIP@Y.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Lesdites conditions affectent vos droits et il en va de votre responsabilité de les lire attentivement. En accédant et en utilisant l’Application BCIP@Y, vous acceptez les termes et conditions du présent Contrat",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "La souscription par le Client au service BCIP@Y par USSD et/ou le téléchargement de l’Application mobile BCIP@Y impliquent l’acceptation des présentes Conditions Générales d’Utilisation. Celles-ci pourront être modifiées au besoin par la Banque, lorsque nécessaire. La poursuite de l’utilisation du service BCIP@Y après la modification des présentes Conditions Générales d’Utilisation sera considérée comme une acceptation tacite des changements apportés par la Banque.",
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
                  "Le Client ne peut bénéficier des services qui lui sont proposés que sous réserve de son acceptation des présentes Conditions Générales et après la validation de son numéro de téléphone personnel et de son Numéro National d’Identification (NNI) qui permet de l’identifier conformément à la législation en vigueur.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Un Compte est ouvert dans les livres de la Banque après acceptation des présentes Conditions Générales.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque se réserve le droit de modifier, à tout moment, son application en fonction de l'évolution de la technologie et de la réglementation en vigueur.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Client déclare avoir pris connaissance de la part de la Banque toutes les informations nécessaires quant aux services proposés et accepte sans réserve aux présentes Conditions Générales.",
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
                  "L’accès au Service est également lié à l’acceptation du dossier de connaissance du client (KYC) : les Clients qui ont ouvert leurs comptes à distance ne peuvent effectuer les transactions proposées dans le cadre du Service « BCIP@Y ».",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Afin d’accéder à l’ensemble des services « BCIP@Y » les clients ayant ouverts des comptes à distance doivent se présenter aux guichets d’une des agences de la Banque ou à l’un de ses agents afin de s’identifier, présenter leurs pièces d’identité, fournir quelques informations exigées par la réglementation en vigueur et signer une convention d’ouverture de compte. La Banque se réserve le droit de modifier, à tout moment, les plafonds définis dans le cadre du Service.",
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
                  "Le compte doit accuser un solde créditeur permettant les retraits, paiements et transferts (frais compris) dans la limite du solde disponible.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En application de la réglementation en vigueur, la Banque ne conserve les documents comptables relatifs aux opérations enregistrées sur le compte que pendant 10 ans.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le Service est lié à un numéro de téléphone et un appareil unique, identifiés lors de l’entrée en relation.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Le changement du numéro de téléphone requiert l’accès au numéro de téléphone initial sur lequel un code de confirmation sera transmis par sms. Le changement ne peut se faire que par la banque et en présentiel du client.",
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
                  "Les Conditions Générales figurant en ligne sur le site www.bci-banque.com prévalent sur toute version imprimée de date antérieure.",
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
                  "Le compte du client peut être bloqué par voie de saisie-arrêt ou saisie conservatoire notifiées à la Banque par exploit d’huissier ou par voie d’avis au tiers détenteur (ATD) notifié par le Trésor Public ou la Direction Générale des Impôts pour les créances fiscales. Dans ces cas de figure la Banque d'informer le Client pour lui permettre de contester la mesure de saisie ou ATD et éventuellement obtenir une mainlevée. Suivant la loi des finances de 2024, la Banque est obligée à se conformer aux prescriptions aux actes de saisie et /ou ATD en cantonnant le montant dans le délai prescrit par la loi.",
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
                  "L’utilisation du Service BCI@P est subordonnée à l’identification de chaque Client sur présentation d’une pièce d’identité en cours de validité. Vous acceptez de fournir des informations complètes et précises dans le cadre de la procédure d'inscription et vous acceptez également de mettre à jour cette information de manière raisonnable ou nécessaire pour garder des informations complètes et exactes en tout temps.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "L’utilisation du Service BCIP@Y vous est consentie sous réserve de notre capacité à vérifier suffisamment votre identité. Si vous ne fournissez pas des informations exactes et complètes lors de votre inscription, lorsque vous demandez un paiement de transfert mobile ou lors d’opération de dépôt ou de retrait, nous avons le droit de vous interdire d'utiliser le Service BCIP@Y ou de refuser de traiter la demande de service. En outre, nous attirons votre plus grande attention sur le fait que si vous ne fournissez pas des informations exactes et complètes lors de l'inscription ou lors d'une demande de transfert, vous pouvez provoquer des erreurs dans vos transferts mobiles demandés.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
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
                spaceHeight(8),
                Text(
                  "Chaque fois que vous accédez au Service BCIP@Y, vous reconnaissez avoir confirmé l'exactitude et l'exhaustivité de toutes les informations d'inscription fournies à Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "La Banque se réserve le droit d'établir des exigences d'identification et de vérification spécifiques pour un Bénéficiaire afin qu’il puisse recevoir les fonds provenant d'un transfert d'argent mobile, sous réserve du respect de vos droits et de ceux du ou des Bénéficiaires en matière de protection des données personnelles et dans les limites autorisées par la réglementation en vigueur en matière de lutte contre la corruption, le blanchiment de capitaux et le financement du terrorisme. Vous acceptez expressément que la Banque peut se fonder de bonne foi, sans autre enquête, sur des informations d'identification ou sur la documentation fournie par vous ou un Bénéficiaire, y compris tout code ou identifiant de numéro du transfert d'argent mobile, lors d'un versement de fonds au Bénéficiaire. Vous reconnaissez et acceptez que la Banque a le droit de refuser de livrer le paiement au Bénéficiaire si la Banque ne peut pas vérifier suffisamment l'identité du Bénéficiaire. Dès lors qu’il est clairement spécifié dans le présent Contrat que la Banque a le droit d'établir des exigences d'identification et de vérification spécifiques, l'incapacité du Bénéficiaire de se conformer auxdites exigences fournit une raison à la Banque de refuser à bon droit la délivrance du transfert d'argent mobile.",
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
                  "La souscription au Service Mobile BCIP@Y permet au Client de :",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Effectuer, à partir de son compte « BCIP@Y », des opérations bancaires vers des comptes Banque pour le commerce et l’industrie et des comptes d’autres banques installées en Guinée.",
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
                  "	•	Effectuer des retraits d’espèces au niveau des agences de la Banque, de son réseau d’agents.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Effectuer des versements d’espèces sur le compte BCIP@Y au niveau des agences de la Banque et de son réseau d’agents.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Régler des factures fournisseurs et commerçants",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Paiements de certains services publics (impôt, taxe, ...).",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	Acheter des recharges téléphoniques.",
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
                spaceHeight(10),
                Text(
                  "Pour gérer votre argent en toute sécurité, il y a des limites transactionnelles et quotidiennes sur votre compte BCIP@Y. Ces limites sont conformes aux réglementations en vigueur. Ces limites peuvent évoluer suivant le volume d’activité et la réglementation. Vous pouvez accéder aux fonds disponibles dans votre compte à tout moment en utilisant le code USSD (*140#) ou l'Application Mobile BCIP@Y disponible sur playstore et Appstore. Vous devez autoriser vos transactions avec votre code PIN secret que vous créez lorsque vous vous inscrivez, ou par toute autre méthode que nous pouvons prescrire de temps à autre. Le solde de votre compte ne peut à aucun moment dépasser votre limite de compte mobile.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Vous acceptez de payer le montant des frais de transfert d'argent et d'autres charges pour chaque transfert initié ou demandé dans l’Application BCIP@Y. En demandant un transfert d'argent mobile, vous autorisez la Banque à débiter votre compte mobile pour le montant du transfert demandé et les frais de service applicables. Vous comprenez et reconnaissez que la Banque n’a aucune obligation de traiter ou d'effectuer un transfert demandé si la Banque est empêchée pour une raison quelconque d’obtenir les fonds de votre compte pour le montant du transfert demandé et des frais.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Nonobstant ce qui précède, la Banque peut suspendre, retarder ou rejeter votre demande de transfert d'argent mobile :",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	si la valeur d'une ou de plusieurs de vos demandes de transfert d'argent mobile dépasse toutes les limites de transfert établies pour les services de la Banque ;",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	si la Banque est incapable de charger votre portefeuille mobile pour le montant du transfert d'argent mobile demandé et les frais connexes ;",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	si votre demande est incomplète ou imprécise ;",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	si la Banque est incapable de confirmer votre identité ou vérifier toute information d'enregistrement ou ceux d'un Bénéficiaire, y compris son identité ;",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	si la Banque a une certaine suspicion de fraude ou d'irrégularité ou d’illégalité concernant la transaction demandée ;",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	si la Banque et / ou ses distributeurs agréés ne sont pas en mesure de répondre à votre demande pour une raison quelconque ; ou",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "	•	pour toute autre raison que la Banque, à sa seule discrétion, juge appropriée ou nécessaire.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Disponibilité de l’Application mobile BCIP@Y",
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
                  "Le code USSD et l’Application mobile BCIP@Y sont disponibles 24 heures par jour, 7 jours par semaine, 365 jours par an. En règle générale, votre Bénéficiaire désigné est payé instantanément grâce à l'Application mobile BCIP@Y. Si jamais il y a une situation où votre transaction n’est pas délivrée instantanément au Bénéficiaire désigné, nous vous contacterons pour vous tenir informé au sujet du retard.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Vous acceptez que la Banque ne sera pas responsable de tout retard, défaut d'exécution, ou d’erreur dans l'exécution de votre demande de transfert d'argent mobile en raison de circonstances insurmontables et indépendantes de la volonté de la Banque, qu'elle soit causée par les grèves, les pannes de courant, dysfonctionnement de l'équipement, des actes ou des omissions d'une banque intermédiaire, la guerre, les émeutes, les prescriptions gouvernementales ou judiciaires, arrêts de travail ou des événements ou des circonstances similaires. Vous acceptez également que la Banque peut refuser de traiter ou retarder le traitement de toute demande si elle est contraire à toute ligne directrice, règle, politique ou règlement des autorités de régulation et / ou gouvernementales et de tout système de transfert de fond.",
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
                spaceHeight(8),
                Text(
                  "Vous déclarez et garantissez que toutes les informations que vous entrez dans l’Application BCIP@Y concernant le Transfert d’argent mobile sont exactes et complètes. Lors du traitement des transferts mobile, la Banque se base sur les informations d'enregistrement et les informations de transfert d'argent mobile que vous fournissez. Vous reconnaissez que toute(s) erreur(s) ou omission(s) dans les informations, y compris une identification erronée du ou des Bénéficiaire (s), les erreurs et incohérences sur les numéros de compte sont de votre pleine et entière responsabilité et que la Banque n'aura aucune responsabilité pour l'exécution d'un transfert d'argent mobile sur la base d’informations inexactes ou incomplètes fournies ou saisies par l’Utilisateur.",
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
                  "Sachant qu’aucune opération ne peut être réalisée sur l’application en l’absence de connexion avec l’identifiant et le mot de passe du client, puis après validation, en seconde étape, de cette opération par une nouvelle saisie du même mot de passe, à titre de confirmation. La confirmation d’une Transaction par le mot de passe exonère irrévocablement et entièrement la Banque de toute responsabilité",
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
                  "Le client est le seul responsable de toute opération exécutée à partir de son espace personnel, en utilisant son identifiant, son mot de passe ou son code à usage unique. Toute utilisation de l'espace personnel et, en conséquence, toute opération réalisée à partir de cet espace, par l’usage de l'identifiant, du mot de passe ou du Code à usage unique attribués au Client est présumée être exécutée par ce dernier et sous sa seule responsabilité. Il assume, seul, l’entière responsabilité d’erreurs de manipulation par ses soins ou de divulgation par ses soins de ses mots de passe et codes à des tiers et il déclare qu’il décharge expressément la banque de toute responsabilité à cet égard.",
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
                  "Le Client est également responsable des informations qu’il fournit, à distance, à la Banque. La banque se réserve le droit d’entamer toute procédure judiciaire à l’encontre du Client dans le cas où celui-ci fournit de fausses déclarations pour l’accès à ses services. Si à tout moment vous croyez ou savez que votre téléphone mobile ou votre code PIN a été volé ou compromis, vous pouvez joindre notre centre de service à la clientèle par appel depuis n’importe quel numéro.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Nous bloquerons votre compte immédiatement. Vous serez responsable de toutes les Transactions qui se sont produites dans votre portefeuille électronique jusqu'à la date de blocage.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Si vous contestez que tout achat ou retrait débité sur votre portefeuille électronique a été autorisé par vous, vous devrez prouver qu'il n'a pas été autorisé par vos soins. Sauf erreur ou faute de nos services, nos dossiers seront considérés comme exacts sauf preuve contraire.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Procédure de résolution d’erreur et politique d’annulation",
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
                  "Vous avez le droit de contester les erreurs sur vos transactions. Il n'y a pas de frais pour ce service. Si vous pensez qu'il y a une erreur, contactez-nous et fournissez-nous votre nom, vos coordonnées, le nom du Bénéficiaire, la date du transfert, et la référence de l’opération, ainsi que les raisons selon lesquelles vous pensez qu'il y a eu une erreur. La banque déterminera si une erreur est survenue et vous répondra. Si la Banque était en faute, vous auriez droit à un remboursement complet ou un transfert renvoyé gratuitement. S’il n’y a aucune erreur ou si la Banque n'a pas été en faute, vous recevrez un avis écrit, y compris les informations que la banque a revues pour prendre cette décision.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En règle générale, parce que votre Bénéficiaire désigné est payé immédiatement après le traitement de votre transfert d'argent mobile, l'annulation de ce transfert et / ou un remboursement d'un transfert d'argent mobile précédemment réglé ne seront pas traitées et la Banque n'a aucune obligation d'honorer une telle demande. Si, pour une raison imprévue, votre Bénéficiaire désigné n'a pas été payé, vous pouvez nous contacter pour régularisation ou remboursement complet.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Lorsque vous recevez un transfert par erreur, vous reconnaissez que la Banque pourra annuler la transaction. Il est expressément convenu que la Banque ne saurait être tenue responsable pour toute perte résultant de son incapacité d'annuler ou de rembourser un transfert d'argent mobile lorsqu’aucune erreur ou faute n’a été commise par la Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Lorsque votre Bénéficiaire ne dispose pas de Compte BCIP@Y il reçoit alors un code secret de retrait par SMS.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Modifications.",
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
                  "La Banque se réserve le droit de modifier les termes et conditions contenues dans ce Contrat, en ajoutant ou en supprimant certaines dispositions entièrement ou partiellement, sans préavis, sauf si requis par la loi. Si nous choisissons de vous informer ou sommes requis par la loi de vous informer des modifications apportées aux présentes conditions générales d’utilisation, nous serons considérés comme ayant entièrement satisfait à cette obligation, sauf modalités spécifiques prévues par la loi applicable, en postant ou en remettant un avis ou un message électronique au dernier numéro de téléphone ou à la dernière adresse connue que nous détiendrons dans votre dossier.",
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
                  "Le présent Contrat est conclu pour une durée indéterminée et peut être résilié à tout moment par le Client.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
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
                  "Si votre compte reste inactif pendant une durée de Six (6) mois successifs, nous vous informerons que si aucune activité ne se produit au cours du mois suivant, nous pourrions être amenés à fermer votre compte. Si aucune activité subséquente n’a lieu en ce mois, le compte pourrait être clôturé à la seule discrétion de la Banque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Vous recevrez une notification pas SMS du solde après déduction des frais de clôture. Vous aurez droit au remboursement du solde de votre compte dans un délai qui ne pourra excéder jours (10) jours ouvrés suivant la date de fermeture.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "En cas de désabonnement du Service, la Banque se réserve le droit de procéder à la clôture du compte bancaire associé. Le clôture du compte doit être effectuée dans l’une des agences de la Banque, après prélèvement des frais en vigueur.",
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
                  "Communications électroniques",
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
                  "Pour utiliser l'Application BCIP@Y, vous consentez à recevoir et accepter les présentes conditions générales d’utilisation, leurs éventuels amendements, ainsi que tous les avis relatifs à l’Application BCIP@Y par voie de communication électronique. Au cas où tout changement à ces conditions générales d’utilisation exigerait un préavis, la Banque vous avertira par un message texte SMS ou e-mail, au numéro de téléphone ou adresse e-mail que vous avez fourni lors de l'inscription aux services BCIP@Y ou le numéro de téléphone ou l’adresse e-mail dernièrement communiqué, ou vous fournira un lien dans un message texte SMS ou par courriel où vous pouvez voir l'accord révisé ou modifié.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Un enregistrement de chaque paiement de transfert sera mis à votre disposition par la banque par voie de communication électronique sur l'Application mobile BCIP@Y. Vous reconnaissez et acceptez que dans le but d'utiliser l'Application USSD de BCIP@Y, vous devez avoir un téléphone mobile ; et pour utiliser l’Application mobile de BCIP@Y, vous devez avoir un téléphone mobile Android ou IOS. Vous convenez que si vous retirez votre consentement à recevoir des communications électroniques, la banque mettra fin à votre utilisation de l'Application BCIP@Y. Vous reconnaissez et acceptez que tous les messages et avis par courriel de texte SMS qui vous sont envoyés en ce qui concerne le statut des paiements de transfert mobile seront considérés comme document officiel de la Banque.",
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
                  "Utilisation des données personnelles ; Politique de confidentialité",
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
                  "Votre vie privée est très importante pour nous. La Banque s’engage à respecter dans le cadre de l’exécution du présent Contrat l’intégralité des dispositions légales applicables à la protection des données personnelles notamment celles relatives à la loi N° L/2016/037/AN , à ne pas louer, vendre ou partager vos données personnelles, sauf en conformité avec la politique utilisée par elle en la matière. La Banque reçoit vos informations grâce à divers sites Web, des Applications mobiles et des tiers (les « Services »). En acceptant ladite Politique de confidentialité et les Conditions d'utilisation, vous consentez à la collecte, le stockage, l'utilisation et la divulgation de vos informations personnelles comme décrit dans cette politique de confidentialité.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Nous recueillons des « données non personnelles » et des « données personnelles » pour fournir et mesurer l'utilisation de nos services et de les améliorer au fil du temps.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Informations collectées lors de l’enregistrement : Lorsque vous créez ou configurez un compte sur nos services, vous fournissez des informations personnelles, telles que votre nom, adresse e- mail, numéro de téléphone, et mot de passe. Vous pouvez modifier vos informations personnelles. En vous inscrivant, vous nous autorisez à collecter, stocker et utiliser ces données.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Vos données personnelles seront conservées pendant une période de dix (10) ans conformément aux dispositions légales réglementant la fourniture de nos services.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Partage d'information et divulgation",
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
                  "La Banque ne divulgue vos données privées que dans les circonstances décrites ci-dessous :",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Votre consentement : Nous pouvons partager ou communiquer vos renseignements avec votre consentement, comme lorsque vous utilisez une application Web d’une partie tierce pour accéder à votre compte sur nos services.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Prestataires de services / distributeurs : Nous engageons des agents tiers de confiance pour exécuter des fonctions et fournir des services pour nous. Nous pouvons partager vos informations personnelles avec ces tiers, mais seulement dans la mesure nécessaire pour remplir ces fonctions et fournir de tels services, et sous le respect d'obligations reflétant les protections de cette politique de confidentialité à savoir celles applicables en matière de protection des données personnelles.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Conservation ou divulgation obligatoire : Nous pouvons conserver ou divulguer vos informations si nous croyons qu'il est raisonnablement nécessaire de la faire ou sur instructions des autorités judiciaires, policières, et/ou de la BCRG pour se conformer à une loi, un règlement ou une demande légale ; pour protéger la sécurité de toute personne ; pour lutter contre la fraude ou le blanchiment d’argent, les questions sécuritaires ou techniques ; ou pour protéger les droits ou la propriété de la Baque.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Transferts de société : Si la Banque, ou la quasi-totalité de nos actifs sont acquis, ou dans le cas peu probable que la banque se retire des affaires ou fait faillite, les données personnelles des Clients seraient l'un des actifs qui sont transférables ou acquises par un tiers. Vous reconnaissez que ces transferts peuvent se produire, et que tout acquéreur de la Banque peut continuer à utiliser vos données personnelles selon la présente politique.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Informations non-privées ou non personnelles : Nous pouvons partager ou divulguer vos informations agrégées ou autrement non personnelles et non-privées, tels que le nombre d'utilisateurs qui ont cliqué sur un lien particulier.",
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
                  "Le présent contrat est régi par la loi guinéenne.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(8),
                Text(
                  "Tout litige portant sur l'interprétation ou l'exécution des présentes sera soumis à la compétence exclusive du Tribunal de Commerce de Conakry.",
                  style: maintextstyle.copyWith(
                    color: colorTextHigh,
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w400,
                  ),
                  textScaleFactor: 1.0,
                ),
                spaceHeight(12),
                Text(
                  "Accord Termes et Conditions.",
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
                  "En souscrivant au Service BCIP@Y, vous reconnaissez que vous avez lu, compris, accepté les termes des présentes Conditions Générales d’Utilisation.",
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
                                // Map body = {
                                //   "username": widget.tel,
                                //   "first_name": widget.prenom,
                                //   "last_name": widget.nom,
                                //   "password": widget.password,
                                //   "photo_visage": widget.photoVisage,
                                //   "photo_identite": widget.photoIdentite,
                                //   "nni": widget.nni,
                                //   "email": "",
                                //   "adresse": "",
                                //   "langue": getTranslated(context, "langue"),
                                // };
                                // print(datenaissance);
                                var url = Uri.parse(baseParPays(pays!) +
                                    "api/user/client_digiPay/register/");
                                try {
                                  http.MultipartRequest request =
                                      http.MultipartRequest('POST', url);
                                  request.headers['Content-Type'] =
                                      'application/json; charset=utf-8';

                                  request.fields['username'] = widget.tel!;
                                  request.fields['first_name'] = widget.prenom!;
                                  request.fields['last_name'] = widget.nom!;
                                  request.fields['password'] = widget.password!;
                                  request.fields['nni'] = widget.nni!;
                                  request.fields['email'] = '';
                                  request.fields['adresse'] = '';
                                  request.fields['langue'] =
                                      getTranslated(context, "langue")!;
                                  request.files.add(
                                      await http.MultipartFile.fromPath(
                                          'photo_visage',
                                          widget.photoVisage!.path));
                                  request.files.add(
                                      await http.MultipartFile.fromPath(
                                          'photo_identite',
                                          widget.photoIdentite!.path));
                                  request.files.add(
                                      await http.MultipartFile.fromPath(
                                          'photo_identite_verso',
                                          widget.photoIdentiteVerso!.path));
                                  var response = await http.Response.fromStream(
                                          await request.send())
                                      .timeout(const Duration(seconds: 120));

                                  // var response = await post(url,
                                  //         headers: {
                                  //           'Content-Type':
                                  //               'application/json; charset=utf-8'
                                  //         },
                                  //         body: jsonEncode(body))
                                  //     .timeout(Duration(seconds: 60));

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
                                    showToaster(
                                        context,
                                        getTranslated(context,
                                            "user with this username already exists"),
                                        kredcolor);
                                  }
                                } catch (e) {
                                  setState(() {
                                    loading = false;
                                  });
                                  showToaster(
                                      context,
                                      getTranslated(context, "nonetwork"),
                                      kredcolor);

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
                SizedBox(
                  height: getProportionateScreenHeight(30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
