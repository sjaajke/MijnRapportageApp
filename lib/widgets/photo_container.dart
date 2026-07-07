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
  final double? height;
  final double? width;
  final double? aspectRatio;

  const PhotoContainer({
    super.key,
    this.photoPath,
    this.label = 'Foto toevoegen',
    required this.onPhotoSelected,
    this.height = 200,
    this.width,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final photoBox = Container(
      height: aspectRatio == null ? height : null,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: photoPath != null && File(photoPath!).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photoPath!),
                fit: BoxFit.cover,
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
          GestureDetector(
            onTap: () => _showPhotoOptions(context),
            child: aspectRatio == null
                ? photoBox
                : AspectRatio(
                    aspectRatio: aspectRatio!,
                    child: photoBox,
                  ),
          ),
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
