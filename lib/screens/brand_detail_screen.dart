import 'package:flutter/material.dart';

class BrandDetailScreen extends StatelessWidget {
  final String brandName;

  const BrandDetailScreen({super.key, required this.brandName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(brandName),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Brand details coming soon!'),
      ),
    );
  }
}