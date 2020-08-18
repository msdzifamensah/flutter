// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

void main() {
  const Offset forcePressOffset = Offset(400.0, 50.0);

  testWidgets('Uncontested scrolls start immediately', (WidgetTester tester) async {
    bool didStartDrag = false;
    double updatedDragDelta;
    bool didEndDrag = false;

    final Widget widget = GestureDetector(
      onVerticalDragStart: (DragStartDetails details) {
        didStartDrag = true;
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        updatedDragDelta = details.primaryDelta;
      },
      onVerticalDragEnd: (DragEndDetails details) {
        didEndDrag = true;
      },
      child: Container(
        color: const Color(0xFF00FF00),
      ),
    );

    await tester.pumpWidget(widget);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isFalse);

    const Offset firstLocation = Offset(10.0, 10.0);
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isFalse);

    const Offset secondLocation = Offset(10.0, 9.0);
    await gesture.moveTo(secondLocation);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, -1.0);
    updatedDragDelta = null;
    expect(didEndDrag, isFalse);

    await gesture.up();
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;

    await tester.pumpWidget(Container());
  });

  testWidgets('Match two scroll gestures in succession', (WidgetTester tester) async {
    int gestureCount = 0;
    double dragDistance = 0.0;

    const Offset downLocation = Offset(10.0, 10.0);
    const Offset upLocation = Offset(10.0, 50.0); // must be far enough to be more than kTouchSlop

    final Widget widget = GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      onVerticalDragUpdate: (DragUpdateDetails details) { dragDistance += details.primaryDelta; },
      onVerticalDragEnd: (DragEndDetails details) { gestureCount += 1; },
      onHorizontalDragUpdate: (DragUpdateDetails details) { fail('gesture should not match'); },
      onHorizontalDragEnd: (DragEndDetails details) { fail('gesture should not match'); },
      child: Container(
        color: const Color(0xFF00FF00),
      ),
    );
    await tester.pumpWidget(widget);

    TestGesture gesture = await tester.startGesture(downLocation, pointer: 7);
    await gesture.moveTo(upLocation);
    await gesture.up();

    gesture = await tester.startGesture(downLocation, pointer: 7);
    await gesture.moveTo(upLocation);
    await gesture.up();

    expect(gestureCount, 2);
    expect(dragDistance, 40.0 * 2.0); // delta between down and up, twice

    await tester.pumpWidget(Container());
  });

  testWidgets("Pan doesn't crash", (WidgetTester tester) async {
    bool didStartPan = false;
    Offset panDelta;
    bool didEndPan = false;

    await tester.pumpWidget(
      GestureDetector(
        onPanStart: (DragStartDetails details) {
          didStartPan = true;
        },
        onPanUpdate: (DragUpdateDetails details) {
          panDelta = panDelta == null ? details.delta : panDelta + details.delta;
        },
        onPanEnd: (DragEndDetails details) {
          didEndPan = true;
        },
        child: Container(
          color: const Color(0xFF00FF00),
        ),
      ),
    );

    expect(didStartPan, isFalse);
    expect(panDelta, isNull);
    expect(didEndPan, isFalse);

    await tester.dragFrom(const Offset(10.0, 10.0), const Offset(20.0, 30.0));

    expect(didStartPan, isTrue);
    expect(panDelta.dx, 20.0);
    expect(panDelta.dy, 30.0);
    expect(didEndPan, isTrue);
  });

  group('Tap', () {
    final ButtonVariant buttonVariant = ButtonVariant(
      values: <int>[kPrimaryButton, kSecondaryButton, kTertiaryButton],
      descriptions: <int, String>{
        kPrimaryButton: 'primary',
        kSecondaryButton: 'secondary',
        kTertiaryButton: 'tertiary',
      },
    );

    testWidgets('Translucent', (WidgetTester tester) async {
      bool didReceivePointerDown;
      bool didTap;

      Future<void> pumpWidgetTree(HitTestBehavior behavior) {
        return tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: <Widget>[
                Listener(
                  onPointerDown: (_) {
                    didReceivePointerDown = true;
                  },
                  child: Container(
                    width: 100.0,
                    height: 100.0,
                    color: const Color(0xFF00FF00),
                  ),
                ),
                Container(
                  width: 100.0,
                  height: 100.0,
                  child: GestureDetector(
                    onTap: ButtonVariant.button == kPrimaryButton ? () {
                      didTap = true;
                    } : null,
                    onSecondaryTap: ButtonVariant.button == kSecondaryButton ? () {
                      didTap = true;
                    } : null,
                    onTertiaryTapDown: ButtonVariant.button == kTertiaryButton ? (_) {
                      didTap = true;
                    } : null,
                    behavior: behavior,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      didReceivePointerDown = false;
      didTap = false;
      await pumpWidgetTree(null);
      await tester.tapAt(const Offset(10.0, 10.0), buttons: ButtonVariant.button);
      expect(didReceivePointerDown, isTrue);
      expect(didTap, isTrue);

      didReceivePointerDown = false;
      didTap = false;
      await pumpWidgetTree(HitTestBehavior.deferToChild);
      await tester.tapAt(const Offset(10.0, 10.0), buttons: ButtonVariant.button);
      expect(didReceivePointerDown, isTrue);
      expect(didTap, isFalse);

      didReceivePointerDown = false;
      didTap = false;
      await pumpWidgetTree(HitTestBehavior.opaque);
      await tester.tapAt(const Offset(10.0, 10.0), buttons: ButtonVariant.button);
      expect(didReceivePointerDown, isFalse);
      expect(didTap, isTrue);

      didReceivePointerDown = false;
      didTap = false;
      await pumpWidgetTree(HitTestBehavior.translucent);
      await tester.tapAt(const Offset(10.0, 10.0), buttons: ButtonVariant.button);
      expect(didReceivePointerDown, isTrue);
      expect(didTap, isTrue);
    }, variant: buttonVariant);

    testWidgets('Empty', (WidgetTester tester) async {
      bool didTap = false;
      await tester.pumpWidget(
        Center(
          child: GestureDetector(
            onTap: ButtonVariant.button == kPrimaryButton ? () {
              didTap = true;
            } : null,
            onSecondaryTap: ButtonVariant.button == kSecondaryButton ? () {
              didTap = true;
            } : null,
            onTertiaryTapUp: ButtonVariant.button == kTertiaryButton ? (_) {
              didTap = true;
            } : null,
          ),
        ),
      );
      expect(didTap, isFalse);
      await tester.tapAt(const Offset(10.0, 10.0), buttons: ButtonVariant.button);
      expect(didTap, isTrue);
    }, variant: buttonVariant);

    testWidgets('Only container', (WidgetTester tester) async {
      bool didTap = false;
      await tester.pumpWidget(
        Center(
          child: GestureDetector(
            onTap: ButtonVariant.button == kPrimaryButton ? () {
              didTap = true;
            } : null,
            onSecondaryTap: ButtonVariant.button == kSecondaryButton ? () {
              didTap = true;
            } : null,
            onTertiaryTapUp: ButtonVariant.button == kTertiaryButton ? (_) {
              didTap = true;
            } : null,
            child: Container(),
          ),
        ),
      );
      expect(didTap, isFalse);
      await tester.tapAt(const Offset(10.0, 10.0));
      expect(didTap, isFalse);
    }, variant: buttonVariant);

    testWidgets('cache render object', (WidgetTester tester) async {
      final GestureTapCallback inputCallback = () { };

      await tester.pumpWidget(
        Center(
          child: GestureDetector(
            onTap: ButtonVariant.button == kPrimaryButton ? inputCallback : null,
            onSecondaryTap: ButtonVariant.button == kSecondaryButton ? inputCallback : null,
            onTertiaryTapUp: ButtonVariant.button == kTertiaryButton ? (_) => inputCallback() : null,
            child: Container(),
          ),
        ),
      );

      final RenderSemanticsGestureHandler renderObj1 = tester.renderObject(find.byType(GestureDetector));

      await tester.pumpWidget(
        Center(
          child: GestureDetector(
            onTap: ButtonVariant.button == kPrimaryButton ? inputCallback : null,
            onSecondaryTap: ButtonVariant.button == kSecondaryButton ? inputCallback : null,
            onTertiaryTapUp: ButtonVariant.button == kTertiaryButton ? (_) => inputCallback() : null,
            child: Container(),
          ),
        ),
      );

      final RenderSemanticsGestureHandler renderObj2 = tester.renderObject(find.byType(GestureDetector));

      expect(renderObj1, same(renderObj2));
    }, variant: buttonVariant);

    testWidgets('Tap down occurs after kPressTimeout', (WidgetTester tester) async {
      int tapDown = 0;
      int tap = 0;
      int tapCancel = 0;
      int longPress = 0;

      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Container(
            alignment: Alignment.center,
            height: 100.0,
            color: const Color(0xFF00FF00),
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              // Adding long press callbacks here will cause the on*TapDown callbacks to be executed only after
              // kPressTimeout has passed. Without the long press callbacks, there would be no press pointers
              // competing in the arena. Hence, we add them to the arena to test this behavior.
              //
              // We use a raw gesture detector directly here because gesture detector does
              // not expose callbacks for the tertiary variant of long presses, i.e. no onTertiaryLongPress*
              // callbacks are exposed in GestureDetector.
              //
              // The primary and secondary long press callbacks could also be put into the gesture detector below,
              // however, it is clearer when they are all in one place.
              gestures: <Type, GestureRecognizerFactory>{
                LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer(),
                  (LongPressGestureRecognizer instance) {
                    instance
                      ..onLongPress = ButtonVariant.button == kPrimaryButton ? () {
                        longPress += 1;
                      } : null
                      ..onSecondaryLongPress = ButtonVariant.button == kSecondaryButton ? () {
                        longPress += 1;
                      } : null
                      ..onTertiaryLongPress = ButtonVariant.button == kTertiaryButton ? () {
                        longPress += 1;
                      } : null;
                  },
                ),
              },
              child: GestureDetector(
                onTapDown: ButtonVariant.button == kPrimaryButton ? (TapDownDetails details) {
                  tapDown += 1;
                } : null,
                onSecondaryTapDown: ButtonVariant.button == kSecondaryButton ? (TapDownDetails details) {
                  tapDown += 1;
                } : null,
                onTertiaryTapDown: ButtonVariant.button == kTertiaryButton ? (TapDownDetails details) {
                  tapDown += 1;
                } : null,
                onTap: ButtonVariant.button == kPrimaryButton ? () {
                  tap += 1;
                } : null,
                onSecondaryTap: ButtonVariant.button == kSecondaryButton ? () {
                  tap += 1;
                } : null,
                onTertiaryTapUp: ButtonVariant.button == kTertiaryButton ? (TapUpDetails details) {
                  tap += 1;
                } : null,
                onTapCancel: ButtonVariant.button == kPrimaryButton ? () {
                  tapCancel += 1;
                } : null,
                onSecondaryTapCancel: ButtonVariant.button == kSecondaryButton ? () {
                  tapCancel += 1;
                } : null,
                onTertiaryTapCancel: ButtonVariant.button == kTertiaryButton ? () {
                  tapCancel += 1;
                } : null,
              ),
            ),
          ),
        ),
      );

      // Pointer is dragged from the center of the 800x100 gesture detector
      // to a point (400,300) below it. This should never call onTap.
      Future<void> dragOut(Duration timeout) async {
        final TestGesture gesture =
        await tester.startGesture(const Offset(400.0, 50.0), buttons: ButtonVariant.button);
        // If the timeout is less than kPressTimeout the recognizer will not
        // trigger any callbacks. If the timeout is greater than kLongPressTimeout
        // then onTapDown, onLongPress, and onCancel will be called.
        await tester.pump(timeout);
        await gesture.moveTo(const Offset(400.0, 300.0));
        await gesture.up();
      }

      await dragOut(kPressTimeout * 0.5); // generates nothing
      expect(tapDown, 0);
      expect(tapCancel, 0);
      expect(tap, 0);
      expect(longPress, 0);

      await dragOut(kPressTimeout); // generates tapDown, tapCancel
      expect(tapDown, 1);
      expect(tapCancel, 1);
      expect(tap, 0);
      expect(longPress, 0);

      await dragOut(kLongPressTimeout); // generates tapDown, longPress, tapCancel
      expect(tapDown, 2);
      expect(tapCancel, 2);
      expect(tap, 0);
      expect(longPress, 1);
    }, variant: buttonVariant);

    testWidgets('Long Press Up Callback called after long press', (WidgetTester tester) async {
      int longPressUp = 0;

      await tester.pumpWidget(
        Container(
          alignment: Alignment.topLeft,
          child: Container(
            alignment: Alignment.center,
            height: 100.0,
            color: const Color(0xFF00FF00),
            child: RawGestureDetector(
              // We use a raw gesture detector directly here because gesture detector does
              // not expose callbacks for the tertiary variant of long presses, i.e. no onTertiaryLongPress*
              // callbacks are exposed in GestureDetector, and we want to test all three variants.
              //
              // The primary and secondary long press callbacks could also be put into the gesture detector below,
              // however, it is more convenient to have them all in one place.
              gestures: <Type, GestureRecognizerFactory>{
                LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                      () => LongPressGestureRecognizer(),
                      (LongPressGestureRecognizer instance) {
                    instance
                      ..onLongPressUp = ButtonVariant.button == kPrimaryButton ? () {
                        longPressUp += 1;
                      } : null
                      ..onSecondaryLongPressUp = ButtonVariant.button == kSecondaryButton ? () {
                        longPressUp += 1;
                      } : null
                      ..onTertiaryLongPressUp = ButtonVariant.button == kTertiaryButton ? () {
                        longPressUp += 1;
                      } : null;
                  },
                ),
              },
            ),
          ),
        ),
      );

      Future<void> longPress(Duration timeout) async {
        final TestGesture gesture = await tester.startGesture(const Offset(400.0, 50.0), buttons: ButtonVariant.button);
        await tester.pump(timeout);
        await gesture.up();
      }

      await longPress(kLongPressTimeout + const Duration(seconds: 1)); // To make sure the time for long press has occurred
      expect(longPressUp, 1);
    }, variant: buttonVariant);
  });

  testWidgets('Primary and secondary long press callbacks should work together in GestureDetector', (WidgetTester tester) async {
    bool primaryLongPress = false, secondaryLongPress = false;

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Container(
          alignment: Alignment.center,
          height: 100.0,
          color: const Color(0xFF00FF00),
          child: GestureDetector(
            onLongPress: () {
              primaryLongPress = true;
            },
            onSecondaryLongPress: () {
              secondaryLongPress = true;
            },
          ),
        ),
      ),
    );

    Future<void> longPress(Duration timeout, int buttons) async {
      final TestGesture gesture = await tester.startGesture(const Offset(400.0, 50.0), buttons: buttons);
      await tester.pump(timeout);
      await gesture.up();
    }

    // Adding a second to make sure the time for long press has occurred.
    await longPress(kLongPressTimeout + const Duration(seconds: 1), kPrimaryButton);
    expect(primaryLongPress, isTrue);

    await longPress(kLongPressTimeout + const Duration(seconds: 1), kSecondaryButton);
    expect(secondaryLongPress, isTrue);
  });

  testWidgets('Force Press Callback called after force press', (WidgetTester tester) async {
    int forcePressStart = 0;
    int forcePressPeaked = 0;
    int forcePressUpdate = 0;
    int forcePressEnded = 0;

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Container(
          alignment: Alignment.center,
          height: 100.0,
          color: const Color(0xFF00FF00),
          child: GestureDetector(
            onForcePressStart: (_) => forcePressStart += 1,
            onForcePressEnd: (_) => forcePressEnded += 1,
            onForcePressPeak: (_) => forcePressPeaked += 1,
            onForcePressUpdate: (_) => forcePressUpdate += 1,
          ),
        ),
      ),
    );
    final int pointerValue = tester.nextPointer;

    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.3,
      pressureMin: 0,
      pressureMax: 1,
    ));

    expect(forcePressStart, 0);
    expect(forcePressPeaked, 0);
    expect(forcePressUpdate, 0);
    expect(forcePressEnded, 0);

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1
    ));

    expect(forcePressStart, 1);
    expect(forcePressPeaked, 0);
    expect(forcePressUpdate, 1);
    expect(forcePressEnded, 0);

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.6,
      pressureMin: 0,
      pressureMax: 1,
    ));
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.7,
      pressureMin: 0,
      pressureMax: 1
    ));
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.2,
      pressureMin: 0,
      pressureMax: 1
    ));
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.3,
      pressureMin: 0,
      pressureMax: 1
    ));

    expect(forcePressStart, 1);
    expect(forcePressPeaked, 0);
    expect(forcePressUpdate, 5);
    expect(forcePressEnded, 0);

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.9,
      pressureMin: 0,
      pressureMax: 1,
    ));

    expect(forcePressStart, 1);
    expect(forcePressPeaked, 1);
    expect(forcePressUpdate, 6);
    expect(forcePressEnded, 0);

    await gesture.up();

    expect(forcePressStart, 1);
    expect(forcePressPeaked, 1);
    expect(forcePressUpdate, 6);
    expect(forcePressEnded, 1);
  });

  testWidgets('Force Press Callback not called if long press triggered before force press', (WidgetTester tester) async {
    int forcePressStart = 0;
    int longPressTimes = 0;

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Container(
          alignment: Alignment.center,
          height: 100.0,
          color: const Color(0xFF00FF00),
          child: GestureDetector(
            onForcePressStart: (_) => forcePressStart += 1,
            onLongPress: () => longPressTimes += 1,
          ),
        ),
      ),
    );

    final int pointerValue = tester.nextPointer;
    const double maxPressure = 6.0;

    final TestGesture gesture = await tester.createGesture();

    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: maxPressure,
        pressureMin: 0.0,
      ),
    );

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(400.0, 50.0),
      pressure: 0.3,
      pressureMin: 0,
      pressureMax: maxPressure
    ));

    expect(forcePressStart, 0);
    expect(longPressTimes, 0);

    // Trigger the long press.
    await tester.pump(kLongPressTimeout + const Duration(seconds: 1));

    expect(longPressTimes, 1);
    expect(forcePressStart, 0);

    // Failed attempt to trigger the force press.
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(400.0, 50.0),
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: maxPressure
    ));

    expect(longPressTimes, 1);
    expect(forcePressStart, 0);
  });

  testWidgets('Force Press Callback not called if drag triggered before force press', (WidgetTester tester) async {
    int forcePressStart = 0;
    int horizontalDragStart = 0;

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Container(
          alignment: Alignment.center,
          height: 100.0,
          color: const Color(0xFF00FF00),
          child: GestureDetector(
            onForcePressStart: (_) => forcePressStart += 1,
            onHorizontalDragStart: (_) => horizontalDragStart += 1,
          ),
        ),
      ),
    );

    final int pointerValue = tester.nextPointer;

    final TestGesture gesture = await tester.createGesture();

    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.3,
      pressureMin: 0,
      pressureMax: 1
    ));

    expect(forcePressStart, 0);
    expect(horizontalDragStart, 0);

    // Trigger horizontal drag.
    await gesture.moveBy(const Offset(100, 0));

    expect(horizontalDragStart, 1);
    expect(forcePressStart, 0);

    // Failed attempt to trigger the force press.
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: const Offset(0.0, 0.0),
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1,
    ));

    expect(horizontalDragStart, 1);
    expect(forcePressStart, 0);
  });

  group("RawGestureDetectorState's debugFillProperties", () {
    testWidgets('when default', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(RawGestureDetector(
        key: key,
      ));
      key.currentState.debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

      expect(description, <String>[
        'gestures: <none>',
      ]);
    });

    testWidgets('should show gestures, custom semantics and behavior', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(RawGestureDetector(
        key: key,
        behavior: HitTestBehavior.deferToChild,
        gestures: <Type, GestureRecognizerFactory>{
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (TapGestureRecognizer recognizer) {
              recognizer.onTap = () {};
            },
          ),
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(),
            (LongPressGestureRecognizer recognizer) {
              recognizer.onLongPress = () {};
            },
          ),
        },
        child: Container(),
        semantics: _EmptySemanticsGestureDelegate(),
      ));
      key.currentState.debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

      expect(description, <String>[
        'gestures: tap, long press',
        'semantics: _EmptySemanticsGestureDelegate()',
        'behavior: deferToChild',
      ]);
    });

    testWidgets('should not show semantics when excludeFromSemantics is true', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(RawGestureDetector(
        key: key,
        gestures: const <Type, GestureRecognizerFactory>{},
        child: Container(),
        semantics: _EmptySemanticsGestureDelegate(),
        excludeFromSemantics: true,
      ));
      key.currentState.debugFillProperties(builder);

      final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

      expect(description, <String>[
        'gestures: <none>',
        'excludeFromSemantics: true',
      ]);
    });

    group('error control test', () {
      test('constructor redundant pan and scale', () {
        FlutterError error;
        try {
          GestureDetector(onScaleStart: (_) {}, onPanStart: (_) {},);
        } on FlutterError catch (e) {
          error = e;
        } finally {
          expect(error, isNotNull);
          expect(
            error.toStringDeep(),
            'FlutterError\n'
            '   Incorrect GestureDetector arguments.\n'
            '   Having both a pan gesture recognizer and a scale gesture\n'
            '   recognizer is redundant; scale is a superset of pan.\n'
            '   Just use the scale gesture recognizer.\n',
          );
          expect(error.diagnostics.last.level, DiagnosticLevel.hint);
          expect(
            error.diagnostics.last.toStringDeep(),
            equalsIgnoringHashCodes(
              'Just use the scale gesture recognizer.\n',
            )
          );
        }
      });

      test('constructor duplicate drag recognizer', () {
        FlutterError error;
        try {
          GestureDetector(
            onVerticalDragStart: (_) {},
            onHorizontalDragStart: (_) {},
            onPanStart: (_) {},
          );
        } on FlutterError catch (e) {
          error = e;
        } finally {
          expect(error, isNotNull);
          expect(
            error.toStringDeep(),
            'FlutterError\n'
            '   Incorrect GestureDetector arguments.\n'
            '   Simultaneously having a vertical drag gesture recognizer, a\n'
            '   horizontal drag gesture recognizer, and a pan gesture recognizer\n'
            '   will result in the pan gesture recognizer being ignored, since\n'
            '   the other two will catch all drags.\n',
          );
        }
      });

      testWidgets('replaceGestureRecognizers not during layout', (WidgetTester tester) async {
        final GlobalKey<RawGestureDetectorState> key = GlobalKey<RawGestureDetectorState>();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RawGestureDetector(
              key: key,
              child: Container(
                child: const Text('Text'),
              ),
            ),
          ),
        );
        FlutterError error;
        try {
          key.currentState.replaceGestureRecognizers(
            <Type, GestureRecognizerFactory>{});
        } on FlutterError catch (e) {
          error = e;
        } finally {
          expect(error, isNotNull);
          expect(error.diagnostics.last.level, DiagnosticLevel.hint);
          expect(
            error.diagnostics.last.toStringDeep(),
            equalsIgnoringHashCodes(
              'To set the gesture recognizers at other times, trigger a new\n'
              'build using setState() and provide the new gesture recognizers as\n'
              'constructor arguments to the corresponding RawGestureDetector or\n'
              'GestureDetector object.\n'
            ),
          );
          expect(
            error.toStringDeep(),
            'FlutterError\n'
            '   Unexpected call to replaceGestureRecognizers() method of\n'
            '   RawGestureDetectorState.\n'
            '   The replaceGestureRecognizers() method can only be called during\n'
            '   the layout phase.\n'
            '   To set the gesture recognizers at other times, trigger a new\n'
            '   build using setState() and provide the new gesture recognizers as\n'
            '   constructor arguments to the corresponding RawGestureDetector or\n'
            '   GestureDetector object.\n',
          );
        }
      });
    });
  });
}

class _EmptySemanticsGestureDelegate extends SemanticsGestureDelegate {
  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {
  }
}

/// A [TestVariant] that runs tests multiple times with different buttons.
class ButtonVariant extends TestVariant<int> {
  const ButtonVariant({
    @required this.values,
    @required this.descriptions,
  }) : assert(values.length != 0); // ignore: prefer_is_empty

  @override
  final List<int> values;

  final Map<int, String> descriptions;

  static int button;

  @override
  String describeValue(int value) {
    assert(descriptions.containsKey(value), 'Unknown button');
    return descriptions[value];
  }

  @override
  Future<int> setUp(int value) async {
    final int oldValue = button;
    button = value;
    return oldValue;
  }

  @override
  Future<void> tearDown(int value, int memento) async {
    button = memento;
  }
}
