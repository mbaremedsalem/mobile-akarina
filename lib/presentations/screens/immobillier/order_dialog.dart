import 'dart:convert';

import 'package:akarina/data/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;


class OrderDialog extends StatefulWidget {
  final int immobilierId;
  final Map<String, dynamic>? immobilierData;
  final String? merchantCode;

  const OrderDialog({
    super.key,
    required this.immobilierId,
    this.immobilierData,
    this.merchantCode = '023977',
  });

  @override
  State<OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<OrderDialog> {
  // Contrôleurs
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dateDebutController = TextEditingController();
  final TextEditingController dateFinController = TextEditingController();
  final TextEditingController ebankilyPhoneController = TextEditingController();
  final TextEditingController ebankilyPasscodeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Contrôleurs pour SEDDAD
  final TextEditingController seddadNomController = TextEditingController();
  final TextEditingController seddadPrenomController = TextEditingController();
  final TextEditingController seddadTelephoneController = TextEditingController();

  // État
  String selectedPaymentMethod = 'reception';
  bool isLoading = false;
  bool showBankilyInstructions = false;
  bool showSeddadInstructions = false;
  bool showPaymentDetails = false;
  double? montantTotal;
  double montantBankily = 0;
  Map<String, dynamic>? reservationResponse;
  Map<String, dynamic>? paymentDetails;

  // Méthodes de paiement
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'reception',
      'name': 'reception',
      'nameAr': 'الدفع عند الاستلام',
      'description': 'reception_desc',
      'descriptionAr': 'ادفع عند استلام العقار',
      'icon': Icons.delivery_dining,
      'color': Colors.green,
    },
    {
      'id': 'ebankily',
      'name': 'ebankily',
      'nameAr': 'بانكيلي',
      'description': 'ebankily_desc',
      'descriptionAr': 'الدفع عبر بانكيلي',
      'icon': Icons.payment,
      'color': Colors.blue,
      'enabled': false, // ❌ Désactivé
    },
    {
      'id': 'seddad',
      'name': 'seddad',
      'nameAr': 'سداد',
      'description': 'seddad_desc',
      'descriptionAr': 'الدفع عبر سداد',
      'icon': Icons.payment,
      'color': Colors.orange,
      'enabled': false, // ❌ Désactivé
    },
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    dateDebutController.text = DateFormat('yyyy-MM-dd').format(now);
    dateFinController.text = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));
    _calculateAmounts();
  }

  void _calculateAmounts() {
    try {
      if (widget.immobilierData == null) {
        throw Exception('Données immobilier manquantes');
      }

      final operationType = widget.immobilierData?['operation']?['type']?.toString()?.toLowerCase();
      final isLocation = operationType == 'louer' || operationType == 'alouer';

      if (isLocation) {
        dynamic loyer;
        
        if (widget.immobilierData?['residentiel'] is Map) {
          loyer = widget.immobilierData?['residentiel']?['loyer_mensuel'];
        }
        
        if (loyer == null) {
          loyer = widget.immobilierData?['loyer_mensuel'];
        }
        
        if (loyer == null) {
          loyer = widget.immobilierData?['prix_location'];
        }

        final montantLocation = double.tryParse('$loyer') ?? 0.0;

        final start = DateTime.tryParse(dateDebutController.text) ?? DateTime.now();
        final end = DateTime.tryParse(dateFinController.text) ?? start.add(const Duration(days: 30));
        final months = (end.difference(start).inDays / 30).ceil().clamp(1, 120);
        
        montantTotal = montantLocation * months;
      } else {
        dynamic montant;
        
        if (widget.immobilierData?['residentiel'] is Map) {
          montant = widget.immobilierData?['residentiel']?['montant'];
        }
        
        if (montant == null) {
          montant = widget.immobilierData?['montant'];
        }
        
        if (montant == null) {
          montant = widget.immobilierData?['prix'];
        }

        montantTotal = double.tryParse('$montant') ?? 0.0;
      }

      montantBankily = (montantTotal ?? 0);

    } catch (e, stackTrace) {
      montantTotal = 0;
      montantBankily = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Directionality(
        textDirection: getAppTextDirection(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslated(context, "reservation_title")!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            getTranslated(context, "reservation_subtitle")!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showPaymentDetails && reservationResponse != null) 
                        _buildReservationSuccess(context),
                      
                      if (!showPaymentDetails) ...[
                        _buildPropertyInfo(context),
                        const SizedBox(height: 20),
                        _buildDateInputs(context),
                        const SizedBox(height: 20),
                        _buildClientInfo(context),
                        const SizedBox(height: 20),
                        Text(
                          getTranslated(context, "payment_method")!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...paymentMethods.map((method) => _buildPaymentMethodTile(context, method)),
                        if (selectedPaymentMethod == 'ebankily' && showBankilyInstructions)
                          _buildBankilyInstructions(context),
                        if (selectedPaymentMethod == 'seddad' && showSeddadInstructions)
                          _buildSeddadInstructions(context),
                        if (selectedPaymentMethod == 'ebankily' && widget.merchantCode != null)
                          _buildBankilyFields(context),
                        if (selectedPaymentMethod == 'seddad')
                          _buildSeddadFields(context),
                      ],
                    ],
                  ),
                ),
              ),

              // Buttons
              if (!showPaymentDetails) _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, "property_info")!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${getTranslated(context, "id")!}: ${widget.immobilierId}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (widget.immobilierData != null) ...[
            const SizedBox(height: 4),
            Text(
              "${getTranslated(context, "address")!}: ${widget.immobilierData!['adresse'] ?? 'N/A'}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${getTranslated(context, "type")!}: ${widget.immobilierData!['operation']?['type'] ?? widget.immobilierData!['residentiel']?['type_operation'] ?? 'N/A'}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (montantTotal != null) ...[
              const SizedBox(height: 4),
              Text(
                "${getTranslated(context, "amount")!}: ${montantTotal!.toStringAsFixed(0)} MRU",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDateInputs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "reservation_period")!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: dateDebutController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, "start_date")!,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                readOnly: true,
                onTap: () => _selectDate(context, dateDebutController),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: dateFinController,
                decoration: InputDecoration(
                  labelText: getTranslated(context, "end_date")!,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                readOnly: true,
                onTap: () => _selectDate(context, dateFinController),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, "your_info")!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "full_name")!,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: getTranslated(context, "phone_number")!,
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "notes_optional")!,
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(BuildContext context, Map<String, dynamic> method) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isEnabled = method['enabled'] ?? true;
    final methodColor = isEnabled ? method['color'] : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: AbsorbPointer(
          absorbing: !isEnabled,
          child: RadioListTile<String>(
            value: method['id'],
            groupValue: selectedPaymentMethod,
            onChanged: isEnabled ? (value) {
              setState(() {
                selectedPaymentMethod = value!;
                showBankilyInstructions = false;
                showSeddadInstructions = false;
              });
            } : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isArabic ? method['nameAr'] : getTranslated(context, method['name'])!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          getTranslated(context, "soon") ?? "Bientôt",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic ? method['descriptionAr'] : getTranslated(context, method['description'])!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? Colors.grey[600] : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'],
                color: methodColor,
                size: 20,
              ),
            ),
            activeColor: methodColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: selectedPaymentMethod == method['id']
                ? methodColor.withOpacity(0.05)
                : Colors.grey.shade50.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
    
  
  Widget _buildBankilyInstructions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getTranslated(context, "bankily_instructions")!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            getTranslated(context, "merchant_code")!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    widget.merchantCode ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.blue),
                onPressed: () {
                  if (widget.merchantCode != null) {
                    Clipboard.setData(ClipboardData(text: widget.merchantCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getTranslated(context, "code_copied")!),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "1. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "bankily_step1")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "2. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "bankily_step2")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "3. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "bankily_step3")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "4. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "bankily_step4")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "5. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: "${getTranslated(context, "bankily_step5")!} ${montantBankily.toStringAsFixed(0)} MRU",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "6. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "bankily_step6")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "7. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "bankily_step7")!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeddadInstructions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getTranslated(context, "seddad_instructions")!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "1. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "seddad_step1")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "2. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "seddad_step2")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "3. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "seddad_step3")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "4. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "seddad_step4")!,
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "5. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: "${getTranslated(context, "seddad_step5")!} ${montantBankily.toStringAsFixed(0)} MRU",
                ),
                const TextSpan(text: "\n"),
                TextSpan(
                  text: "6. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: getTranslated(context, "seddad_step6")!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankilyFields(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextField(
          controller: ebankilyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: getTranslated(context, "bankily_phone")!,
            prefixIcon: const Icon(Icons.phone_android),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ebankilyPasscodeController,
          keyboardType: TextInputType.number,
          obscureText: false,
          decoration: InputDecoration(
            labelText: getTranslated(context, "bankily_passcode")!,
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildSeddadFields(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          getTranslated(context, "your_info")!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: seddadNomController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Nom")!,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: seddadPrenomController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "prenom")!,
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: seddadTelephoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: getTranslated(context, "telephone")!,
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationSuccess(BuildContext context) {
    final reservation = reservationResponse?['reservation'];
    final payment = reservationResponse?['payment_details'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                reservationResponse?['message'] ?? getTranslated(context, "reservation_confirmed")!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${getTranslated(context, "reservation_number")!}: ${reservation?['id'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "${getTranslated(context, "status")!}: ${reservation?['statut'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "${getTranslated(context, "total_amount")!}: ${reservation?['montant_total'] ?? ''} MRU",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "${getTranslated(context, "payment_method")!}: ${payment?['method'] ?? reservation?['moyen_paiement'] ?? ''}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          
          if (payment?['transaction_id'] != null) ...[
            const SizedBox(height: 8),
            Text(
              "${getTranslated(context, "transaction_id")!}: ${payment?['transaction_id'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          
          if (payment?['code_paiement'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${getTranslated(context, "payment_code")!}: ${payment?['code_paiement'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payment?['code_paiement'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getTranslated(context, "code_copied")!),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          
          if (payment?['message'] != null) ...[
            const SizedBox(height: 16),
            Text(
              payment?['message'] ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Text(
                getTranslated(context, "cancel")!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading 
              ? null 
              : () {
                  if (selectedPaymentMethod == 'ebankily' && !showBankilyInstructions) {
                    setState(() {
                      showBankilyInstructions = true;
                    });
                  } else if (selectedPaymentMethod == 'seddad' && !showSeddadInstructions) {
                    setState(() {
                      showSeddadInstructions = true;
                    });
                  } else {
                    _showPasswordDialog();
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      (selectedPaymentMethod == 'ebankily' && !showBankilyInstructions) ||
                      (selectedPaymentMethod == 'seddad' && !showSeddadInstructions)
                          ? getTranslated(context, "confirm")!
                          : getTranslated(context, "confirm")!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateAmounts();
      });
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final fieldWidth = (screenWidth * 0.13).clamp(40.0, 60.0);
        
        return AlertDialog(
          title: Center(child: Text(getTranslated(context, "password")!)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getTranslated(context, "enter_password_to_confirm")!),
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                length: 4,
                obscureText: true,
                animationType: AnimationType.none,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: fieldWidth,
                  fieldWidth: fieldWidth,
                  activeFillColor: Colors.white,
                  activeColor: Theme.of(context).primaryColor,
                  selectedColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.grey.shade300,
                ),
                onCompleted: (pin) {
                  Navigator.pop(context);
                  _submitReservation(password: pin);
                },
                onChanged: (value) {
                  passwordController.text = value;
                },
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: Text(getTranslated(context, "cancel")!),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (passwordController.text.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(getTranslated(context, "pin_4_digits_required")!),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _submitReservation(password: passwordController.text);
                    },
                    child: Text(getTranslated(context, "confirm")!),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


Future<void> _submitReservation({String? password}) async {
  // [Validation existante...]
  
  setState(() {
    isLoading = true;
  });

  try {
    final storage = const FlutterSecureStorage();
    final String? token = await storage.read(key: "access");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "session_expired")!),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Construction de la requête
    final Map<String, dynamic> requestBody = {
      'immobilier_id': widget.immobilierId,
      'password': password,
      'moyen_paiement': selectedPaymentMethod,
      'date_debut': dateDebutController.text,
      'date_fin': dateFinController.text,
      'montant_total': montantBankily.toStringAsFixed(0),
    };

    // Ajout des champs spécifiques
    if (selectedPaymentMethod == 'seddad') {
      requestBody['nom_payeur'] = seddadNomController.text;
      requestBody['prenom_payeur'] = seddadPrenomController.text;
      requestBody['telephone_payeur'] = seddadTelephoneController.text;
      requestBody['remarque'] = notesController.text.isNotEmpty 
          ? notesController.text 
          : "Paiement pour réservation";
    } else if (selectedPaymentMethod == 'ebankily') {
      requestBody['ebankily_phone'] = ebankilyPhoneController.text;
      requestBody['ebankily_passcode'] = ebankilyPasscodeController.text;
      requestBody['notes'] = notesController.text;
    } else {
      requestBody['notes'] = notesController.text;
    }

    // DEBUG: Afficher la requête COMPLÈTE
    final response = await http.post(
      Uri.parse('https://akarina.online/akareena/reservations/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    // AFFICHER LA RÉPONSE COMPLÈTE (SUCCÈS OU ERREUR)
    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // Vérifier si la réponse contient une erreur même avec status 200
      if (responseData['success'] == false) {
        
        throw Exception(responseData['message'] ?? 'Erreur inconnue de l\'API');
      }
      
      setState(() {
        reservationResponse = responseData;
        paymentDetails = responseData['payment_details'];
        showPaymentDetails = true;
        isLoading = false;
      });

      await _updateImmobilierStatus(false);
      _showSuccessDialog(responseData);

    } else {

      
      String responseBody = response.body;
      Map<String, dynamic>? errorData;
      
      try {
        errorData = jsonDecode(responseBody);

      } catch (e) {

      }

      setState(() {
        isLoading = false;
      });

      String errorMessage = 'Erreur HTTP ${response.statusCode}';
      
      // Extraction du message d'erreur
      if (errorData != null) {
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        } else if (errorData['detail'] != null) {
          errorMessage = errorData['detail'];
        } else if (errorData['non_field_errors'] != null) {
          errorMessage = errorData['non_field_errors'].toString();
        }
      } else {
        errorMessage = responseBody;
      }

      // Afficher l'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Copier',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Status: ${response.statusCode}\nError: $errorMessage\nBody: ${response.body}'));
            },
          ),
        ),
      );

      // Afficher aussi une alerte dialog avec l'erreur complète
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur Détaillée'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${response.statusCode}'),
                const SizedBox(height: 10),
                Text('Message: $errorMessage'),
                const SizedBox(height: 10),
                const Text('Réponse complète:'),
                Text(response.body, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'Status: ${response.statusCode}\nError: $errorMessage\nBody: ${response.body}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur copiée!')),
                );
              },
              child: const Text('Copier'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });

    // ERREUR DE RÉSEAU OU AUTRE EXCEPTION

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur: ${e.toString()}"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
void _showSuccessDialog(Map<String, dynamic> responseData) {
  final reservation = responseData['reservation'];
  final payment = responseData['payment_details'];
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(getTranslated(context, "Réservation Confirmée")!),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${getTranslated(context, "reservation_number")!}: ${reservation?['id']}'),
              Text('${getTranslated(context, "status")!}: ${reservation?['statut']}'),
              Text('${getTranslated(context, "total_amount")!}: ${reservation?['montant_total']} MRU'),
              
              if (payment?['code_paiement'] != null) ...[
                const SizedBox(height: 16),
                 Text(getTranslated(context, "Code de paiement SEDDAD:")!, style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(payment!['code_paiement'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: payment['code_paiement']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Fermer aussi le dialog de réservation
            },
            child:  Text(getTranslated(context, "Fermer")!),
          ),
        ],
      );
    },
  );
}

  Future<void> _updateImmobilierStatus(bool available) async {
    try {
      final storage = const FlutterSecureStorage();
      final String? token = await storage.read(key: "access");

      if (token == null) return;

      await http.patch(
        Uri.parse('https://akarina.online/akareena/imobiers/${widget.immobilierId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'available': available,
        }),
      );
    } catch (e) {
      debugPrint("Erreur mise à jour statut immobilier: $e");
    }
  }
}


