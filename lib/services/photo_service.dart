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
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _picker = ImagePicker();
  int _copyCounter = 0;

  Future<String> _getPhotosDir(int? inspectionId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(
        p.join(appDir.path, 'photos', (inspectionId ?? 0).toString()));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir.path;
  }

  Future<String?> takePhoto({int? inspectionId}) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (image == null) return null;
    return await _saveImage(image, inspectionId);
  }

  Future<String?> pickFromGallery({int? inspectionId}) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (image == null) return null;
    return await _saveImage(image, inspectionId);
  }

  Future<String> _saveImage(XFile image, int? inspectionId) async {
    final dir = await _getPhotosDir(inspectionId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(image.path).isNotEmpty ? p.extension(image.path) : '.jpg';
    final fileName = '$timestamp$ext';
    final savedPath = p.join(dir, fileName);
    await File(image.path).copy(savedPath);
    return savedPath;
  }

  /// Saves raw photo bytes (e.g. downloaded from a remote herstel-submission)
  /// into an inspection's photos directory, using the same naming convention
  /// as [_saveImage], and returns the local file path.
  Future<String> saveBytesAsPhoto(List<int> bytes, int? inspectionId,
      {String ext = '.jpg'}) async {
    final dir = await _getPhotosDir(inspectionId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp$ext';
    final savedPath = p.join(dir, fileName);
    await File(savedPath).writeAsBytes(bytes);
    return savedPath;
  }

  /// Copies an existing photo file into another inspection's photos directory
  /// and returns the new path. Used when duplicating data across inspections.
  Future<String?> copyPhotoToInspection(
      String? sourcePath, int targetInspectionId) async {
    if (sourcePath == null || sourcePath.isEmpty) return sourcePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return sourcePath;
    final dir = await _getPhotosDir(targetInspectionId);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final ext =
        p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final fileName = '${timestamp}_${_copyCounter++}$ext';
    final newPath = p.join(dir, fileName);
    await sourceFile.copy(newPath);
    return newPath;
  }

  Future<String> getExportsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(appDir.path, 'exports'));
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir.path;
  }
}
