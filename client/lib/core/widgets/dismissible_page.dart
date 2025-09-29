import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class _DismissiblePageListener extends StatelessWidget {
  const _DismissiblePageListener({
    required this.parentState,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  }) : super();

  final _DismissiblePageState parentState;
  final ValueChanged<Offset> onStart;
  final ValueChanged<DragEndDetails> onEnd;
  final ValueChanged<DragUpdateDetails> onUpdate;
  final Widget child;

  bool get _dragUnderway => parentState._dragUnderway;

  void _startDrag(DragUpdateDetails? details) {
    if (details == null) return;
    if (!_dragUnderway) {
      parentState._pointerStart = details.globalPosition;
      onStart(details.globalPosition);
    }
  }

  void _updateDrag(DragUpdateDetails? details) {
    if (details != null && details.primaryDelta != null) {
      if (_dragUnderway) {
        onUpdate(details);
      }
    }
  }

  bool _isSameDirections(ScrollMetrics metrics) {
    return metrics.axis == Axis.vertical && metrics.extentBefore == 0;
  }

  bool _onScrollNotification(ScrollNotification scrollInfo) {
    if (_isSameDirections(scrollInfo.metrics)) {
      if (scrollInfo is OverscrollNotification) {
        _startDrag(scrollInfo.dragDetails);
        return false;
      }

      if (scrollInfo is ScrollUpdateNotification) {
        if (scrollInfo.metrics.outOfRange) {
          _startDrag(scrollInfo.dragDetails);
        }
        return false;
      }
    }

    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    parentState._pointerStart = event.position;
    parentState._activePointerCount++;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragUnderway && parentState._activePointerCount != 0) {
      _updateDrag(
        DragUpdateDetails(
          globalPosition: Offset(0, 0),
          delta: Offset(0, event.position.dy - parentState._pointerStart.dy),
          primaryDelta: event.position.dy - parentState._pointerStart.dy,
        ),
      );
      parentState._pointerStart = event.position;
    }
  }

  void _onPointerUp(_) {
    parentState._activePointerCount--;
    if (_dragUnderway && parentState._activePointerCount == 0) {
      onEnd(DragEndDetails());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerCancel: _onPointerUp,
      onPointerUp: _onPointerUp,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: child,
      ),
    );
  }
}

class DismissiblePage extends StatefulWidget {
  const DismissiblePage({
    required this.builder,
    required this.onDismissed,
    required this.active,
    this.movementDuration = const Duration(milliseconds: 400),
    super.key,
  });

  final VoidCallback onDismissed;
  final bool active;
  final Widget Function(BuildContext context, bool isActive) builder;
  final Duration movementDuration;

  @override
  State<DismissiblePage> createState() => _DismissiblePageState();
}

class _DismissiblePageState extends State<DismissiblePage>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  int _activePointerCount = 0;

  Offset _pointerStart = Offset(0, 0);

  bool _dragUnderway = false;

  bool get _isActive => _dragUnderway || _moveController.isAnimating;

  late Animation<Offset> _moveAnimation;
  double _dragExtent = 0;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(duration: Duration.zero, vsync: this);
    _moveController.addStatusListener(_handleDismissStatusChanged);
    _updateMoveAnimation();
  }

  @override
  void dispose() {
    _moveController
      ..removeStatusListener(_handleDismissStatusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleDragStart([DragStartDetails? _]) {
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent =
          _moveController.value * context.size!.height * _dragExtent.sign;
      _moveController.stop();
    } else {
      _dragExtent = 0.0;
      _moveController.value = 0.0;
    }
    setState(_updateMoveAnimation);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController.isAnimating) return;

    final delta = details.primaryDelta;
    final oldDragExtent = _dragExtent;

    if (_dragExtent + delta! > 0) _dragExtent += delta;

    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(_updateMoveAnimation);
    }

    if (!_moveController.isAnimating) {
      _moveController.value = _dragExtent.abs() / context.size!.height;
    }
  }

  void _updateMoveAnimation() {
    final end = _dragExtent.sign;
    _moveAnimation = _moveController.drive(
      Tween<Offset>(begin: Offset.zero, end: Offset(0, end)),
    );
  }

  void _handleDragEnd([DragEndDetails? _]) {
    if (!_isActive || _moveController.isAnimating) return;
    _dragUnderway = false;
    if (!_moveController.isDismissed) {
      if (_moveController.value > 0.35) {
        _moveController
          ..duration = widget.movementDuration
          ..forward();
      } else {
        _moveController
          ..reverseDuration = widget.movementDuration
          ..reverse();
      }
    }
    setState(() {});
  }

  void _handleDismissStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_dragUnderway) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.builder(context, false);
    }
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.deferToChild,
      dragStartBehavior: DragStartBehavior.down,
      child: _DismissiblePageListener(
        onStart: (_) => _handleDragStart(),
        onUpdate: _handleDragUpdate,
        onEnd: _handleDragEnd,
        parentState: this,
        child: AnimatedBuilder(
          animation: _moveAnimation,
          builder: (BuildContext context, Widget? child) {
            return FractionalTranslation(
              translation: Offset(
                _moveAnimation.value.dx,
                _moveAnimation.value.dy,
              ),
              child: child,
            );
          },
          child: widget.builder(context, _dragUnderway),
        ),
      ),
    );
  }
}
