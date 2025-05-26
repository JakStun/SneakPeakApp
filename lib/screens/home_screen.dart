import 'package:flutter/material.dart';
import 'brand_screen.dart';
import 'marketplace_screen.dart';
import 'store_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _slectedIndex = 0;

  final List<Widget> _screens = [
    const BrandScreen(),
    const MarketplaceScreen(),
    const StoreScreen(),
    Center(child: Text('Favourites (coming soon)')),
  ];

  @override
  Widget build(BuildContext context) {
    const Color navBarColor = Color(0xFFE9DFCC); // Darker beige

    return Scaffold(
      body: _screens[_slectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _slectedIndex,
        backgroundColor: navBarColor,
        selectedItemColor: const Color(0xFF8B6B29), // Darker brown
        unselectedItemColor: const Color(0xFF4E3E14), // Darker brown
        onTap: (index) {
          setState(() {
            _slectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Brands',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Your Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
        ],
      ),
    );
  }  
}