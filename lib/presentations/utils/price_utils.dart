import 'package:flutter/material.dart';

/// Formate un montant avec un séparateur de milliers (espace), en conservant
/// les décimales éventuelles. Retourne une chaîne vide si [raw] est `null`
/// ou n'est pas un nombre valide (dans ce cas la valeur brute est renvoyée).
String formatAmount(String? raw) {
  if (raw == null) return '';
  final value = double.tryParse(raw);
  if (value == null) return raw;

  final isWhole = value == value.roundToDouble();
  final numberStr = isWhole ? value.toInt().toString() : value.toStringAsFixed(2);
  final parts = numberStr.split('.');
  final intPart = parts[0];

  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(intPart[i]);
  }
  if (parts.length > 1) buffer.write(',${parts[1]}');
  return buffer.toString();
}

/// Affiche un montant (chiffres + devise, ex. « 17 000 MRU/mois ») en forçant
/// le sens gauche-à-droite : dans un contexte arabe (RTL), l'algorithme bidi
/// peut sinon réordonner les chiffres et le symbole monétaire de façon
/// illisible. Le widget garde l'alignement du parent, seul le rendu interne
/// des caractères est forcé en LTR.
class PriceText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Segment additionnel accolé à [text] dans un style différent (ex. le
  /// « /mois » d'un prix, affiché en plus petit et plus clair). Reste dans
  /// le même bloc forcé en LTR que [text], donc pas de risque de réordre.
  final String? suffix;
  final TextStyle? suffixStyle;

  const PriceText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.suffix,
    this.suffixStyle,
  });

  static final _hasDigit = RegExp(r'[0-9]');

  @override
  Widget build(BuildContext context) {
    final hasSuffix = suffix != null && suffix!.isNotEmpty;

    final textWidget = hasSuffix
        ? RichText(
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.clip,
            textAlign: textAlign ?? TextAlign.start,
            text: TextSpan(
              style: style ?? DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: text),
                TextSpan(text: suffix, style: suffixStyle),
              ],
            ),
          )
        : Text(
            text,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
          );

    // Un texte sans chiffre (ex. "Prix sur demande") n'a pas besoin d'être
    // forcé en LTR — ça casserait son alignement naturel en arabe.
    if (!_hasDigit.hasMatch(text)) return textWidget;

    return Directionality(textDirection: TextDirection.ltr, child: textWidget);
  }
}
