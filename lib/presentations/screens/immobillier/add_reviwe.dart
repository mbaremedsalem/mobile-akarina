import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';

class AddReviewDialog extends StatefulWidget {
  final Function(int rating, String comment) onSubmit;

  const AddReviewDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int selectedRating = 0;
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTranslated(context, "Ajouter un avis")!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Sélection de la note
            Text(
              getTranslated(context, "Votre note")!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                  child: Icon(
                    Icons.star,
                    size: 40,
                    color: index < selectedRating
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Champ de commentaire
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: getTranslated(context, "Votre commentaire")!,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(getTranslated(context, "Annuler")!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedRating > 0
                        ? () {
                            widget.onSubmit(
                                selectedRating, commentController.text);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pcolor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(getTranslated(context, "Envoyer")!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
