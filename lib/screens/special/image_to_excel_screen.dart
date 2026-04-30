import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/excel_service.dart';

class ImageToExcelScreen extends StatefulWidget {
  const ImageToExcelScreen({super.key});

  @override
  State<ImageToExcelScreen> createState() => _ImageToExcelScreenState();
}

class _ImageToExcelScreenState extends State<ImageToExcelScreen> {
  final List<File> _pendingImages = [];
  bool _isProcessing = false;
  String _statusText = '';
  int _totalRecords = 0; // number of rows already in session
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSessionCount();
  }

  Future<void> _loadSessionCount() async {
    final count = await ExcelService.getSessionRowCount();
    if (mounted) setState(() => _totalRecords = count);
  }

  Future<void> _pickMultipleImages() async {
    // Show tip on first use
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '💡 Tap each photo to select it (✓ appears), then tap "Add"',
        ),
        duration: Duration(seconds: 4),
        backgroundColor: Color(0xFF1A3A5C),
      ),
    );
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() {
        _pendingImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _pendingImages.add(File(image.path)));
    }
  }

  void _removeImage(int index) =>
      setState(() => _pendingImages.removeAt(index));

  Future<void> _processBatch() async {
    if (_pendingImages.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _statusText = 'Analyzing image 1 of ${_pendingImages.length}...';
    });

    try {
      final total = await ExcelService.addBatchToSession(
        List.from(_pendingImages),
        onProgress: (current, max) {
          if (mounted) {
            setState(() {
              _statusText = 'Analyzing image $current of $max...';
            });
          }
        },
      );

      setState(() {
        _pendingImages.clear();
        _totalRecords = total;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added! Total records in session: $_totalRecords'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportExcel() async {
    try {
      await ExcelService.shareSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showPreview() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PreviewDialog(
        onRefresh: () async {
          final count = await ExcelService.getSessionRowCount();
          if (mounted) setState(() => _totalRecords = count);
        },
      ),
    );
  }

  Future<void> _clearSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Session?'),
        content: Text(
          'This will delete all $_totalRecords saved records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ExcelService.clearSession();
      if (mounted) {
        setState(() => _totalRecords = 0);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session cleared.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Image to Excel',
          style: TextStyle(
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3A5C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_totalRecords > 0)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Clear session',
              onPressed: _clearSession,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            // Session status banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _totalRecords > 0
                    ? const Color(0xFF1A3A5C)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _totalRecords > 0
                        ? Icons.table_chart
                        : Icons.table_chart_outlined,
                    color: _totalRecords > 0 ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _totalRecords > 0
                          ? '$_totalRecords record${_totalRecords == 1 ? '' : 's'} saved'
                          : 'No session data yet',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _totalRecords > 0 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_totalRecords > 0) ...[
                    const SizedBox(width: 8),
                    _BannerButton(
                      text: 'Preview',
                      icon: Icons.visibility,
                      onPressed: _showPreview,
                      isPrimary: false,
                    ),
                    const SizedBox(width: 6),
                    _BannerButton(
                      text: 'Export',
                      icon: Icons.download,
                      onPressed: _exportExcel,
                      isPrimary: true,
                    ),
                  ],
                ],
              ),
            ),

            // Pending image grid or empty state
            Expanded(
              child: _pendingImages.isEmpty
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF5DADE2),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 80,
                              color: Color(0xFF5DADE2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _totalRecords > 0
                                  ? 'Add more images to continue'
                                  : 'No images selected',
                              style: const TextStyle(
                                color: Color(0xFF1A3A5C),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap Gallery or Camera to add images',
                              style: TextStyle(
                                color: Color(0xFF1A3A5C),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '${_pendingImages.length} image${_pendingImages.length == 1 ? '' : 's'} pending',
                                style: const TextStyle(
                                  color: Color(0xFF1A3A5C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _pendingImages.clear()),
                                child: const Text(
                                  'Clear all',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _pendingImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _pendingImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1A3A5C,
                                        ).withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            // Progress
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF5DADE2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Color(0xFF1A3A5C),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Picker buttons
            Row(
              children: [
                Expanded(
                  child: _SmallButton(
                    text: 'Gallery',
                    icon: Icons.photo_library,
                    onPressed: _isProcessing ? () {} : _pickMultipleImages,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallButton(
                    text: 'Camera',
                    icon: Icons.camera_alt,
                    onPressed: _isProcessing ? () {} : _pickFromCamera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Process batch button
            _ActionButton(
              text: _isProcessing
                  ? 'Processing...'
                  : _pendingImages.isEmpty
                  ? 'Add images first'
                  : 'Process & Add to Session (${_pendingImages.length})',
              color: _pendingImages.isEmpty
                  ? Colors.grey.shade400
                  : const Color(0xFF1A3A5C),
              textColor: Colors.white,
              onPressed: _isProcessing || _pendingImages.isEmpty
                  ? () {}
                  : _processBatch,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  const _PreviewDialog({required this.onRefresh});

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  List<Map<String, String>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ExcelService.getSessionData();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          AppBar(
            title: const Text(
              'Session Preview',
              style: TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF1A3A5C)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                    ? const Center(child: Text('No data found in session.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xFF1A3A5C).withOpacity(0.05),
                            ),
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'Action',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...(_data.first.keys.map(
                                (h) => DataColumn(
                                  label: Text(
                                    h,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )),
                            ],
                            rows: _data.asMap().entries.map((entry) {
                              final index = entry.key;
                              final row = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Row?'),
                                            content: const Text('Are you sure you want to remove this record?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true), 
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await ExcelService.deleteRowFromSession(index);
                                          _loadData();
                                          widget.onRefresh();
                                        }
                                      },
                                    ),
                                  ),
                                  ...row.values.map((v) => DataCell(Text(v))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _BannerButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF5DADE2) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const _SmallButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A3A5C),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        side: const BorderSide(color: Color(0xFF5DADE2)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.text,
    required this.color,
    this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFF1A3A5C),
            ),
          ),
        ),
      ),
    );
  }
}
