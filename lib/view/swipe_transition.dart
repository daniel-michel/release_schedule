import 'package:flutter/material.dart';

/// A widget that transitions between two child widget by clipping them so that
/// the first one slides out of view and the second one slides into view.
class SwipeTransition extends StatelessWidget {
  final Widget first;
  final Widget second;
  late final CurvedAnimation firstAnimation;
  late final CurvedAnimation secondAnimation;
  final Animation<double> animation;

  SwipeTransition({
    Key? key,
    required this.first,
    required this.second,
    required this.animation,
  }) : super(key: key) {
    firstAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutSine,
    );
    secondAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInSine,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            ClipWithRect(
              clipRect: Rect.fromLTRB(
                0,
                firstAnimation.value,
                1,
                1,
              ),
              child: first,
            ),
            ClipWithRect(
              clipRect: Rect.fromLTRB(
                0,
                0,
                1,
                secondAnimation.value,
              ),
              child: second,
            ),
          ],
        );
      },
    );
  }
}

class ClipWithRect extends StatelessWidget {
  final Widget child;
  final Rect clipRect;

  const ClipWithRect({
    Key? key,
    required this.child,
    required this.clipRect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: _RectClipper(clipRect),
      child: child,
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  final Rect clipRect;

  _RectClipper(this.clipRect);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      clipRect.left * size.width,
      clipRect.top * size.height,
      clipRect.right * size.width,
      clipRect.bottom * size.height,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}
