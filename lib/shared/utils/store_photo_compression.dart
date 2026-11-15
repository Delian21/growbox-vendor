import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Which store photo is being prepared. Each kind has its own size budget:
/// a logo is shown small, a banner full-width, and both live in browser
/// localStorage (about 5 MB for everything the app stores).
enum StorePhotoKind {
  /// Store avatar: at most 512 px on the long side, 400 KB.
  logo,

  /// Store banner: at most 1600 px on the long side, 800 KB.
  banner,
}

/// The stored result plus the numbers the Store page/report care about.
class CompressedPhoto {
  const CompressedPhoto({
    required this.dataUrl,
    required this.byteLength,
    required this.width,
    required this.height,
    required this.mimeType,
  });

  /// A ready-to-save `data:image/...;base64,` URL.
  final String dataUrl;

  /// Size of the encoded image (before base64 inflation).
  final int byteLength;
  final int width;
  final int height;
  final String mimeType;
}

/// Thrown when even the hardest compression step cannot fit the budget.
class ImageTooLargeException implements Exception {
  const ImageTooLargeException([this.message = tooLargeMessage]);

  static const String tooLargeMessage =
      'This image is too large. Try a smaller one.';

  final String message;

  @override
  String toString() => message;
}

/// Budgets, kept in one place so the UI copy and the tests agree.
const int kLogoMaxBytes = 400 * 1024;
const int kBannerMaxBytes = 800 * 1024;
const int kLogoMaxSide = 512;
const int kBannerMaxSide = 1600;

/// Qualities tried in order: 80% first, then harder steps when the first
/// result misses the byte cap.
const List<int> kQualitySteps = [80, 70, 60, 50, 40];

/// Downscales, recompresses and (if needed) steps the quality down until the
/// image fits [kind]'s budget. One helper for both pickers and re-saving an
/// existing image, so there is a single code path to reason about.
///
/// [maxBytes] and [maxSide] exist for tests (to exercise the refusal path
/// without a 5 MB fixture); the app always uses the kind's real budget.
Future<CompressedPhoto> compressStorePhoto(
  Uint8List input,
  StorePhotoKind kind, {
  int? maxBytes,
  int? maxSide,
}) async {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const ImageTooLargeException(
        'That file is not an image. Try a JPG or PNG.');
  }

  final int budget = maxBytes ??
      (kind == StorePhotoKind.logo ? kLogoMaxBytes : kBannerMaxBytes);
  final int sideCap = maxSide ??
      (kind == StorePhotoKind.logo ? kLogoMaxSide : kBannerMaxSide);

  final resized = _fitWithin(decoded, sideCap);

  // Keep PNG only for a logo that needs transparency AND is already small;
  // everything else becomes JPEG at the first quality that fits.
  if (decoded.numChannels >= 4 && kind == StorePhotoKind.logo) {
    final pngBytes = img.encodePng(resized);
    if (pngBytes.length <= budget) {
      return CompressedPhoto(
        dataUrl: 'data:image/png;base64,${base64Encode(pngBytes)}',
        byteLength: pngBytes.length,
        width: resized.width,
        height: resized.height,
        mimeType: 'image/png',
      );
    }
  }

  for (final quality in kQualitySteps) {
    final jpgBytes = img.encodeJpg(resized, quality: quality);
    if (jpgBytes.length <= budget) {
      return CompressedPhoto(
        dataUrl: 'data:image/jpeg;base64,${base64Encode(jpgBytes)}',
        byteLength: jpgBytes.length,
        width: resized.width,
        height: resized.height,
        mimeType: 'image/jpeg',
      );
    }
  }

  // Hardest step still too big: refuse instead of filling localStorage.
  throw const ImageTooLargeException();
}

/// Scales [image] down so its longest side is at most [maxSide]; never scales
/// up, and preserves the aspect ratio.
img.Image _fitWithin(img.Image image, int maxSide) {
  final longest = math.max(image.width, image.height);
  if (longest <= maxSide) return image;
  final scale = maxSide / longest;
  return img.copyResize(
    image,
    width: math.max(1, (image.width * scale).round()),
    height: math.max(1, (image.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
}
