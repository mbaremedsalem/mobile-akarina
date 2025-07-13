import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class TopSkeleton extends StatefulWidget {
  const TopSkeleton({super.key, this.heidht, this.item});

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
  const Immobilierkeleton({super.key, this.heidht, this.item});

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


class ImmobilierCategorykeleton extends StatelessWidget {
  final double? height;
  final int? item;
  const ImmobilierCategorykeleton({super.key, this.height, this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: item ?? 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: kgrey300,
              highlightColor: kWhiteColor,
              child: _skeletonCard(),
            ),
          );
        },
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey[400],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Container(
                  height: 14,
                  width: 120,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                // Badge
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Container(
                  height: 10,
                  width: 180,
                  color: Colors.grey[350],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 140,
                  color: Colors.grey[350],
                ),
                const SizedBox(height: 12),
                // Rating et prix
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 40,
                      color: Colors.grey[350],
                    ),
                    const Spacer(),
                    Container(
                      height: 14,
                      width: 60,
                      color: Colors.grey[350],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





class CategorySkeleton extends StatefulWidget {
  final double? height;
  final int? item;

  const CategorySkeleton({super.key, this.height, this.item});

  @override
  _CategorySkeletonState createState() => _CategorySkeletonState();
}

class _CategorySkeletonState extends State<CategorySkeleton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

class ImmobilierDetailSkeleton extends StatelessWidget {
  const ImmobilierDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kgrey300,
      highlightColor: kWhiteColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image principale
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            // Titre
            Container(
              height: 22,
              width: 220,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 10),
            // Adresse
            Container(
              height: 16,
              width: 160,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 20),
            // Caractéristiques en grille (6 items, 3 colonnes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 colonnes
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Plusieurs paragraphes de description
            ...List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 12,
                width: double.infinity,
                color: Colors.grey[350],
              ),
            )),
            const SizedBox(height: 24),
            // Deux boutons d'action skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    color: Colors.grey[350],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 44,
                    color: Colors.grey[350],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}