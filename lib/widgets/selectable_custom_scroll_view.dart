import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Widget that enables long-press gesture recognition over multiple [SliverList] items.
///
/// - [sliverLisKey] must be a [Key] linked to the target [SliverList].
/// - [scrollController] must be a valid [ScrollController] linked to the [CustomScrollView] that is parent of the target [SliverList], remember to create it inside [State.initState] and call [ScrollController.dispose] inside of [State.dispose].
/// - [onSelectedItems] a callback that receives a list of key values.
/// - [enableSelect] set to [true] to enable the gesture recognition. I am exposing this API because computing the highlighted items is a expensive computation, so disable this when you are not in a "selection mode".
/// - [child] must be the target [CustomScrollView].
///
/// To see a demo refer to issue [#25](https://github.com/alexrintt/kanade/issues/25).
class ScrollViewLongPressGestureDetector extends StatefulWidget {
  const ScrollViewLongPressGestureDetector({
    super.key,
    required this.sliverLisKey,
    required this.scrollController,
    required this.onSelectedItems,
    required this.child,
    required this.enableSelect,
  });

  final Key sliverLisKey;
  final ScrollController scrollController;
  final void Function(List<String>) onSelectedItems;
  final Widget child;
  final bool enableSelect;

  @override
  State<ScrollViewLongPressGestureDetector> createState() =>
      _ScrollViewLongPressGestureDetectorState();
}

