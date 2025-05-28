import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'create_listing.dart';
import '/services/user_key_service.dart';

enum MarketplaceTab { inventory, newOns, reviews}

class MarketplaceScreen extends StatefulWidget{
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  MarketplaceTab selectedTab = MarketplaceTab.inventory;
  List<dynamic> listings = [];

  bool isLoading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final userNanoid = await UserKeyChecker.getCreateUserKey();

    try {
      final uri = Uri.parse('http://80.211.202.178:8000/listings/v1/my-listings');
      // final uri = Uri.parse('http://127.0.0.1:8000/listings/v1/my-listings');
      final response = await http.get(uri, headers: {
        'X-User-Nanoid': userNanoid}
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          listings = jsonResponse['listings'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load listings: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildTabButton(String label, MarketplaceTab tab) {
    final bool isSelected = selectedTab == tab; 
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = tab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B6B29) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ),
    );
  }

  Widget _buildInventoryList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }

    if (listings.isEmpty) {
      return const Center(child: Text("No listings found."));
    }

    return ListView.builder(
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final item = listings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: item['image_paths'].isNotEmpty
                ? Image.network(
                    'https://jakstun.github.io/imgs/SneakPeak_icon.png',
                    width: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported),
            title: Text(item['title']),
            subtitle: Text("${item['price']} ${item['price_currency']}"),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (selectedTab) {
      case MarketplaceTab.inventory:
        return _buildInventoryList();
      case MarketplaceTab.newOns:
        return const Center(child: Text("Trending section coming soon."));
      case MarketplaceTab.reviews:
        return const Center(child: Text("Reviews section coming soon."));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF5EFE6); // Lighter beige
    const Color appBarColor = Color(0xFFE9DFCC); // Darker beige

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text(
          'MARKETPLACE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildTabButton("Inventory", MarketplaceTab.inventory),
                const SizedBox(width: 8),
                _buildTabButton("Trending", MarketplaceTab.newOns),
                const SizedBox(width: 8),
                _buildTabButton("Reviews", MarketplaceTab.reviews),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B6B29),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListing()),
          );

          if (result == true) {
            _loadInventory(); // Refresh the inventory after creating new listing
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Listing"),
      ),
    );
  }
}