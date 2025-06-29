import 'dart:io';
import 'package:electrition_bill/core/constant.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:electrition_bill/downloads/downloadwidgets/downloadesearch_input.dart';

class DownloadedBillsPage extends StatefulWidget {
  const DownloadedBillsPage({Key? key}) : super(key: key);

  @override
  State<DownloadedBillsPage> createState() => _DownloadedBillsPageState();
}

class _DownloadedBillsPageState extends State<DownloadedBillsPage> {
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _filteredBills = [];
  Set<int> _selectedIndexes = {};
  bool _loading = false;
  String? _error;
  DateTime? _selectedDate;
  String _filterLabel = 'All';
  bool get _selectionMode => _selectedIndexes.isNotEmpty;
  DateTime? _searchDate;
  String _searchNumber = '';

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIndexes = Set.from(List.generate(_filteredBills.length, (i) => i));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
    });
  }

  void _deleteSelected() async {
    final toDelete = _selectedIndexes.map((i) => _filteredBills[i]['file'] as File).toList();
    for (final file in toDelete) {
      if (await file.exists()) await file.delete();
    }
    await _loadBills();
    _clearSelection();
  }

  void _shareSelected() async {
    // IMPORTANT: If you get MissingPluginException for share_plus,
    // do a FULL STOP and RESTART of your app (not just hot reload/hot restart).
    // Also, make sure you are running on a real device or emulator (not web/desktop).
    // If the error still occurs, run 'flutter clean' and then 'flutter pub get'.
    final toShare = _selectedIndexes.map((i) => _filteredBills[i]['file'].path).toList();
    if (toShare.isNotEmpty) {
      await Share.shareXFiles(
        toShare.map((path) => XFile(path)).toList(),
        text: 'Sharing ${toShare.length} bill(s)',
      );
    }
  }

  void _applyFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<Map<String, dynamic>> filtered;
    if (filter == 'Today') {
      filtered = _bills.where((bill) {
        final d = bill['modified'] as DateTime;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();
    } else if (filter == 'Yesterday') {
      final yesterday = today.subtract(Duration(days: 1));
      filtered = _bills.where((bill) {
        final d = bill['modified'] as DateTime;
        return d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;
      }).toList();
    } else if (filter == 'Last Week') {
      final lastWeek = today.subtract(Duration(days: 7));
      filtered = _bills.where((bill) {
        final d = bill['modified'] as DateTime;
        return d.isAfter(lastWeek) && d.isBefore(today.add(Duration(days: 1)));
      }).toList();
    } else if (filter == 'Last Month') {
      final lastMonth = DateTime(today.year, today.month - 1, today.day);
      filtered = _bills.where((bill) {
        final d = bill['modified'] as DateTime;
        return d.isAfter(lastMonth) && d.isBefore(today.add(Duration(days: 1)));
      }).toList();
    } else if (filter == 'Last Year') {
      final lastYear = DateTime(today.year - 1, today.month, today.day);
      filtered = _bills.where((bill) {
        final d = bill['modified'] as DateTime;
        return d.isAfter(lastYear) && d.isBefore(today.add(Duration(days: 1)));
      }).toList();
    } else {
      filtered = _bills;
    }
    setState(() {
      _filteredBills = filtered;
      _filterLabel = filter;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tz.initializeTimeZones();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Directory? downloadsDir;
      if (Theme.of(context).platform == TargetPlatform.android) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) {
          downloadsDir = dirs.first;
        } else {
          downloadsDir = await getExternalStorageDirectory();
        }
        if (downloadsDir == null || !(await downloadsDir.exists())) {
          downloadsDir = Directory('/storage/emulated/0/Download');
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      final files = downloadsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.pdf'))
          .toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      setState(() {
        _bills = files.map((f) => {
          'file': f,
          'name': f.uri.pathSegments.last,
          'modified': f.statSync().modified,
        }).toList();
        _filteredBills = _bills;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bills: $e';
        _loading = false;
      });
    }
  }

  void _onSearchNumber(String value) {
    setState(() {
      _searchNumber = value;
      _filteredBills = _bills.where((bill) {
        final name = bill['name'] as String;
        return name.contains(_searchNumber);
      }).toList();
    });
  }

  void _onDateSelected(DateTime? date) {
    setState(() {
      _searchDate = date;
      if (date == null) {
        _filteredBills = _bills;
      } else {
        _filteredBills = _bills.where((bill) {
          final d = bill['modified'] as DateTime;
          return d.year == date.year && d.month == date.month && d.day == date.day;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final chennai = tz.getLocation('Asia/Kolkata');
    final recentBills = _filteredBills.where((bill) {
      final modified = bill['modified'] as DateTime;
      return now.difference(modified).inMinutes < 1;
    }).toList();
    final otherBills = _filteredBills.where((bill) {
      final modified = bill['modified'] as DateTime;
      return now.difference(modified).inMinutes >= 1;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedIndexes.length} selected')
            : Text(_filterLabel == 'All' ? 'Downloaded Bills': '$_filterLabel Downloads (${_filteredBills.length})'),
            backgroundColor: primary,
        actions: [
          if (!_selectionMode)
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list,size: 40,
              color: black,),
              onSelected: (value) => _applyFilter(value),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'All', child: Row(children: [Text('All'), Spacer(), Text('${_bills.length}')])) ,
                PopupMenuItem(value: 'Today', child: Row(children: [Text('Today'), Spacer(), Text('${_bills.where((b){final d=b['modified'] as DateTime;final now=DateTime.now();return d.year==now.year&&d.month==now.month&&d.day==now.day;}).length}')])) ,
                PopupMenuItem(value: 'Yesterday', child: Row(children: [Text('Yesterday'), Spacer(), Text('${_bills.where((b){final d=b['modified'] as DateTime;final y=DateTime.now().subtract(Duration(days:1));return d.year==y.year&&d.month==y.month&&d.day==y.day;}).length}')])) ,
                PopupMenuItem(value: 'Last Week', child: Row(children: [Text('Last Week'), Spacer(), Text('${_bills.where((b){final d=b['modified'] as DateTime;final w=DateTime.now().subtract(Duration(days:7));return d.isAfter(w);}).length}')])) ,
                PopupMenuItem(value: 'Last Month', child: Row(children: [Text('Last Month'), Spacer(), Text('${_bills.where((b){final d=b['modified'] as DateTime;final m=DateTime(DateTime.now().year,DateTime.now().month-1,DateTime.now().day);return d.isAfter(m);}).length}')])) ,
                PopupMenuItem(value: 'Last Year', child: Row(children: [Text('Last Year'), Spacer(), Text('${_bills.where((b){final d=b['modified'] as DateTime;final y=DateTime(DateTime.now().year-1,DateTime.now().month,DateTime.now().day);return d.isAfter(y);}).length}')])) ,
              ],
            ),
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _shareSelected,
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Selection',
              onPressed: _clearSelection,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DownloadeSearchInput(
              onSearch: _onSearchNumber,
              onDateSelected: _onDateSelected,
              selectedDate: _searchDate,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text('Recent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (recentBills.isNotEmpty)
            ...recentBills.asMap().entries.map((entry) {
              final bill = entry.value;
              final index = _filteredBills.indexOf(bill);
              final selected = _selectedIndexes.contains(index);
              return Card(
                color: selected ? Colors.blue.withOpacity(0.1) : null,
                elevation: 2,
                child: ListTile(
                  onLongPress: () => _toggleSelect(index),
                  onTap: _selectionMode ? () => _toggleSelect(index) : null,
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                      if (selected)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                    ],
                  ),
                  title: Text(bill['name']),
                  subtitle: Text('Downloaded: ' + DateFormat('yyyy-MM-dd hh:mm a').format(
                    tz.TZDateTime.from(bill['modified'], chennai)) + ' (Dharmapuri, Tamil Nadu, IST)'),
                  trailing: !_selectionMode
                      ? IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final file = bill['file'] as File;
                            final result = await OpenFile.open(file.path);
                            if (result.type != ResultType.done) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Unable to open PDF: ${result.message}')),
                              );
                            }
                          },
                        )
                      : null,
                ),
              );
            }).toList(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (otherBills.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: otherBills.length,
                itemBuilder: (context, index) {
                  final bill = otherBills[index];
                  final realIndex = _filteredBills.indexOf(bill);
                  final selected = _selectedIndexes.contains(realIndex);
                  return Opacity(
                    opacity: _selectionMode && !selected ? 0.5 : 1.0,
                    child: Card(
                      color: selected ? Colors.blue.withOpacity(0.1) : null,
                      elevation: 1,
                      child: ListTile(
                        onLongPress: () => _toggleSelect(realIndex),
                        onTap: _selectionMode ? () => _toggleSelect(realIndex) : null,
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                            if (selected)
                              const Positioned(
                                right: 0,
                                bottom: 0,
                                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                              ),
                          ],
                        ),
                        title: Text(bill['name']),
                        subtitle: Text('Downloaded: ' + DateFormat('yyyy-MM-dd hh:mm a').format(
                          tz.TZDateTime.from(bill['modified'], chennai)) ),
                        trailing: !_selectionMode
                            ? IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () async {
                                  final file = bill['file'] as File;
                                  final result = await OpenFile.open(file.path);
                                  if (result.type != ResultType.done) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Unable to open PDF: ${result.message}')),
                                    );
                                  }
                                },
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
