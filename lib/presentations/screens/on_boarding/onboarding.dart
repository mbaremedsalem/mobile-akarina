import 'package:akarina/presentations/components/default_button.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:akarina/size_config.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../data/localization/language_constants.dart';



class BoardingModel
{
  late final String image;
  late final String title;
  late final String body;

  BoardingModel({
    required this.image,
    required this.title,
    required this.body,
  });
}

class Onboarding extends StatefulWidget {
   const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  var boardController = PageController();

 
  bool isLast = false;

  @override
  Widget build(BuildContext context) {

  List<BoardingModel> boarding =
  [
    BoardingModel(
      image: 'assets/images/image1.png',
      title: getTranslated(context, 'Choose maison')!,
      body: getTranslated(context, 'Find your best house  from popular allocation without any delay')!,
    ),
    BoardingModel(
      image: 'assets/images/image2.png',
      title: getTranslated(context, 'Make Payment')!,
      body: getTranslated(context, 'There are many payment options available for ease')!,
    ),
    BoardingModel(
      image: 'assets/images/image3.png',
      title: getTranslated(context, 'Get Your Commands')!,
      body: getTranslated(context,'Your demande despatch within one business day delivered at you')!,
    ),
  ];
  
  
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        actions:[
          TextButton(
              onPressed: ()
              {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));

              }, 
              child:  Text(
            getTranslated(context, 'SKIP')!,
            style: const TextStyle(
              color: pcolor,
            ),
          ),),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                controller: boardController,
                onPageChanged: (int index)
                {
                  if(index == boarding.length - 1)
                  {
                    setState((){
                      isLast = true;
                    });

                  }else
                  {
                    setState((){
                      isLast = false;
                    });
                  }
                },
                itemBuilder: (context,index) => buildBoardingItem(boarding[index]) ,
              itemCount: boarding.length,

              ),
            ),
            Expanded(
              child: SmoothPageIndicator(
                    controller: boardController,
                    effect: const ExpandingDotsEffect(
                      dotColor: Colors.grey,
                      dotHeight: 10,
                      activeDotColor: pcolor,
                      expansionFactor: 2,
                      dotWidth: 10,
                      spacing: 2,
                    ),
                    count: boarding.length,
                  ),
               ),
              SizedBox(
               height: getProportionateScreenHeight(20),
               ), 
               isLast?
               Defaultbutton(
                      height: getProportionateScreenHeight(45),
                      text: getTranslated(context, 'Get Started')!,
                      borderRadius: getProportionateScreenWidth(5),
                      width: getProportionateScreenWidth(500),
                      onTap: () async {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
                      },
                      color: pcolor,
                      textcolor: kWhiteColor,
                    ):Container(),
          ]
          ,
        ),
      ),
    );
  }

  Widget buildBoardingItem(BoardingModel model) => Column(
    children: [
      Expanded(
        child: Center(
          child: SizedBox(
            width: getProportionateScreenWidth(400), // Définissez la largeur de l'image
            height: getProportionateScreenHeight(200), 
            child: Image(
              image:AssetImage(model.image),
              fit: BoxFit.cover, // Ajustez l'image pour couvrir tout l'espace

            ),
          ),
        ),
      ),
      Center(
        child: Text(
          model.title,
          style: const TextStyle(
            fontSize: 24,
            color: pcolor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      Center(
        child: Text(
          model.body,
          style:  TextStyle(
            fontSize: 14,
            color: kgrey600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

    ],
  );
}
