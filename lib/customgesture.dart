import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

typedef OnDrawGesture = void Function(bool left);

class CustomGesture extends StatefulWidget {

  Widget child;
  HitTestBehavior behavior;
  OnDrawGesture onDrawGesture = (left) => {};

  CustomGesture({Key key,
    this.child,
    this.behavior,
    this.onDrawGesture}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CustomGestureState();
  }

}

class CustomGestureState extends State<CustomGesture> {

  Map<Type, GestureRecognizer> _recognizers = const <Type, GestureRecognizer>{};
  final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};

  HitTestBehavior get _defaultBehavior {
    return widget.child == null ? HitTestBehavior.translucent : HitTestBehavior.deferToChild;
  }

  void _handlePointerDown(PointerDownEvent event) {
    for (GestureRecognizer recognizer in _recognizers.values)
      recognizer.addPointer(event);
  }

  @override
  void initState() {
    super.initState();
    if (widget.onDrawGesture != null) {
      gestures[DrawGestureRecognizer] = GestureRecognizerFactoryWithHandlers<DrawGestureRecognizer>(
            () => DrawGestureRecognizer(debugOwner: this),
            (DrawGestureRecognizer instance) {
          instance
            ..onDrawGesture = widget.onDrawGesture;
        },
      );
    }

    _syncAll(gestures);
  }

  void _syncAll(Map<Type, GestureRecognizerFactory> gestures) {
    assert(_recognizers != null);
    final Map<Type, GestureRecognizer> oldRecognizers = _recognizers;
    _recognizers = <Type, GestureRecognizer>{};
    for (Type type in gestures.keys) {
      assert(gestures[type] != null);
      assert(!_recognizers.containsKey(type));
      _recognizers[type] = oldRecognizers[type] ?? gestures[type].constructor();
      assert(_recognizers[type].runtimeType == type, 'GestureRecognizerFactory of type $type created a GestureRecognizer of type ${_recognizers[type].runtimeType}. The GestureRecognizerFactory must be specialized with the type of the class that it returns from its constructor method.');
      gestures[type].initializer(_recognizers[type]);
    }
    for (Type type in oldRecognizers.keys) {
      if (!_recognizers.containsKey(type))
        oldRecognizers[type].dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Listener(
        onPointerDown: _handlePointerDown,
        behavior: widget.behavior ?? _defaultBehavior,
        child: widget.child
    );
    return result;
  }

}

class DrawGestureRecognizer extends GestureRecognizer {
  DrawGestureRecognizer({ Object debugOwner }) : super(debugOwner: debugOwner);

  OnDrawGesture onDrawGesture;

  GestureArenaEntry gestureArenaEntry;

  final int _slot = 50;

  double _startX, _startY;
  double _inflectionX, _inflectionY;
  double _endX, _endY;
  double _lastX, _lastY;

  bool _reachInflectionPoint = false;

  bool _directionRecognized = false;
  bool _toLeft;

  bool _gestureValid = false;
  bool _winGesture = false;
  bool _invoked = false;

  int _primaryPointer;

  @override
  void addPointer(PointerEvent event) {
    print("addPointer ... ${event.pointer}");
    GestureBinding.instance.pointerRouter.addRoute(event.pointer, handleEvent);
    gestureArenaEntry = GestureBinding.instance.gestureArena.add(event.pointer, this);
  }

  void handleEvent(PointerEvent event) {
    //print("handleEvent ... ${event.pointer}");

    if (event is PointerUpEvent) {
      _dispatch(event.position);

      GestureBinding.instance.pointerRouter.removeRoute(event.pointer, handleEvent);
    } else if (event is PointerMoveEvent) {
      _recognizePath(event.position);
    } else if (event is PointerCancelEvent) {
      GestureBinding.instance.pointerRouter.removeRoute(event.pointer, handleEvent);
    } else if (event is PointerDownEvent) {
      _startX = event.position.dx;
      _startY = event.position.dy;
      _lastX = event.position.dx;
      _lastY = event.position.dy;

      _directionRecognized = false;
      _reachInflectionPoint = false;
      _toLeft = null;
      _gestureValid = true;
      _winGesture = false;
      _invoked = false;

      _primaryPointer = event.pointer;
    }
  }

  void _dispatch(Offset offset) {
    if (!_gestureValid)
      return;
  }

  void _recognizePath(Offset offset) {
    if (!_gestureValid)
      return;

    double x = offset.dx;
    double y = offset.dy;

    if (!_directionRecognized) {
      _directionRecognized = true;
      _toLeft = x < _lastX;
    }

    //print("_recognizePath....$offset");

    if (x > _lastX) {
      if (_toLeft) {
        //拐弯了
        double distance = math.sqrt(math.pow((x - _startX), 2) + math.pow((y - _startY), 2));
        if (distance < _slot) {
          _gestureValid = false;
          return;
        }

        if (!_reachInflectionPoint) {
          _reachInflectionPoint = true;

          _inflectionX = x;
          _inflectionY = y;
          return;
        }

        distance = math.sqrt(math.pow((x - _inflectionX), 2) + math.pow((y - _inflectionY), 2));

        //print("_recognizePath....$distance ... toleft");

        if (distance > _slot)
          _resolve();
      }
    } else if (x < _lastX) {
      if (!_toLeft) {
        //拐弯了
        double distance = math.sqrt(math.pow((x - _startX), 2) + math.pow((y - _startY), 2));
        if (distance < _slot) {
          _gestureValid = false;
          return;
        }

        if (!_reachInflectionPoint) {
          _reachInflectionPoint = true;

          _inflectionX = x;
          _inflectionY = y;
          return;
        }

        distance = math.sqrt(math.pow((x - _inflectionX), 2) + math.pow((y - _inflectionY), 2));

        //print("_recognizePath....$distance ... toright");

        if (distance > _slot)
          _resolve();
      }
    }

    _lastX = x;
    _lastY = y;
  }

  void _judge() {
    if (_reachInflectionPoint) {
      if (!_invoked) {
        GestureBinding.instance.pointerRouter.removeRoute(_primaryPointer, handleEvent);
        onDrawGesture(_toLeft);
        _invoked = true;
      }
    }
  }

  void _resolve() {
    if (_winGesture) {
      _judge();
    } else {
      gestureArenaEntry.resolve(GestureDisposition.accepted);
    }
  }

  @override
  void acceptGesture(int pointer) {
    print("acceptGesture....");
    _winGesture = true;
    _judge();
  }

  @override
  void rejectGesture(int pointer) {
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  String get debugDescription => 'draw gesture';
}