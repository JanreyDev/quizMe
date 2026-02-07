import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';

class ModulesListScreen extends StatefulWidget {
  final String classCode;
  final String classId;

  const ModulesListScreen({
    super.key,
    required this.classCode,
    required this.classId,
  });

  @override
  State<ModulesListScreen> createState() => _ModulesListScreenState();
}

class _ModulesListScreenState extends State<ModulesListScreen> {
  bool _isUploading = false;
  bool _isPublishing = false;
  final Set<String> _selectedItems = {};
  Stream<QuerySnapshot>? _modulesStream;

  @override
  void initState() {
    super.initState();
    _modulesStream = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('modules')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> _publishModules() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isPublishing = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var itemKey in _selectedItems) {
        final docId = itemKey;
        final docRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('modules')
            .doc(docId);
        batch.update(docRef, {'isPublished': true});
      }

      await batch.commit();

      // Send notifications
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final className = classDoc.data()?['name'] ?? widget.classCode;

      for (var docId in _selectedItems) {
        // Fetch module title
        final modDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('modules')
            .doc(docId)
            .get();
        final modTitle = modDoc.data()?['title'] ?? 'New Module';

        await NotificationService.sendToClass(
          classId: widget.classId,
          classCode: widget.classCode,
          className: className,
          title: 'Module Uploaded',
          message: 'New file uploaded: "$modTitle" in ${widget.classCode}.',
          type: 'module',
          docId: docId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully published ${_selectedItems.length} module${_selectedItems.length > 1 ? 's' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedItems.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to publish: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _showCreateModuleModal() async {
    final titleController = TextEditingController();
    String? pickedFileName;
    PlatformFile? platformFile;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Module',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Module Title',
                    hintText: 'e.g., Lesson 1: Fundamentals of SE',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Upload File',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'doc',
                            'docx',
                            'ppt',
                            'pptx',
                          ],
                        );
                    if (result != null) {
                      setModalState(() {
                        platformFile = result.files.first;
                        pickedFileName = platformFile!.name;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          pickedFileName == null
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_outline,
                          size: 48,
                          color: pickedFileName == null
                              ? Colors.grey[400]
                              : const Color(0xFF007D6E),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pickedFileName ?? 'Click to pick PDF, PPTX, or DOCS',
                          style: TextStyle(
                            color: pickedFileName == null
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontWeight: pickedFileName == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (titleController.text.isEmpty ||
                            platformFile == null ||
                            _isUploading)
                        ? null
                        : () async {
                            Navigator.pop(context, {
                              'title': titleController.text,
                              'file': platformFile,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007D6E),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Module',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ).then((result) async {
      if (result != null && result is Map) {
        final title = result['title'] as String;
        final file = result['file'] as PlatformFile;
        await _performUpload(title, file);
      }
    });
  }

  Future<void> _performUpload(String title, PlatformFile file) async {
    setState(() => _isUploading = true);

    try {
      final fileName = file.name;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'modules/${widget.classId}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      late UploadTask uploadTask;
      if (file.bytes != null) {
        uploadTask = storageRef.putData(file.bytes!);
      } else if (file.path != null) {
        uploadTask = storageRef.putFile(File(file.path!));
      } else {
        throw Exception('Could not read file');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('modules')
          .add({
            'title': title,
            'fileUrl': downloadUrl,
            'fileName': fileName,
            'fileType': file.extension ?? 'unknown',
            'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
            'uploadedAt': FieldValue.serverTimestamp(),
            'isPublished': false, // Default to unpublished
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteModule(
    String docId,
    String title,
    String? fileUrl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('modules')
            .doc(docId)
            .delete();

        // Try to delete from Storage if fileUrl exists
        if (fileUrl != null && fileUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
          } catch (storageError) {
            print('Error deleting from storage: $storageError');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Module deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting module: $e')));
        }
      }
    }
  }

  Widget _buildPopupMenu(String docId, String title, String? fileUrl) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      onSelected: (value) async {
        if (value == 'download') {
          if (fileUrl == null || fileUrl.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No file URL available')),
              );
            }
            return;
          }

          try {
            final Uri uri = Uri.parse(fileUrl);
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              throw 'Could not launch $fileUrl';
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
            }
          }
        } else if (value == 'delete') {
          _deleteModule(docId, title, fileUrl);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 8),
              Text('Download'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.classCode,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modules Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'Modules',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Module Cards List - Dynamic from Firestore
          Expanded(
            child: _modulesStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _modulesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final modules = snapshot.data?.docs ?? [];

                      if (modules.isEmpty) {
                        return const Center(
                          child: Text(
                            'No modules yet.\nClick "Upload" to add one!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final moduleDoc = modules[index];
                          final moduleData =
                              moduleDoc.data() as Map<String, dynamic>;
                          final docId = moduleDoc.id;
                          final isSelected = _selectedItems.contains(docId);
                          final isPublished =
                              moduleData['isPublished'] ?? false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedItems.remove(docId);
                                  } else {
                                    _selectedItems.add(docId);
                                  }
                                });
                              },
                              child: _buildModuleCard(
                                docId: docId,
                                title: moduleData['title'] ?? 'Untitled Module',
                                fileType: moduleData['fileType'],
                                fileUrl: moduleData['fileUrl'],
                                isSelected: isSelected,
                                isPublished: isPublished,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedItems.isEmpty || _isPublishing)
                        ? null
                        : _publishModules,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007D6E),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isPublishing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedItems.isEmpty
                                ? 'Upload'
                                : 'Upload (${_selectedItems.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _showCreateModuleModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String docId,
    required String title,
    String? fileType,
    String? fileUrl,
    required bool isSelected,
    required bool isPublished,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF009688)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: const Color(0xFF007D6E), width: 3)
            : (isPublished
                  ? Border.all(color: Colors.greenAccent, width: 2)
                  : null),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF007D6E).withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container with white background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(fileType),
              size: 24,
              color: const Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(width: 16),
          // Module title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          if (isPublished)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
            ),
          _buildPopupMenu(docId, title, fileUrl),
        ],
      ),
    );
  }
}
