import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/local_settings_service.dart';


class CreateListing extends StatefulWidget {
  const CreateListing({super.key});

  @override
  State<CreateListing> createState() => _CreateListingState();
}

class _CreateListingState extends State<CreateListing> {
  bool _isUploading = false;

  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();

  String brand = '';
  double size = 0;
  String condition = '';
  String packaging = '';
  String currency = '\$';

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 10) {
      _showLimitMessage("You can only upload up to 10 images.");
      return;
    }

    if (source == ImageSource.gallery) {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final availableSlots = 10 - _images.length;
        final limitedFiles = pickedFiles.take(availableSlots).map((f) => File(f.path)).toList();

        setState(() {
          _images.addAll(limitedFiles);
        });

        if (pickedFiles.length > availableSlots) {
          _showLimitMessage("Only $availableSlots more image(s) allowed. Extra images were ignored.");
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

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Take Photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  void _showLimitMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, 
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, color: Colors.white)), 
      duration: const Duration(seconds: 2)),
    );
  }

  void _showImagePreview(File image) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => Navigator.pop(context), // tap to close
        child: InteractiveViewer( // allows pinch zoom & drag
          child: Image.file(image),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadListing() async {
    if (_images.isEmpty) {
      _showLimitMessage("Please add at least one image.");
      return;
    }
    if (titleController.text.trim().isEmpty) {
      _showLimitMessage("Please enter a title.");
      return;
    }
    if (priceController.text.trim().isEmpty) {
      _showLimitMessage("Please enter a price.");
      return;
    }
    if (brand.isEmpty) {
      _showLimitMessage("Please select a brand.");
      return;
    }
    if (size == 0) {
      _showLimitMessage("Please select a size.");
      return;
    }
    if (condition.isEmpty) {
      _showLimitMessage("Please select the item condition.");
      return;
    }
    if (packaging.isEmpty) {
      _showLimitMessage("Please select the packaging.");
      return;
    }

    final String userKey = LocalSettingsService.userKey;

    // After tests, create a listing
    final uri = Uri.parse("http://80.211.202.178:8000/listings/v1/create-listing");
    // final uri = Uri.parse("http://127.0.0.1:8000/listings/v1/create-listing");
    final request = http.MultipartRequest('POST', uri);

    // create fields for every data parameter:
    request.fields['title'] = titleController.text;
    request.fields['price'] = priceController.text;
    request.fields['price_currency'] = currency;
    request.fields['description'] = descController.text.isNotEmpty ? descController.text : "";
    request.fields['brand'] = brand;
    request.fields['size'] = size.toString();
    request.fields['item_condition'] = condition;
    request.fields['packaging'] = packaging;
    request.headers['X-User-Nanoid'] = userKey; // replace with actual user key

    for (var imageFile in _images) {
      final fileStream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();

      request.files.add(http.MultipartFile(
        'images', 
        fileStream, 
        length,
        filename: imageFile.path.split("/").last,
        contentType: MediaType('image', 'jpeg'), // or 'png' based on your image type
      ));
    }

    setState(() => _isUploading = true);

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        print("Upload success: $respStr");

        if (mounted) {
          Navigator.pop(context, true); // Close create_listing screen and go back to your store
        }

      } else {
        print("Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error uploading listing: $e");
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

    final customTheme = ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF5EFE6),
      primaryColor: const Color(0xFF8B6B29),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF8B6B29)),
        bodyMedium: TextStyle(color: Color(0xFF8B6B29)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFE9DFCC),
        elevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8B6B29)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8B6B29)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8B6B29), width: 2),
        ),
        labelStyle: TextStyle(color: Color(0xFF8B6B29)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF8B6B29)),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: Color(0xFF8B6B29)),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF8B6B29)),
          ),
        ),
      ),
    );

    return Theme(
      data: customTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          title: const Text("CREATE LISTING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          centerTitle: true,
          backgroundColor: Color(0xFFE9DFCC),
          // foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Row
              SizedBox(
                height: 120,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length < 10 ? _images.length + 1 : 10,
                  itemBuilder: (context, index) {
                    if (index < _images.length) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GestureDetector(
                                onTap: () => _showImagePreview(_images[index]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _images[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(index)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(153), // ~0.6 opacity
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF8B6B29)),
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

              // Title
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: spacing),

              // Price + Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: currency,
                      decoration: const InputDecoration(labelText: "Currency", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: '\$', child: Text("\$", style: TextStyle(color: Color(0xFF8B6B29)))),
                        DropdownMenuItem(value: '€', child: Text("€", style: TextStyle(color: Color(0xFF8B6B29)))),
                      ],
                      onChanged: (val) => setState(() => currency = val!),
                      style: const TextStyle(fontSize: 18),
                      iconEnabledColor: Color(0xFF8B6B29),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: spacing),

              // Description
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description (Optional)", border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: spacing),

              // Brand
              DropdownButtonFormField<String>(
                value: brand.isEmpty ? null : brand,
                decoration: const InputDecoration(labelText: "Brand", border: OutlineInputBorder()),
                hint: const Text("Select brand", style: TextStyle(color: Color(0xFF8B6B29))),
                items: const [
                  DropdownMenuItem(value: "Nike", child: Text("Nike", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: "Adidas", child: Text("Adidas", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) => setState(() => brand = val!),
                style: const TextStyle(fontSize: 18),
                iconEnabledColor: Color(0xFF8B6B29),
              ),
              const SizedBox(height: spacing),

              // Size
              DropdownButtonFormField<double>(
                value: size == 0 ? null : size,
                hint: const Text("Select size", style: TextStyle(color: Color(0xFF8B6B29))),
                decoration: const InputDecoration(labelText: "Size", border: OutlineInputBorder()),
                items: List.generate(
                  15,
                  (index) {
                    final val = 36 + index.toDouble();
                    return DropdownMenuItem(value: val, child: Text(val.toString(), style: const TextStyle(color: Color(0xFF8B6B29))));
                  },
                ),
                onChanged: (val) => setState(() => size = val!),
                style: const TextStyle(fontSize: 18),
                iconEnabledColor: Color(0xFF8B6B29),
              ),
              const SizedBox(height: spacing),

              // Condition
              DropdownButtonFormField<String>(
                value: condition.isEmpty ? null : condition,
                decoration: const InputDecoration(labelText: "Item Condition", border: OutlineInputBorder()),
                hint: const Text("Select condition", style: TextStyle(color: Color(0xFF8B6B29))),
                items: const [
                  DropdownMenuItem(value: "New", child: Text("New", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: "New with faults", child: Text("New with faults", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: "Used", child: Text("Used", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) => setState(() => condition = val!),
                style: const TextStyle(fontSize: 18),
                iconEnabledColor: Color(0xFF8B6B29),
              ),
              const SizedBox(height: spacing),

              // Packaging
              DropdownButtonFormField<String>(
                value: packaging.isEmpty ? null : packaging,
                hint: const Text("Select packaging", style: TextStyle(color: Color(0xFF8B6B29))),
                decoration: const InputDecoration(labelText: "Packaging", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "With original box", child: Text("With original box", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: "Without original box", child: Text("Without original box", style: TextStyle(color: Color(0xFF8B6B29), fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) => setState(() => packaging = val!),
                style: const TextStyle(fontSize: 18),
                iconEnabledColor: Color(0xFF8B6B29),
              ),
              const SizedBox(height: spacing * 1.5),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4E3E14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 5,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text(
                          "POST LISTING", 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
