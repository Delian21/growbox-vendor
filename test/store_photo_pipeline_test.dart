import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/providers/store_provider.dart';
import 'package:growbox_vendor/app/router.dart';
import 'package:growbox_vendor/features/store/store_screen.dart';
import 'package:growbox_vendor/main.dart';
import 'package:growbox_vendor/shared/utils/store_photo_compression.dart';

import 'load_roboto.dart';

/// Coverage for the store-photo budget pass:
///  1. A phone-sized photo comes out within the logo/banner caps, in both
///     dimensions and bytes.
///  2. An image that cannot be compressed enough is refused with the clear
///     message, not stored.
///  3. A storage failure reports failure and leaves the previous store (and
///     its previous image) exactly as it was.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A 4000×3000 "photo": smooth gradients plus a little noise, encoded as a
  /// high-quality JPEG — roughly what a phone camera produces.
  Uint8List bigPhotoJpeg() {
    final image = img.Image(width: 4000, height: 3000);
    final random = Random(7);
    for (final p in image) {
      final x = p.x * 255 ~/ image.width;
      final y = p.y * 255 ~/ image.height;
      p.r = (x + random.nextInt(16)).clamp(0, 255);
      p.g = (y + random.nextInt(16)).clamp(0, 255);
      p.b = ((x + y) ~/ 2).clamp(0, 255);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }

  test('a 4000px photo fits the logo budget and the max dimensions', () async {
    final logo = await compressStorePhoto(
      bigPhotoJpeg(),
      StorePhotoKind.logo,
    );

    expect(logo.width <= kLogoMaxSide, isTrue);
    expect(logo.height <= kLogoMaxSide, isTrue);
    expect(logo.byteLength <= kLogoMaxBytes, isTrue);
    expect(logo.dataUrl.startsWith('data:image/'), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a 4000px photo fits the banner budget and the max dimensions',
      () async {
    final banner = await compressStorePhoto(
      bigPhotoJpeg(),
      StorePhotoKind.banner,
    );

    expect(banner.width <= kBannerMaxSide, isTrue);
    expect(banner.height <= kBannerMaxSide, isTrue);
    expect(banner.byteLength <= kBannerMaxBytes, isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('an image that cannot be compressed enough is refused with a message',
      () async {
    // A budget no real photo can meet, so the helper reaches its refusal path.
    await expectLater(
      compressStorePhoto(
        bigPhotoJpeg(),
        StorePhotoKind.logo,
        maxBytes: 512,
      ),
      throwsA(isA<ImageTooLargeException>().having(
        (e) => e.message,
        'message',
        'This image is too large. Try a smaller one.',
      )),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a failed storage write leaves the previous image in place', () async {
    SharedPreferences.setMockInitialValues({
      'store_logo_url': 'old-logo',
      'store_banner_url': 'old-banner',
    });
    final provider = StoreProvider();
    await provider.loadFromPrefs();

    final beforeLogo = provider.store.logoUrl;
    final beforeBanner = provider.store.bannerUrl;

    provider.debugFailNextSave = true;
    final saved = await provider.updateStore(
      name: 'Kaduna Greens',
      logoUrl: 'data:image/jpeg;base64,new-logo',
      bannerUrl: 'data:image/jpeg;base64,new-banner',
    );

    expect(saved, isFalse);
    // Rolled back completely — the new image is not shown as saved.
    expect(provider.store.logoUrl, beforeLogo);
    expect(provider.store.bannerUrl, beforeBanner);
    expect(provider.store.name, isNot('Kaduna Greens'));

    // The hook is one-shot: the next save succeeds and persists.
    final retried = await provider.updateStore(
      logoUrl: 'data:image/jpeg;base64,new-logo',
    );
    expect(retried, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('store_logo_url'), 'data:image/jpeg;base64,new-logo');
  });

  test('a failed banner write also restores the stored logo', () async {
    SharedPreferences.setMockInitialValues({
      'store_logo_url': 'old-logo',
      'store_banner_url': 'old-banner',
    });
    final provider = StoreProvider();
    await provider.loadFromPrefs();

    // The logo write lands, then the banner write fails: the stored logo must
    // not keep the value from the half-finished save.
    provider.debugFailBannerWrite = true;
    final saved = await provider.updateStore(
      name: 'Kaduna Greens',
      logoUrl: 'data:image/jpeg;base64,new-logo',
      bannerUrl: 'data:image/jpeg;base64,new-banner',
    );
    expect(saved, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('store_logo_url'), 'old-logo');
    expect(prefs.getString('store_banner_url'), 'old-banner');

    // A reload therefore still shows the previous photos, not the new ones.
    final reloaded = StoreProvider();
    await reloaded.loadFromPrefs();
    expect(reloaded.store.logoUrl, 'old-logo');
    expect(reloaded.store.bannerUrl, 'old-banner');

    // The hook is one-shot: the next save persists both images.
    expect(
      await provider.updateStore(
        logoUrl: 'data:image/jpeg;base64,new-logo',
        bannerUrl: 'data:image/jpeg;base64,new-banner',
      ),
      isTrue,
    );
    expect(prefs.getString('store_logo_url'), 'data:image/jpeg;base64,new-logo');
    expect(
        prefs.getString('store_banner_url'), 'data:image/jpeg;base64,new-banner');
  });

  testWidgets('a failed save shows an error and keeps the old logo',
      (tester) async {
    await tester.runAsync(loadRoboto);
    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: growboxProviders(),
      child: const GrowboxApp(),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    appRouter.go('/store');
    await tester.pumpAndSettle();

    final provider = Provider.of<StoreProvider>(
      tester.element(find.byType(StoreScreen)),
      listen: false,
    );
    final beforeLogo = provider.store.logoUrl;
    provider.debugFailNextSave = true;

    // Open the sheet through the button's callback: the header button can sit
    // below the phone viewport in the test surface.
    tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Edit Store'))
        .onPressed!();
    await tester.pumpAndSettle();
    // Scroll the sheet to its actions row.
    for (var i = 0; i < 3; i++) {
      if (find.text('Save Changes').evaluate().isNotEmpty &&
          tester.getCenter(find.text('Save Changes')).dy < 800) {
        break;
      }
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Could not save your changes. Please try again.'),
        findsOneWidget);
    expect(provider.store.logoUrl, beforeLogo);
  });
}
