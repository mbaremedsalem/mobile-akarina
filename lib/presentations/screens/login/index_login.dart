import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:akarina/presentations/screens/register/register1.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import '../../../data/localization/language_constants.dart';

class IndexLogin extends StatefulWidget {
  const IndexLogin({super.key});

  @override
  State<IndexLogin> createState() => IndexLoginState();
}

class IndexLoginState extends State<IndexLogin> with SingleTickerProviderStateMixin {
  Widget _currentPage = const Login();
  List<Widget> _pageHistory = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  void changePage(Widget newPage) {
    _pageHistory.add(_currentPage);
    _animationController.reset();
    _animationController.forward();
    setState(() {
      _currentPage = newPage;
    });
  }

  void goBack() {
    if (_pageHistory.isNotEmpty) {
      final previousPage = _pageHistory.removeLast();
      _animationController.reset();
      _animationController.forward();
      setState(() {
        _currentPage = previousPage;
      });
    } else {
      changePage(const Login());
    }
  }

  bool _shouldShowBackButton() {
    if (_currentPage.runtimeType == Login) {
      return false;
    }
    return true;
  }

  String _getBackButtonText() {
    if (_currentPage.runtimeType == Register1Page) {
      return getTranslated(context, "Retourner") ?? "Retourner";
    }
    return getTranslated(context, "Retourner") ?? "Retourner";
  }

  String? pays;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  void fetch() async {
    String? t = await storage.read(key: "country");
    if (mounted) {
      setState(() {
        pays = t;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetch();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kgrey50,
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header avec animation
                if (_shouldShowBackButton())
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.2, 0),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: _buildModernBackButton(),
                        ),
                      ),
                    ),
                  ),
                
                // Logo animé
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(_fadeAnimation),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: getProportionateScreenHeight(_shouldShowBackButton() ? 20 : 50),
                        bottom: getProportionateScreenHeight(30),
                      ),
                      child: _buildAnimatedLogo(),
                    ),
                  ),
                ),
                
                // Divider avec animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          kgrey300,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contenu principal
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(_currentPage.runtimeType),
                      margin: const EdgeInsets.only(top: 8),
                      child: _currentPage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: goBack,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: kgrey200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: kBlackColor,
              ),
              const SizedBox(width: 6),
              Text(
                _getBackButtonText(),
                style: TextStyle(
                  fontSize: 14,
                  color: kBlackColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: getProportionateScreenWidth(90),
            height: getProportionateScreenHeight(90),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: pcolor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/icon.png',
                fit: BoxFit.cover,
                color: pcolor,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        );
      },
    );
  }
}