import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/local_settings_service.dart';

class EditListingScreen extends StatefulWidget {
  final Map<String, dynamic> listingData;

  const EditListingScreen({super.key, required this.listingData});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  bool _isUploading = false;

  final List<File> _images = [];
  late List<String> _existingImageUrls; // for displaying remote images
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController descController;

  late String brand;
  late double size;
  late String condition;
  late String packaging;
  late String currency;

  @override
  void initState() {
    super.initState();
    final data = widget.listingData;

    titleController = TextEditingController(text: data['title']);
    priceController = TextEditingController(text: data['price'].toString());
    descController = TextEditingController(text: data['description'] ?? "");

    brand = data['brand'] ?? '';
    size = double.tryParse(data['size'].toString()) ?? 0;
    condition = data['item_condition'] ?? '';
    packaging = data['packaging'] ?? '';
    currency = data['price_currency'] ?? '\$';

    // _existingImageUrls.clear(); // Must be cleared, otherwise won't delete
    _existingImageUrls = List<String>.from(widget.listingData['image_paths'] ?? []); // must be like this otherwise it won't change later on
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length + _existingImageUrls.length >= 10) {
      _showLimitMessage("You can only upload up to 10 images.");
      return;
    }

    if (source == ImageSource.gallery) {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final availableSlots = 10 - _images.length - _existingImageUrls.length;
        final limitedFiles = pickedFiles.take(availableSlots).map((f) => File(f.path)).toList();

        setState(() {
          _images.addAll(limitedFiles);
        });

        if (pickedFiles.length > availableSlots) {
          _showLimitMessage("Only $availableSlots more image(s) allowed.");
        }

        _scrollToEnd();
      }
    } else {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLimitMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center)),
    );
  }

  void _showImagePreview(dynamic image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: image is File
                ? Image.file(image)
                : Image.network(image),
          ),
        ),
      ),
    );
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
      print("_existingImageUrls: $_existingImageUrls");
      if (_existingImageUrls.isEmpty && _images.isEmpty) {
        _showLimitMessage("Please include at least one image.");
      }
    });
  }

  Future<void> _updateListing() async {
    if (_existingImageUrls.isEmpty && _images.isEmpty) {
      _showLimitMessage("Please include at least one image.");
      return;
    }

    final String userKey = LocalSettingsService.userKey;
    final uri = Uri.parse("http://80.211.202.178:8000/listings/v1/edit-listing");
    // final uri = Uri.parse("http://127.0.0.1:8000/listings/v1/edit-listing");

    final request = http.MultipartRequest('POST', uri);

    request.headers['X-Listing-id'] = widget.listingData["listing_id"]; // make sure this is passed
    request.fields['title'] = titleController.text;
    request.fields['price'] = priceController.text;
    request.fields['price_currency'] = currency;
    request.fields['description'] = descController.text;
    request.fields['brand'] = brand;
    request.fields['size'] = size.toString();
    request.fields['item_condition'] = condition;
    request.fields['packaging'] = packaging;
    request.headers['X-User-Nanoid'] = userKey;

    // For now convert back to relative path, can't save as url in server
    String baseUrl = "http://80.211.202.178:8000/user-image/";
    // String baseUrl = "http://127.0.0.1:8000/user-image/";
    String toRelativePath(String url) {
      if (url.startsWith(baseUrl)) {
        final pathWithoutBase = url.substring(baseUrl.length); // "user_id/filename.jpg"
        final parts = pathWithoutBase.split('/');

        if (parts.length >= 2) {
          final userId = parts[0];
          final filename = parts.sublist(1).join('/');
          return "data/$userId/images/$filename";
        }
      }
      return url;
    }

    List<String> relativePaths = _existingImageUrls.map(toRelativePath).toList();

    request.fields['remaining_image_urls'] = json.encode(relativePaths);

    // Add image files only if present
    for (var imageFile in _images) {
      final fileStream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();

      request.files.add(http.MultipartFile(
        'images',
        fileStream,
        length,
        filename: imageFile.path.split("/").last,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    setState(() => _isUploading = true);

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        print("Listing updated: $respStr");

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        print("Update failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    titleController.dispose();
    priceController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("EDIT LISTING", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE9DFCC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _existingImageUrls.length + _images.length + 1,
                itemBuilder: (context, index) {
                  if (index < _existingImageUrls.length) {
                    final url = _existingImageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showImagePreview(url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: const CircleAvatar(
                                radius: 12, 
                                backgroundColor: Colors.black54, 
                                child: Icon(Icons.close, color: Colors.white, size: 16)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (index < _existingImageUrls.length + _images.length) {
                    final localIndex = index - _existingImageUrls.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showImagePreview(_images[localIndex]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_images[localIndex], width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(localIndex)),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 16)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () => _showImageSourceSelector(),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B6B29)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt, color: Color(0xFF8B6B29)),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: spacing),

            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: spacing),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: currency,
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text('\$')),
                      DropdownMenuItem(value: '€', child: Text('€')),
                    ],
                    onChanged: (val) => setState(() => currency = val!),
                    decoration: const InputDecoration(labelText: "Currency"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: spacing),

            TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: spacing),

            DropdownButtonFormField<String>(
              value: brand,
              items: const [
                DropdownMenuItem(value: "Nike", child: Text("Nike")),
                DropdownMenuItem(value: "Adidas", child: Text("Adidas")),
              ],
              onChanged: (val) => setState(() => brand = val!),
              decoration: const InputDecoration(labelText: "Brand"),
            ),
            const SizedBox(height: spacing),

            DropdownButtonFormField<double>(
              value: size == 0 ? null : size,
              items: List.generate(15, (i) => DropdownMenuItem(value: (36 + i).toDouble(), child: Text('${36 + i}'))),
              onChanged: (val) => setState(() => size = val!),
              decoration: const InputDecoration(labelText: "Size"),
            ),
            const SizedBox(height: spacing),

            DropdownButtonFormField<String>(
              value: condition,
              items: const [
                DropdownMenuItem(value: "New", child: Text("New")),
                DropdownMenuItem(value: "New with faults", child: Text("New with faults")),
                DropdownMenuItem(value: "Used", child: Text("Used")),
              ],
              onChanged: (val) => setState(() => condition = val!),
              decoration: const InputDecoration(labelText: "Condition"),
            ),
            const SizedBox(height: spacing),

            DropdownButtonFormField<String>(
              value: packaging,
              items: const [
                DropdownMenuItem(value: "With original box", child: Text("With original box")),
                DropdownMenuItem(value: "Without original box", child: Text("Without original box")),
              ],
              onChanged: (val) => setState(() => packaging = val!),
              decoration: const InputDecoration(labelText: "Packaging"),
            ),
            const SizedBox(height: spacing * 1.5),

            ElevatedButton(
              onPressed: _isUploading ? null : _updateListing,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4E3E14)),
              child: _isUploading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text("SAVE CHANGES", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
