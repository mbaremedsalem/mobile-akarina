import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class TopSkeleton extends StatefulWidget {
  TopSkeleton({this.heidht, this.item});

  final double? heidht;

  final int? item;
  @override
  _TopSkeletonState createState() => _TopSkeletonState();
}
class _TopSkeletonState extends State<TopSkeleton> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.item ?? 1,
        itemBuilder: (BuildContext ctx, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Shimmer.fromColors(
              baseColor: kgrey300,
              highlightColor: kWhiteColor,
              child: box(),
            ),
          );
        });
  }

  Widget box() {
    return Container(
      height: widget.heidht ?? 170,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7), color: Colors.grey[300]),
    );
  }
}


class Immobilierkeleton extends StatefulWidget {
  Immobilierkeleton({this.heidht, this.item});

  final double? heidht;

  final int? item;
  @override
  _ImmobilierkeletonState createState() => _ImmobilierkeletonState();
}



class _ImmobilierkeletonState extends State<Immobilierkeleton> {
  @override
  Widget build(BuildContext context) {
    return 
    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250, // Largeur max de chaque élément
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.65, // Ajustement du ratio hauteur/largeur
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                                  return Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: Shimmer.fromColors(
                                    baseColor: kgrey300,
                                    highlightColor: kWhiteColor,
                                    child: box(),
                                  ),
                                ); 
                        
                      },
                    );

  }

  Widget box() {
    return Container(
      height: widget.heidht ?? 170,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7), color: Colors.grey[300]),
    );
  }
}


class ImmobilierCategorykeleton extends StatefulWidget {
  ImmobilierCategorykeleton({this.heidht, this.item});

  final double? heidht;

  final int? item;
  @override
  _ImmobilierCategorykeletonState createState() => _ImmobilierCategorykeletonState();
}



class _ImmobilierCategorykeletonState extends State<ImmobilierCategorykeleton> {
  @override
  Widget build(BuildContext context) {
    return 
    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),

                      itemCount: 8,
                      itemBuilder: (context, index) {
                                  return Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: Shimmer.fromColors(
                                    baseColor: kgrey300,
                                    highlightColor: kWhiteColor,
                                    child: box(),
                                  ),
                                ); 
                        
                      },
                    );

  }

  Widget box() {
    return Container(
      height: widget.heidht ?? 170,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7), color: Colors.grey[300]),
    );
  }
}





class CategorySkeleton extends StatefulWidget {
  final double? height;
  final int? item;

  CategorySkeleton({this.height, this.item});

  @override
  _CategorySkeletonState createState() => _CategorySkeletonState();
}

class _CategorySkeletonState extends State<CategorySkeleton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 100, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.item ?? 8, 
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15,right: 5),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.white,
              child: box(),
            ),
          );
        },
      ),
    );
  }

  Widget box() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[300], // Couleur pour simuler le chargement
    );
  }
}