class _ScrollViewLongPressGestureDetectorState
    extends State<ScrollViewLongPressGestureDetector> {
  Offset? _globalInitialDragPosition;
  Offset? _globalFinalDragPosition;

  /// From the given [element], recursively find the target [SliverList] by:
  /// - A given [key], if [filterByKey] is [true].
  /// - A given type [T], must extends of [SliverList].
  ///
  /// Call [visitor] for each [SliverList] child item element.
  void _visitVisibleSliverListChildElements<T extends SliverList>(
    Element element,
    void Function(Element) visitor, {
    Key? key,
    bool filterByKey = true,
  }) {
    _visitVisibleSliverListChildElementsRecursively<T>(
      element,
      visitor,
      filterByKey: filterByKey,
      key: key,
    );
  }

  void _visitVisibleSliverListChildElementsRecursively<T extends SliverList>(
    Element element,
    void Function(Element) visitor, {
    Key? key,
    bool filterByKey = true,
  }) {
    assert(
      (() {
        if (filterByKey) return key != null;
        return true;
      })(),
    );

    element.visitChildElements((Element childElement) {
      final bool keyMatch = !filterByKey || childElement.widget.key == key;
      final bool typeMatch = childElement.widget is T;

      if (keyMatch && typeMatch) {
        childElement.visitChildElements(visitor);
      } else {
        _visitVisibleSliverListChildElements<T>(
          childElement,
          visitor,
          filterByKey: filterByKey,
          key: key,
        );
      }
    });
  }

  void _visitVisiblePackageTileElements(void Function(Element) visitor) {
    _visitVisibleSliverListChildElements(
      context as Element,
      visitor,
      key: widget.sliverLisKey,
    );
  }

  ScrollController get _scrollController => widget.scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (widget.enableSelect) _findAndDetectSelectedListItems();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);

    super.dispose();
  }

  bool _hasRectOverlap(Rect rectA, Rect rectB) {
    return rectA.left < rectB.right &&
        rectA.right > rectB.left &&
        rectA.top < rectB.bottom &&
        rectA.bottom > rectB.top;
  }

  Rect _rectFromPoints(Offset pointA, Offset pointB) {
    final double xa = min(pointA.dx, pointB.dx);
    final double xb = max(pointA.dx, pointB.dx);

    final double ya = min(pointA.dy, pointB.dy);
    final double yb = max(pointA.dy, pointB.dy);

    return Rect.fromLTRB(xa, ya, xb, yb);
  }

  void _findAndDetectSelectedListItems() {
    final List<String> selectedListItemKeyValues = <String>[];

    _visitVisiblePackageTileElements((Element tileElement) {
      final RenderBox? renderBox = tileElement.findRenderObject() as RenderBox?;

      if (renderBox == null) return;

      final Offset tilePosition =
          renderBox.localToGlobal(_scrollControllerOffset);

      if (_globalInitialDragPosition == null) return;

      final Offset dragStartGlobalPosition =
          _globalInitialDragPosition! + _scrollControllerOffset;

      final Offset dragFinalGlobalPosition =
          (_globalFinalDragPosition ?? _globalInitialDragPosition!) +
              _scrollControllerOffset;

      final Rect pointerRect =
          _rectFromPoints(dragStartGlobalPosition, dragFinalGlobalPosition);

      final Rect tileRect = _rectFromPoints(
        tilePosition,
        Offset(
          tilePosition.dx + renderBox.size.width,
          tilePosition.dy + renderBox.size.height,
        ),
      );

      final bool hasOverlap = _hasRectOverlap(tileRect, pointerRect);

      if (hasOverlap) {
        // This [parseValueKey] is required because [SliverList] wraps each
        // child into a private class [_SaltedValueKey] which we cannot import
        // or get the raw String original value directly.
        // See https://github.com/flutter/flutter/blob/08a2635e2b725c951ff0471eb9c556b375aa5d7a/packages/flutter/lib/src/widgets/sliver.dart#L229-L231
        T parseValueKey<T>(Key key) {
          if (key is ValueKey<T>) {
            return key.value;
          }
          return parseValueKey((key as ValueKey<dynamic>).value as Key);
        }

        assert(
          tileElement.widget.key != null,
          '''You must provide a key to each list item child of ${widget.sliverLisKey}''',
        );

        final String listItemKeyValue =
            parseValueKey<String>(tileElement.widget.key!);

        selectedListItemKeyValues.add(listItemKeyValue);
      }
    });

    widget.onSelectedItems(selectedListItemKeyValues);
  }

  Offset get _scrollControllerOffset => Offset(0, _scrollController.offset);

  double get _maxScrollExtent => _scrollController.position.maxScrollExtent;
  double get _minScrollExtent => _scrollController.position.minScrollExtent;

  double _velocity = 4.0;

  double get _pixelRatio => window.devicePixelRatio;
  Size get _logicalScreenSize => window.physicalSize / _pixelRatio;
  double get _logicalHeight => _logicalScreenSize.height;

  void _autoscrollListener() {
    _velocity = _acceleration * _logicalHeight / 10;

    final double step =
        _autoscrollDirection == AxisDirection.up ? -_velocity : _velocity;

    final double newOffset = (_scrollControllerOffset.dy + step)
        .clamp(_minScrollExtent, _maxScrollExtent);

    _scrollController.jumpTo(newOffset);

    // We need to call it here to updating the selected items when the list is autoscrolling down
    // or up and the user doesn't move the finger.
    //
    // When that happens the [_findAndDetectSelectedListItems] is not called thus the [onSelectedItems]
    // callback is also not called, which results in the list not updating the selected items.
    _findAndDetectSelectedListItems();
  }

  StreamSubscription<void>? _autoscrollStreamSubscription;

  Future<void> _startAutoscrolling() async {
    const int kFps = 60;
    const int k1s = 1000;

    _autoscrollStreamSubscription =
        Stream<void>.periodic(const Duration(milliseconds: k1s ~/ kFps))
            .listen((_) => _autoscrollListener());
  }

  Future<void> _stopAutoscroll() async {
    _autoscrollDirection = null;
    await _autoscrollStreamSubscription?.cancel();
  }

  void _endAutoscrollFeature() {
    _calcAutoscrollDirectionAndForce();
    _stopAutoscroll();
  }

  void _updateAutoscrollFeature() {
    _calcAutoscrollDirectionAndForce();
  }

  Future<void> _startAutoscrollFeature() async {
    _calcAutoscrollDirectionAndForce();
    await _startAutoscrolling();
  }

  AxisDirection? _autoscrollDirection;
  double _acceleration = 0.0;

  void _calcAutoscrollDirectionAndForce() {
    final Offset? pointer =
        _globalFinalDragPosition ?? _globalInitialDragPosition;
    final bool hasPointer = pointer != null;

    const double kAutoscrollArea = kToolbarHeight * 2;

    final double topDiff = hasPointer ? 1 - pointer.dy / kAutoscrollArea : 0.0;
    final double bottomDiff = hasPointer
        ? 1 - (pointer.dy - _logicalHeight).abs() / kAutoscrollArea
        : 0.0;

    final bool shouldAutoscrollToTop =
        hasPointer && pointer.dy <= kAutoscrollArea;

    final bool shouldAutoscrollToBottom =
        hasPointer && pointer.dy >= _logicalHeight - kAutoscrollArea;

    if (shouldAutoscrollToTop) {
      _autoscrollDirection = AxisDirection.up;
      _acceleration = topDiff;
    } else if (shouldAutoscrollToBottom) {
      _autoscrollDirection = AxisDirection.down;
      _acceleration = bottomDiff;
    } else {
      _autoscrollDirection = null;
      _acceleration = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        _globalInitialDragPosition = details.globalPosition;
        _startAutoscrollFeature();
      },
      onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
        _globalFinalDragPosition = details.globalPosition;

        _findAndDetectSelectedListItems();
        _updateAutoscrollFeature();
      },
      onLongPressEnd: (LongPressEndDetails details) {
        _globalInitialDragPosition = null;
        _globalFinalDragPosition = null;
        _endAutoscrollFeature();
      },
      onLongPressCancel: () {
        _globalInitialDragPosition = null;
        _globalFinalDragPosition = null;
        _endAutoscrollFeature();
      },
      onLongPress: () {
        _findAndDetectSelectedListItems();
      },
      child: widget.child,
    );
  }
}
