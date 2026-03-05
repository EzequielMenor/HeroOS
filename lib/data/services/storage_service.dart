import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Gestiona la selección y subida de imágenes a Supabase Storage.
class StorageService {
  static const _bucket = 'avatars';
  final _picker = ImagePicker();

  /// Abre la galería y devuelve el archivo seleccionado.
  /// Devuelve null si el usuario cancela.
  Future<XFile?> pickImage() => _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

  /// Sube [file] al bucket `avatars` bajo la subcarpeta del usuario autenticado.
  /// Devuelve la URL pública del archivo subido.
  Future<String> uploadAvatar(XFile file) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$ts.jpg';
    const opts = FileOptions(contentType: 'image/jpeg', upsert: true);

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await SupabaseService.client.storage
          .from(_bucket)
          .uploadBinary(path, bytes, fileOptions: opts);
    } else {
      await SupabaseService.client.storage
          .from(_bucket)
          .upload(path, File(file.path), fileOptions: opts);
    }

    return SupabaseService.client.storage.from(_bucket).getPublicUrl(path);
  }
}
