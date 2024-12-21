import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:flutter/material.dart';


class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return  SafeArea(child: 
    SingleChildScrollView(
      child: Column(
        children: [
        Center(
          child: Column(
            children: [
            const Text('Profile',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10,),
            Container(
              height: 100,
              child:  Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius:60,
                    backgroundImage:  NetworkImage('https://t4.ftcdn.net/jpg/03/03/11/75/360_F_303117590_NNmo6BS2fOBEmDp8uKs2maYmt03t8fSL.jpg'), 
                    ),
                    Container(
                    height: 40,
                    width: 50,
                      child: InkWell(
                        onTap: (){},
                        child: const Icon(IconBroken.Camera)))
                ],
              ),
            ),
           const SizedBox(height: 10,),
            const Text('M\'bare Mohamed Salem',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),
            ),
           const SizedBox(height: 10,),
            Padding(
             padding: const EdgeInsets.all(15.0),
             child: SingleChildScrollView(
               child: Column(
                 children: [
                   const Row(
                    children: [
                      Icon(IconBroken.User),
                      SizedBox(width: 20,),
                      Text('My Account'),
                      Spacer(),
                      Icon(IconBroken.Arrow___Right),
                    ],
                   ),
                   const SizedBox(height: 10,),
                   Container(
                    height: 1,
                    color: kgrey400,
                   ),
                   const SizedBox(height: 16,),
                  const Row(
                    children: [
                      Icon(IconBroken.Lock),
                      SizedBox(width: 20,),
                      Text('My Order'),
                      Spacer(),
                      Icon(IconBroken.Arrow___Right),
                    ],
                   ),
                   const SizedBox(height: 10,),
                   Container(
                    height: 1,
                    color: kgrey400,
                   ),
                  const SizedBox(height: 16,),
                  const Row(
                    children: [
                      Icon(IconBroken.Home),
                      SizedBox(width: 20,),
                      Text('My Address'),
                      Spacer(),
                      Icon(IconBroken.Arrow___Right),
                    ],
                   ),
                   const SizedBox(height: 10,),
                   Container(
                    height: 1,
                    color: kgrey400,
                   ),
               
                  const SizedBox(height: 16,),
                  const Row(
                    children: [
                      Icon(IconBroken.Paper),
                      SizedBox(width: 20,),
                      Text('Payment Methode'),
                      Spacer(),
                      Icon(IconBroken.Arrow___Right),
                    ],
                   ),
                   const SizedBox(height: 10,),
                   Container(
                    height: 1,
                    color: kgrey400,
                   ),
                  const SizedBox(height: 16,),
                  const Row(
                    children: [
                      Icon(IconBroken.Heart),
                      SizedBox(width: 20,),
                      Text('My Wishlist'),
                      Spacer(),
                      Icon(IconBroken.Arrow___Right),
                    ],
                   ),
                   const SizedBox(height: 10,),
                   Container(
                    height: 1,
                    color: kgrey400,
                   ),
                  const SizedBox(height: 16,),
                  const Row(
                    children: [
                      Icon(IconBroken.Setting),
                      SizedBox(width: 20,),
                      Text('Account Setting'),
                      Spacer(),
                      Icon(IconBroken.Arrow___Right),
                    ],
                   ),
                   const SizedBox(height: 10,),
                   Container(
                    height: 1,
                    color: kgrey400,
                   ),
                  const SizedBox(height: 16,),
                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                    },
                    child: const Row(
                      children: [
                        Icon(IconBroken.Logout),
                        SizedBox(width: 20,),
                        Text('Logout'),
                        Spacer(),
                        Icon(IconBroken.Arrow___Right),
                      ],
                     ),
                  ),
               
                 ],
               ),
             ),
           )
          ],
          ),
        )
        ]
      ),
    )
    );
  }
}