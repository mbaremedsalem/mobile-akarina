import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

// Example primary color (replace with your actual color)

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  int _currentStep = 0; // Track current step
  String? selectedOtpMethod;
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController nniController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _timer;
  int _remainingTime = 30; // 30 seconds for OTP expiration

  void startTimer() {
    if (_timer != null) _timer!.cancel();
    _remainingTime = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          timer.cancel(); // Stop the timer
        }
      });
    });
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/svg/logo.svg',
                      width: 180,
                      height: 180,
                    ),
                  ),
                  
                  Theme(
                    data: ThemeData(
                      colorScheme: ColorScheme.light(primary: pcolor),
                    ),
                    child: Stepper(
                      currentStep: _currentStep,
                      onStepTapped: (step) => setState(() => _currentStep = step),
                      onStepContinue: () {
                        if (_currentStep == 1 && _formKey.currentState!.validate()) {
                          startTimer(); // Start OTP timer
                        }
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          // Handle registration submission
                          if (_formKey.currentState!.validate()) {
                            // Perform the registration logic
                            print("Registering user...");
                          }
                        }
                      },
                      onStepCancel: _currentStep == 0
                          ? null
                          : () => setState(() => _currentStep--),
                      steps: _buildSteps(),
                      controlsBuilder: (context, details) {
                        return Row(
                          children: [
                        Defaultbutton(
                            onTap: () {
                         
                            },
                            color: pcolor,
                            textcolor: kWhiteColor,
                            text: getTranslated(context, 'Continuer')!,
                            borderRadius: getProportionateScreenWidth(5),
                            width: getProportionateScreenWidth(90),
                            height: getProportionateScreenHeight(35),
                          ),
                            TextButton(
                              onPressed: details.onStepCancel,
                              style: TextButton.styleFrom(
                                // foregroundColor: pcolor, // Use pcolor for cancel button
                              ),
                              child: const Text("Cancel"),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build the steps for the Stepper
  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text("Phone Number"),
        content: Column(
          children: [
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              validator: (value) =>
                  value!.isEmpty ? "Please enter your phone number" : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedOtpMethod,
              decoration: const InputDecoration(labelText: "OTP Method"),
              items: const [
                DropdownMenuItem(value: "phone", child: Text("Phone")),
                DropdownMenuItem(value: "email", child: Text("Email")),
              ],
              onChanged: (value) => setState(() => selectedOtpMethod = value),
              validator: (value) =>
                  value == null ? "Please select an OTP method" : null,
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text("OTP Verification"),
        content: Column(
          children: [
            TextFormField(
              controller: otpController,
              decoration: const InputDecoration(labelText: "Enter OTP"),
              validator: (value) =>
                  value!.isEmpty ? "Please enter the OTP" : null,
            ),
            const SizedBox(height: 10),
            Text("Expires in: $_remainingTime seconds"),
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text("Final Details"),
        content: Column(
          children: [
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: "Full Name"),
              validator: (value) =>
                  value!.isEmpty ? "Please enter your full name" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              validator: (value) =>
                  value!.isEmpty ? "Please enter a password" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: nniController,
              decoration: const InputDecoration(labelText: "NNI"),
              validator: (value) =>
                  value!.isEmpty ? "Please enter your NNI" : null,
            ),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep == 2 ? StepState.indexed : StepState.complete,
      ),
    ];
  }
}
