import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  bool isDark = false;
  String? _pressedBrand;
  List<String> favoriteBrands = [];
  bool _favoritesLoaded = false;

  // Keep initial alphabetical order
  final List<Map<String, String>> allBrands = [
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
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('favoriteBrands');
    setState(() {
      favoriteBrands = saved ?? [];
      _favoritesLoaded = true; // Set to true when loaded
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteBrands', favoriteBrands);
  }

  @override
Widget build(BuildContext context) {
  final Color topBottomBarColor = isDark ? Colors.grey[850]! : const Color(0xFFE9DFCC);
  final Color bodyBackgroundColor = isDark ? Colors.grey[900]! : const Color(0xFFF5EFE6);
  final Color brandTextColor = isDark ? const Color(0xFFdcc66e) : const Color(0xFF4E3E14);
  final Color headerTextColor = isDark ? const Color(0xFFdcc66e) : Colors.black;
  final Color dividerColor = isDark ? Colors.grey[700]! : const Color(0xFF4E3E14);

  final favoriteBrandMaps = favoriteBrands
      .map((fav) => allBrands.firstWhere((b) => b['name'] == fav, orElse: () => {}))
      .where((b) => b.isNotEmpty)
      .toList();

  final nonFavoriteBrandMaps = allBrands
      .where((b) => !favoriteBrands.contains(b['name']))
      .toList()
    ..sort((a, b) => a['name']!.compareTo(b['name']!));

  final displayBrands = [...favoriteBrandMaps, ...nonFavoriteBrandMaps];

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
            setState(() => isDark = !isDark);
          },
        ),
      ],
    ),
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: !_favoritesLoaded
          ? const SizedBox.shrink()//const Center(child: CircularProgressIndicator())
          : ListView.builder(
              key: const ValueKey('brandList'), // Ensures switcher animates
              itemCount: displayBrands.length,
              itemBuilder: (context, index) {
                final brand = displayBrands[index];
                final isFavorite = favoriteBrands.contains(brand['name']);
                final logoPath = 'assets/${isDark ? 'dark_mode' : 'light_mode'}/${brand['logo']}';

                return KeyedSubtree(
                  key: ValueKey(brand['name']),
                  child: InkWell(
                    splashColor: dividerColor.withOpacity(0.2),
                    onTap: () {},
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
                          trailing: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () async {
                                setState(() {
                                  _pressedBrand = brand['name'];
                                });

                                await Future.delayed(const Duration(milliseconds: 150));

                                setState(() {
                                  _pressedBrand = null;
                                  if (isFavorite) {
                                    favoriteBrands.remove(brand['name']);
                                  } else {
                                    favoriteBrands.add(brand['name']!);
                                  }
                                });

                                await _saveFavorites();
                              },
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 150),
                                scale: _pressedBrand == brand['name'] ? 1.2 : 1.0,
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: brandTextColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(height: 1, color: dividerColor),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
  );
}
}