import 'package:flutter/material.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {

  final List<Map<String, String>> brands = [
    {'name': 'Adidas', 'logo': 'assets/Adidas_logo_light.png'},
    {'name': 'Air Jordan', 'logo': 'assets/Jordan_logo_light.png'},
    {'name': 'Converse', 'logo': 'assets/Converse_logo_light.png'},
    {'name': 'Lacoste', 'logo': 'assets/Lacoste_logo_light.png'},
    {'name': 'Nike', 'logo': 'assets/Nike_logo_light.png'},
    {'name': 'Puma', 'logo': 'assets/Puma_logo_light.png'},
    {'name': 'Skechers', 'logo': 'assets/Skechers_logo_light.png'},
    {'name': 'Under Armour', 'logo': 'assets/Under_Armour_logo_light.png'},
    {'name': 'Vans', 'logo': 'assets/Vans_logo_light.png'},
  ];

  @override
  Widget build(BuildContext context) {
    const Color topBottomBarColor = Color(0xFFE9DFCC); // Darker beige
    const Color bodyBackgroundColor = Color(0xFFF5EFE6); // Lighter beige
    const Color brandTextColor = Color(0xFF4E3E14);
    const Color dividerColor = Color(0xFF4E3E14);

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: AppBar(
        backgroundColor: topBottomBarColor,
        elevation: 0,
        title: const Text(
          'BRANDS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return InkWell(
            onTap: () {
              // Handle tap
            },
            splashColor: dividerColor.withOpacity(0.2),
            child: Column(
              children: [
                ListTile(
                  leading: Image.asset(brand['logo']!, width: 40, height: 40),
                  title: Text(
                    brand['name']!,
                    style: const TextStyle(
                      color: brandTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.favorite_border, color: brandTextColor),
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
