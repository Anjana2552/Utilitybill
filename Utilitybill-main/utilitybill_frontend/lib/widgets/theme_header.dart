import 'package:flutter/material.dart';

class BlueGreenHeader extends StatelessWidget {
  final double height;
  final String? title;
  final TextStyle? titleStyle;
  const BlueGreenHeader({
    super.key,
    this.height = 260,
    this.title,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipPath(
        clipper: _WaveClipper(offset: 0),
        child: Container(
          color: const Color(0xFF7FD9CE),
          child: title == null
              ? null
              : Center(
                  child: Text(
                    title!,
                    textAlign: TextAlign.center,
                    style:
                        titleStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double offset;
  _WaveClipper({this.offset = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - (90 + offset));

    final firstControlPoint = Offset(
      size.width * 0.25,
      size.height - (10 + offset),
    );
    final firstEndPoint = Offset(size.width * 0.5, size.height - (50 + offset));
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(
      size.width * 0.75,
      size.height - (100 + offset),
    );
    final secondEndPoint = Offset(size.width, size.height - (60 + offset));
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
