import 'package:camera_app_test2/screens/edit_listing_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';

import '../services/user_key_service.dart';

class ListingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onDelete;

  const ListingDetailsScreen({
    super.key,
    required this.listing,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(listing['image_paths'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(listing['title']),
        backgroundColor: const Color(0xFFE9DFCC),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditListingScreen(
                    listingData: listing, // pass listing data here
                  ),
                ),
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Listing'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirmed == true) {
                final listingId = listing['listing_id'];
                final userKey = await UserKeyChecker.getCreateUserKey(); // Make sure you store `user_key` in your listing map
                final uri = Uri.parse('http://80.211.202.178:8000/delete-listing');

                final response = await http.delete(uri, headers: {
                  "X-User-Nanoid": userKey,
                  "X-Listing-id": listingId
                });

                if (response.statusCode == 200) {
                  onDelete();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete listing')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openFullGallery(context, images, index),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("${listing['price']} ${listing['price_currency']}", style: const TextStyle(fontSize: 18, color: Colors.green)),
                const SizedBox(height: 12),
                Text("Brand: ${listing['brand']}"),
                Text("Size: ${listing['size']}"),
                Text("Condition: ${listing['item_condition']}"),
                Text("Packaging: ${listing['packaging']}"),
                const SizedBox(height: 12),
                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(listing['description']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: images.length,
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[index]),
                heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              pageController: PageController(initialPage: initialIndex),
              scrollPhysics: const BouncingScrollPhysics(),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
