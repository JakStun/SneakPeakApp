import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'create_listing.dart';
import 'all_listings.dart';
import 'listing_details_screen.dart';
import '/services/user_key_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<dynamic> listings = [];
  bool isLoading = false;
  bool showAllListings = false;
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
      final uri = Uri.parse('http://80.211.202.178:8000/my-listings');
      final response = await http.get(uri, headers: {
        'X-User-Nanoid': userNanoid,
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          listings = List.from(jsonResponse['listings']);
          listings.sort((a, b) => b['created_at'].compareTo(a['created_at']));
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

  Widget _buildListingsSection() {
    final hasReviews = _hasReviews();
    final displayListings =
        (hasReviews && !showAllListings) ? listings.take(3).toList() : listings;

    if (displayListings.isEmpty) {
      return const Center(child: Text("No listings created yet."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "LATEST LISTINGS:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...displayListings.map((item) => GestureDetector(
          onTap: () async {
            final shouldReload = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailsScreen(
                  listing: item,
                  onDelete: () {
                    // Optionally reload listings after delete
                    _loadInventory();
                  },
                ),
              ),
            );
            if (shouldReload == true) {
              _loadInventory(); // if returned from edit or delete
            }
          }, 
          child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    item['image_paths'].isNotEmpty
                        ? Image.network(
                            item['image_paths'][0],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported, size: 80),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                "${item['price']} ${item['price_currency']}",
                                style: const TextStyle(
                                    fontSize: 15.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Size: ${item['size']} | State: ${item['item_condition']} | Packaging: ${item['packaging']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ),
        ),
        if (_shouldShowToggleButton)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllListingsScreen(listings: listings),
                ),
              );
            },
            child: const Text("Show All"),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final List<Map<String, String>> mockReviews = [
      {"user": "Alice", "review": "Great seller!"},
      {"user": "Bob", "review": "Quick shipping, item as described."},
    ];

    if (mockReviews.isEmpty) {
      return const SizedBox.shrink(); // No reviews
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "USER REVIEWS:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxReviewHeight = MediaQuery.of(context).size.height * 0.5;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxReviewHeight,
              ),
              child: ListView.builder(
                itemCount: mockReviews.length,
                itemBuilder: (context, index) {
                  final review = mockReviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(review['user']!),
                      subtitle: Text(review['review']!),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  bool _hasReviews() {
  // Later this can be dynamic - now check mocks
    return false; //mockReviews.isNotEmpty -> for now false, reviews are just a concept
  }

  bool get _shouldShowToggleButton {
    return _hasReviews() && listings.length > 3;
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF5EFE6);
    const Color appBarColor = Color(0xFFE9DFCC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text(
          'YOUR STORE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 34,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildListingsSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (_hasReviews()) SliverToBoxAdapter(child: _buildReviewsSection()),
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
            _loadInventory(); // Refresh listings

            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF8B6B29),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Listing uploaded successfully",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Listing"),
      ),
    );
  }
}
