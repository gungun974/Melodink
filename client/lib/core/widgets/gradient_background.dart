import 'dart:math';

import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AlignmentGeometry gradientEndPoint(double angle) {
      double angleRad = (angle - 90) * (pi / 180);
      return Alignment(cos(angleRad), sin(angleRad));
    }

    AlignmentGeometry gradientStartPoint(double angle) {
      double angleRad = (angle + 90) * (pi / 180);
      return Alignment(cos(angleRad), sin(angleRad));
    }

    return Stack(
      children: [
        Container(
          color: Colors.black87,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientStartPoint(127),
              end: gradientEndPoint(127),
              stops: const [0.0, 0.9],
              colors: const [
                Color.fromRGBO(58, 91, 111, 0.55),
                Color.fromRGBO(58, 91, 111, 0),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientStartPoint(217),
              end: gradientEndPoint(217),
              stops: const [0.0, 0.8],
              colors: const [
                Color.fromRGBO(216, 232, 238, 0.55),
                Color.fromRGBO(216, 232, 238, 0.10),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientStartPoint(336),
              end: gradientEndPoint(336),
              stops: const [0.0, 1],
              colors: const [
                Color.fromRGBO(151, 201, 218, 0.55),
                Color.fromRGBO(151, 201, 218, 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
