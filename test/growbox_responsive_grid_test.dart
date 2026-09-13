import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growbox_vendor/shared/widgets/growbox_responsive_grid.dart';

Widget _host(List<ResponsiveGridItem> items) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: GrowboxResponsiveGrid(items: items),
      ),
    ),
  );
}

Widget _card(String label, Key key) {
  return Container(
    key: key,
    height: 50,
    alignment: Alignment.center,
    color: Colors.blue,
    child: Text(label),
  );
}

void main() {
  testWidgets('single-span items share one row of equal widths',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host([
      ResponsiveGridItem(_card('a', Key('a'))),
      ResponsiveGridItem(_card('b', Key('b'))),
      ResponsiveGridItem(_card('c', Key('c'))),
    ]));

    double widthOf(String label) =>
        tester.getSize(find.byKey(Key(label))).width;
    double topOf(String label) =>
        tester.getTopLeft(find.byKey(Key(label))).dy;
    double leftOf(String label) =>
        tester.getTopLeft(find.byKey(Key(label))).dx;

    // Wide layout (default breakpoint 900) → 3 columns, one row.
    final w = widthOf('a');
    expect(w, moreOrLessEquals(widthOf('b')));
    expect(w, moreOrLessEquals(widthOf('c')));
    expect(topOf('a'), topOf('b'));
    expect(leftOf('b'), greaterThan(leftOf('a')));
    expect(leftOf('c'), greaterThan(leftOf('b')));
  });

  testWidgets('item wider than the remaining row wraps to the next row',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host([
      ResponsiveGridItem(_card('a', Key('a'))),
      // Needs 1 + 2 = 3 columns of a 3-column row → fills row 1 exactly.
      ResponsiveGridItem(_card('b', Key('b')), wideSpan: 2),
      // Wraps to row 2, alone.
      ResponsiveGridItem(_card('c', Key('c'))),
    ]));

    double widthOf(String label) =>
        tester.getSize(find.byKey(Key(label))).width;
    double topOf(String label) =>
        tester.getTopLeft(find.byKey(Key(label))).dy;

    expect(topOf('c'), greaterThan(topOf('a')));
    // 'b' spans two of the three columns on row 1.
    expect(widthOf('b'), moreOrLessEquals(widthOf('a') * 2, epsilon: 1));
  });

  testWidgets('wideSpan 2 pairs with a single-span item on one row',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host([
      ResponsiveGridItem(_card('a', Key('a'))),
      ResponsiveGridItem(_card('wide', Key('wide')), wideSpan: 2),
    ]));

    double widthOf(String label) =>
        tester.getSize(find.byKey(Key(label))).width;
    double topOf(String label) =>
        tester.getTopLeft(find.byKey(Key(label))).dy;

    expect(widthOf('wide'), moreOrLessEquals(widthOf('a') * 2, epsilon: 1));
    expect(topOf('wide'), topOf('a'));
  });

  testWidgets('narrow layout uses narrowColumns and narrowSpan',
      (tester) async {
    tester.view.physicalSize = const Size(700, 800); // below 900 breakpoint
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host([
      ResponsiveGridItem(_card('a', Key('a'))),
      ResponsiveGridItem(_card('b', Key('b'))),
      // narrowSpan 2 → full row at 2 columns.
      ResponsiveGridItem(_card('full', Key('full')), narrowSpan: 2),
    ]));

    double widthOf(String label) =>
        tester.getSize(find.byKey(Key(label))).width;
    double topOf(String label) =>
        tester.getTopLeft(find.byKey(Key(label))).dy;

    // 2 columns: a and b each take half the width; 'full' (alone on its
    // row) takes the whole row.
    expect(widthOf('a'), moreOrLessEquals(widthOf('b')));
    expect(widthOf('full'), greaterThan(widthOf('a')));
    expect(topOf('full'), greaterThan(topOf('a')));
    expect(topOf('a'), topOf('b'));
  });

  testWidgets('same items lay out differently across the breakpoint',
      (tester) async {
    double widthOf(String label) =>
        tester.getSize(find.byKey(Key(label))).width;
    double topOf(String label) =>
        tester.getTopLeft(find.byKey(Key(label))).dy;

    final items = [
      ResponsiveGridItem(_card('a', Key('a'))),
      ResponsiveGridItem(_card('b', Key('b'))),
      ResponsiveGridItem(_card('full', Key('full')), narrowSpan: 2),
    ];

    // Narrow: full-row card below the two half cards.
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_host(items));
    final narrowTop = topOf('full');
    final narrowCardWidth = widthOf('a');
    await tester.pumpWidget(const SizedBox.shrink());

    // Wide: three columns, so 'full' (wideSpan defaults to 1) sits inline.
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_host(items));

    expect(topOf('full'), topOf('a'));
    expect(narrowTop, greaterThan(topOf('a')));
    // Exact column math: (700 - 16 gap) / 2 vs (1200 - 32 gaps) / 3.
    expect(narrowCardWidth, moreOrLessEquals(342, epsilon: 1));
    expect(widthOf('a'), moreOrLessEquals(389.3, epsilon: 1));
  });

  testWidgets('spans are clamped to the current column count',
      (tester) async {
    tester.view.physicalSize = const Size(700, 800); // 2 columns narrow
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host([
      // narrowSpan 4 > 2 columns → clamped to a full row.
      ResponsiveGridItem(_card('big', Key('big')), narrowSpan: 4),
    ]));

    expect(
        tester.getSize(find.byKey(Key('big'))).width, greaterThan(600));
  });
}
