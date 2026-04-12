import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget defaultInputField({
  required TextEditingController controller,
  bool isPassword = false,
  bool isClickable = true,
  double height = 40,  // Réduction de la hauteur
  required TextInputType type,
  Function(String)? onSubmit,
  Function? onTap,
  required String text,
  IconData? prefix,
  IconData? suffix,  // L'icône suffix est désormais obligatoire
  Function? suffixFunction,
  String textForUnValid = 'This element is required',
  Color? backgroundColor = Colors.white, // Couleur de fond par défaut
  Color borderColor = Colors.grey,  // Couleur de la bordure
  double borderRadius = 8.0,  // Rayon de la bordure
}) =>
    Container(
      height: height,  // Utilisation de la hauteur définie
      decoration: const BoxDecoration(),
      child: TextFormField(
        enableSuggestions: true,
        autocorrect: true,
        controller: controller,
        enabled: isClickable,
        onTap: onTap != null ? () => onTap() : null,
        validator: (value) {
          if (value!.isEmpty) {
            return textForUnValid;
          }
          return null;
        },
        onChanged: (value) {
          if (suffixFunction != null) {
            suffixFunction();
          }
        },
        onFieldSubmitted: (value) {
          if (onSubmit != null) {
            onSubmit(value);
          }
        },
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          
          labelText: text,
          prefixIcon: Icon(prefix),
          suffixIcon: IconButton(
            onPressed: () {
              if (suffixFunction != null) {
                suffixFunction();
              }
            },
            icon: Icon(suffix),
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),  // Réduction du padding
          
          // Ajout d'une bordure personnalisée
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: pcolor,  // Couleur de la bordure
              width: 1.5,  // Épaisseur de la bordure
            ),
          ),
          
          // Style de la bordure quand le champ est actif (focus)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: pcolor,  // Couleur de la bordure quand le champ est en focus
              width: 2.0,
            ),
          ),
          
          // Style de la bordure quand le champ est désactivé
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );









Widget defaultInputField1({
  required TextEditingController controller,
  bool isPassword = false,
  bool isClickable = true,
  double height = 53,
  required TextInputType type,
  Function(String)? onSubmit,
  Function? onTap,
  required String text,
  IconData? prefix,
  IconData? suffix,
  Function? suffixFunction,
  String textForUnValid = 'This element is required',
  Color? backgroundColor = kWhiteColor,
  Color borderColor = Colors.transparent,
  double borderRadius = 10.0, 
  String? hintText,
  int? maxLength,
  String? Function(String?)? customValidator,
  List<TextInputFormatter>? inputFormatters,
}) =>
    Container(
      height: height,
      decoration: const BoxDecoration(),
      child: TextFormField(
        enableSuggestions: true,
        autocorrect: true,
        controller: controller,
        enabled: isClickable,
        onTap: onTap != null ? () => onTap() : null,
        validator: (value) {
          // D'abord le validateur personnalisé s'il existe
          if (customValidator != null) {
            final customResult = customValidator(value);
            if (customResult != null) return customResult;
          }
          
          // Ensuite la validation de base
          if (value!.isEmpty) {
            return textForUnValid;
          }
          return null;
        },
        onChanged: (value) {
          // SUPPRIMER l'appel à suffixFunction ici
          // Ne rien mettre ou mettre une autre logique si nécessaire
        },
        onFieldSubmitted: (value) {
          if (onSubmit != null) {
            onSubmit(value);
          }
        },
        maxLength: maxLength,
        obscureText: isPassword,
        keyboardType: type,
        inputFormatters: inputFormatters,
        // Ajouter cette propriété pour éviter la réduction de hauteur
        buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) => null,
        decoration: InputDecoration(
          labelText: text,
          labelStyle: TextStyle(color: kgrey400),
          prefixIcon: prefix != null
              ? Icon(prefix, color: pcolor)
              : null,
          suffixIcon: suffix != null
              ? IconButton(
                  onPressed: () {
                    if (suffixFunction != null) {
                      suffixFunction();
                    }
                  },
                  icon: Icon(suffix, color: kgrey400),
                )
              : null,
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: pcolor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: pcolor,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor,
              width: 1.5,
            ),
          ),
          // Pour gérer l'affichage du compteur si maxLength est défini
          counterText: '',
        ),
      ),
    );

