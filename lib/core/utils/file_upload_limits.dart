const int maxUploadFileSizeBytes = 1024 * 1024;

const String maxUploadFileSizeMessage =
    'File size must be less than or equal to 1 MB.';

bool hasFileOverUploadLimit(Iterable<dynamic> files) {
  return files.any(
    (dynamic file) => ((file.size ?? 0) as int) > maxUploadFileSizeBytes,
  );
}

void validateUploadBytesLength(int bytesLength) {
  if (bytesLength > maxUploadFileSizeBytes) {
    throw Exception(maxUploadFileSizeMessage);
  }
}
