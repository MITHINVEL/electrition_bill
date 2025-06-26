import 'package:flutter/material.dart';

class DownloadeSearchInput extends StatefulWidget {
  final Function(String) onSearch;
  final Function(DateTime?) onDateSelected;
  final DateTime? selectedDate;
  final String hintText;
  const DownloadeSearchInput({
    Key? key,
    required this.onSearch,
    required this.onDateSelected,
    this.selectedDate,
    this.hintText = 'Search by number',
  }) : super(key: key);

  @override
  State<DownloadeSearchInput> createState() => _DownloadeSearchInputState();
}

class _DownloadeSearchInputState extends State<DownloadeSearchInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    widget.onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _pickDate,
        ),
        hintText: widget.hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: widget.onSearch,
    );
  }
}
