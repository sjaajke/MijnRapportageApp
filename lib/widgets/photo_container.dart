// Copyright (C) 2026 Jay Smeekes
//
// This file is part of MijnRapportage.
//
// MijnRapportage is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// MijnRapportage is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with MijnRapportage. If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../services/photo_service.dart';

const _imageExtensions = {
  '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif',
};

class PhotoContainer extends StatefulWidget {
  final String? photoPath;
  final String label;
  final ValueChanged<String> onPhotoSelected;
  final VoidCallback? onPhotoRemoved;
  final double? height;
  final double? width;
  final double? aspectRatio;
  final BoxFit fit;

  const PhotoContainer({
    super.key,
    this.photoPath,
    this.label = 'Foto toevoegen',
    required this.onPhotoSelected,
    this.onPhotoRemoved,
    this.height = 200,
    this.width,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  @override
  State<PhotoContainer> createState() => _PhotoContainerState();
}

class _PhotoContainerState extends State<PhotoContainer> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        widget.photoPath != null && File(widget.photoPath!).existsSync();
    final photoBox = Container(
      height: widget.aspectRatio == null ? widget.height : null,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: _dragging ? Colors.blue : Colors.grey.shade400,
          width: _dragging ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _dragging
            ? Colors.blue.withValues(alpha: 0.08)
            : Colors.grey.shade100,
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(widget.photoPath!),
                fit: widget.fit,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _dragging ? Icons.file_download_outlined : Icons.add_a_photo,
                  size: 40,
                  color: _dragging ? Colors.blue : Colors.grey.shade500,
                ),
                const SizedBox(height: 8),
                Text(
                  _dragging ? 'Sleep hier om toe te voegen' : widget.label,
                  style: TextStyle(
                    color: _dragging ? Colors.blue.shade700 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );

    final photoTile = GestureDetector(
      onTap: () => _showPhotoOptions(context),
      child: widget.aspectRatio == null
          ? photoBox
          : AspectRatio(
              aspectRatio: widget.aspectRatio!,
              child: photoBox,
            ),
    );

    final dropTarget = DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _handleDrop,
      child: photoTile,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(widget.label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          if (hasPhoto && widget.onPhotoRemoved != null)
            Stack(
              children: [
                dropTarget,
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onPhotoRemoved,
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.delete_outline,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            dropTarget,
        ],
      ),
    );
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    final imageFiles = details.files.where(
        (f) => _imageExtensions.contains(p.extension(f.path).toLowerCase()));
    if (imageFiles.isEmpty) return;
    final path = await PhotoService().importDroppedFile(imageFiles.first.path);
    widget.onPhotoSelected(path);
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService().takePhoto();
                if (path != null) widget.onPhotoSelected(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerij'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService().pickFromGallery();
                if (path != null) widget.onPhotoSelected(path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
