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

class PropertyCardSkeleton extends StatelessWidget {
  final double? height;
  final int? rowCount;

  const PropertyCardSkeleton({
    super.key,
    this.height,
    this.rowCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = 12.0;
    final gap = 12.0;
    final cardWidth = (screenWidth - (padding * 2) - gap) / 2;
    
    // Calculer la hauteur pour que tout tienne sans scroll
    final cardHeight = height ?? (cardWidth * 1.4);
    final totalHeight = (cardHeight + gap) * (rowCount ?? 2);
    
    // Si la hauteur totale dépasse l'écran, réduire la hauteur des cartes
    final finalCardHeight = totalHeight > screenHeight 
        ? (screenHeight / (rowCount ?? 2)) - gap 
        : cardHeight;

    final locale = Localizations.localeOf(context).languageCode;
    final isRTL = locale == 'ar';

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            rowCount ?? 2,
            (rowIndex) => Padding(
              padding: EdgeInsets.only(bottom: rowIndex == (rowCount ?? 2) - 1 ? 0 : gap),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: finalCardHeight,
                    child: _buildCard(isRTL),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: finalCardHeight,
                    child: _buildCard(isRTL),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isRTL) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[350],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.home, size: 40, color: Colors.grey[400]),
                  ),
                  Positioned(
                    top: 8,
                    left: isRTL ? null : 8,
                    right: isRTL ? 8 : null,
                    child: _buildBadge(),
                  ),
                  Positioned(
                    top: 8,
                    right: isRTL ? null : 8,
                    left: isRTL ? 8 : null,
                    child: _buildBadge(small: true),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLine(80, 14),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isRTL) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                      ],
                      _buildLine(60, 12),
                      if (isRTL) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildLine(70, 16),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isRTL) ...[
                        ..._buildStars(),
                        const SizedBox(width: 6),
                        _buildLine(25, 12),
                      ],
                      if (isRTL) ...[
                        _buildLine(25, 12),
                        const SizedBox(width: 6),
                        ..._buildStars(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(small ? 4 : 8),
      ),
      child: Container(
        width: small ? 30 : 40,
        height: small ? 10 : 12,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildLine(double widthPercent, double height) {
    return Container(
      width: widthPercent,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[350],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  List<Widget> _buildStars() {
    return List.generate(
      5,
      (index) => Icon(
        Icons.star,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }
}
class _CategorySkeletonState extends State<CategorySkeleton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.white,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            2,
            (rowIndex) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (colIndex) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(
                        height: 53,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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