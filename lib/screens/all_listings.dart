import 'package:flutter/material.dart';

class AllListingsScreen extends StatelessWidget {
  final List<dynamic> listings;

  const AllListingsScreen({super.key, required this.listings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ALL LISTINGS"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final item = listings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  item['image_paths'].isNotEmpty
                      ? Image.network(
                          'https://jakstun.github.io/imgs/SneakPeak_icon.png',
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
                                style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              "${item['price']} ${item['price_currency']}",
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
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
          );
        },
      ),
    );
  }
}