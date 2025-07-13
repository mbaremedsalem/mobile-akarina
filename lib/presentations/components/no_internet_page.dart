import 'package:flutter/material.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/size_config.dart';

class NoInternetPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NoInternetPage({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône d'erreur de connexion
                Container(
                  width: getProportionateScreenWidth(120),
                  height: getProportionateScreenWidth(120),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: getProportionateScreenWidth(60),
                    color: Colors.red[400],
                  ),
                ),
                
                SizedBox(height: getProportionateScreenHeight(30)),
                
                // Titre principal
                Text(
                  getTranslated(context, "Connexion faible")!,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: getProportionateScreenHeight(15)),
                
                // Message descriptif
                Text(
                  customMessage ?? getTranslated(context, "Vérifiez votre connexion internet et réessayez")!,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16),
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: getProportionateScreenHeight(40)),
                
                // Bouton de réessai
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pcolor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(30),
                        vertical: getProportionateScreenHeight(15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(getProportionateScreenWidth(12)),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: getProportionateScreenWidth(20),
                    ),
                    label: Text(
                      getTranslated(context, "Réessayer")!,
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                
                SizedBox(height: getProportionateScreenHeight(20)),
                
                // Conseils de dépannage
                Container(
                  padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(getProportionateScreenWidth(12)),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue[600],
                            size: getProportionateScreenWidth(20),
                          ),
                          SizedBox(width: getProportionateScreenWidth(8)),
                          Text(
                            getTranslated(context, "Conseils de dépannage")!,
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(16),
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(12)),
                      _buildTipItem(
                        context,
                        Icons.wifi,
                        getTranslated(context, "Vérifiez que votre WiFi est activé")!,
                      ),
                      SizedBox(height: getProportionateScreenHeight(8)),
                      _buildTipItem(
                        context,
                        Icons.signal_cellular_alt,
                        getTranslated(context, "Vérifiez votre connexion mobile")!,
                      ),
                      SizedBox(height: getProportionateScreenHeight(8)),
                      _buildTipItem(
                        context,
                        Icons.router,
                        getTranslated(context, "Redémarrez votre routeur")!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: getProportionateScreenWidth(16),
          color: Colors.blue[600],
        ),
        SizedBox(width: getProportionateScreenWidth(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
} 