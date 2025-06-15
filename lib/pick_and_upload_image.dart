import 'package:flutter/material.dart';
import 'dart:io';

class PickAndUploadImagePage extends StatefulWidget {
  final File? imageFile;
  final VoidCallback? onDelete;
  const PickAndUploadImagePage({Key? key, this.imageFile, this.onDelete}) : super(key: key);

  @override
  State<PickAndUploadImagePage> createState() => _PickAndUploadImagePageState();
}

class _PickAndUploadImagePageState extends State<PickAndUploadImagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete your product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (widget.onDelete != null) widget.onDelete!();
                  Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            // Optionally handle tap on image (e.g., zoom, show options, etc.)
          },
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: widget.imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.imageFile!, fit: BoxFit.cover),
                  )
                : const Center(child: Text('No image selected.')),
          ),
        ),
      ),
    );
  }
}

