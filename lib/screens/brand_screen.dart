import 'package:flutter/material.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  bool isDark = false;
  String? _pressedBrand;
  final Set<String> favoriteBrands = {};

  final List<Map<String, String>> brands = [
    {'name': 'Adidas', 'logo': 'Adidas_logo.webp'},
    {'name': 'Air Jordan', 'logo': 'Air_Jordan_logo.webp'},
    {'name': 'Converse', 'logo': 'Converse_logo.webp'},
    {'name': 'DC_Shoes', 'logo': 'DC_shoes_logo.webp'},
    {'name': 'Lacoste', 'logo': 'Lacoste_logo.webp'},
    {'name': 'Nike', 'logo': 'Nike_logo.webp'},
    {'name': 'Puma', 'logo': 'Puma_logo.webp'},
    {'name': 'Skechers', 'logo': 'Skechers_logo.webp'},
    {'name': 'Under Armour', 'logo': 'Under_Armour_logo.webp'},
    {'name': 'Vans', 'logo': 'Vans_logo.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    // THEME COLORS
    final Color topBottomBarColor = isDark ? Colors.grey[850]! : const Color(0xFFE9DFCC);
    final Color bodyBackgroundColor = isDark ? Colors.grey[900]! : const Color(0xFFF5EFE6);
    final Color brandTextColor = isDark ? Colors.white : const Color(0xFF4E3E14);
    final Color headerTextColor = isDark ? Colors.white : Colors.black;
    final Color dividerColor = isDark ? Colors.grey[700]! : const Color(0xFF4E3E14);

    // SORTED BRANDS LIST
    final sortedBrands = [...brands];
    sortedBrands.sort((a, b) {
      final aFav = favoriteBrands.contains(a['name']);
      final bFav = favoriteBrands.contains(b['name']);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: AppBar(
        backgroundColor: topBottomBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'BRANDS',
          style: TextStyle(
            color: headerTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny,
              color: headerTextColor,
            ),
            onPressed: () {
              setState(() {
                isDark = !isDark;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: sortedBrands.length,
        itemBuilder: (context, index) {
          final brand = sortedBrands[index];
          final isFavorite = favoriteBrands.contains(brand['name']);
          final logoPath = 'assets/${isDark ? 'dark_mode' : 'light_mode'}/${brand['logo']}';

          return InkWell(
            onTap: () {},
            splashColor: dividerColor.withOpacity(0.2),
            child: Column(
              children: [
                ListTile(
                  leading: Image.asset(logoPath, width: 40, height: 40),
                  title: Text(
                    brand['name']!,
                    style: TextStyle(
                      color: brandTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _pressedBrand = brand['name'];
                      });
                    },
                    onTapUp: (_) async {
                      if (!mounted) return;
                      setState(() {
                        _pressedBrand = null;
                      });

                      await Future.delayed(const Duration(milliseconds: 150));

                      if (!mounted) return;  // Check again before calling setState
                      setState(() {
                        if (isFavorite) {
                          favoriteBrands.remove(brand['name']);
                        } else {
                          favoriteBrands.add(brand['name']!);
                        }
                      });

                      await Future.delayed(const Duration(seconds: 2));
                      if (!mounted) return; // And again here before setState
                      setState(() {}); // trigger rebuild & sorting
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: _pressedBrand == brand['name'] ? 1.2 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _pressedBrand == brand['name']
                              ? [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : brandTextColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: dividerColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}