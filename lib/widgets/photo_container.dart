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
import 'package:flutter/material.dart';
import '../services/photo_service.dart';

class PhotoContainer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    final photoBox = Container(
      height: aspectRatio == null ? height : null,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photoPath!),
                fit: fit,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo,
                    size: 40, color: Colors.grey.shade500),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
    );

    final photoTile = GestureDetector(
      onTap: () => _showPhotoOptions(context),
      child: aspectRatio == null
          ? photoBox
          : AspectRatio(
              aspectRatio: aspectRatio!,
              child: photoBox,
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ),
          if (hasPhoto && onPhotoRemoved != null)
            Stack(
              children: [
                photoTile,
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPhotoRemoved,
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
            photoTile,
        ],
      ),
    );
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
                if (path != null) onPhotoSelected(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerij'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService().pickFromGallery();
                if (path != null) onPhotoSelected(path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
