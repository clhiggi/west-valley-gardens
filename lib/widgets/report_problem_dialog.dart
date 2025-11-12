
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportProblemDialog extends StatefulWidget {
  final XFile imageFile;
  final Future<bool> Function(XFile imageFile, String description) onUpload;

  const ReportProblemDialog(
      {super.key, required this.imageFile, required this.onUpload});

  @override
  _ReportProblemDialogState createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<ReportProblemDialog> {
  final _descriptionController = TextEditingController();
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _uploadError = "Description cannot be empty.";
      });
      return;
    }
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    final success =
        await widget.onUpload(widget.imageFile, _descriptionController.text.trim());

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isUploading = false;
          _uploadError = "Upload failed. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report a Problem'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            kIsWeb
                ? Image.network(
                    widget.imageFile.path,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(widget.imageFile.path),
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (_uploadError != null) ...[
              const SizedBox(height: 16),
              Text(
                _uploadError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ]
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submit,
          child: _isUploading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
