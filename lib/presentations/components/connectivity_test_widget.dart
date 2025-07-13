import 'package:flutter/material.dart';
import 'package:akarina/data/services/connectivity_service.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/data/localization/language_constants.dart';

class ConnectivityTestWidget extends StatefulWidget {
  final Widget child;
  
  const ConnectivityTestWidget({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityTestWidget> createState() => _ConnectivityTestWidgetState();
}

class _ConnectivityTestWidgetState extends State<ConnectivityTestWidget> {
  bool hasInternetConnection = true;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    setState(() {
      isChecking = true;
    });

    final hasConnection = await ConnectivityService.hasInternetConnection();
    
    if (mounted) {
      setState(() {
        hasInternetConnection = hasConnection;
        isChecking = false;
      });
    }
  }

  Future<void> _retryConnection() async {
    await _checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
              const SizedBox(height: 20),
              Text(
                getTranslated(context, "Vérification de la connexion...")!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: _retryConnection,
        customMessage: getTranslated(context, "Impossible de se connecter au serveur. Vérifiez votre connexion internet.")!,
      );
    }

    return widget.child;
  }
} 