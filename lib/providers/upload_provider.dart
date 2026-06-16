import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/new_api_client.dart';

final uploadFileProvider = Provider((ref) {
  final apiClient = ref.watch(newApiClientProvider);
  return (String filePath, {String? filename}) async {
    return apiClient.uploadTempFile(filePath, filename: filename);
  };
});