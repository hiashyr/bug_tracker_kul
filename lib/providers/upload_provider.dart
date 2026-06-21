import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/new_api_client.dart';

final uploadFileProvider = Provider((ref) {
  final apiClient = ref.watch(newApiClientProvider);

  return (Uint8List bytes, {required String filename}) async {
    return apiClient.uploadTempFile(bytes, filename: filename);
  };
});
