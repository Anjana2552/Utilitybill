import 'package:flutter/material.dart';

class BlueGreenHeader extends StatelessWidget {
  final double height;
  final String? title;
  final TextStyle? titleStyle;
  final Widget? overlay;
  final Color backgroundColor;
  const BlueGreenHeader({
    super.key,
    this.height = 260,
    this.title,
    this.titleStyle,
    this.overlay,
    this.backgroundColor = const Color(0xFF7FD9CE),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: _WaveClipper(offset: 0),
            child: Container(
              color: backgroundColor,
              child: title == null
                  ? null
                  : Center(
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: titleStyle ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
            ),
          ),
          if (overlay != null)
            Center(
              child: overlay,
            ),
        ],
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

enum HeaderTitleAlignment { center, left }

/// A reusable page wrapper that applies the curved BlueGreenHeader
/// at the top and places [child] content below it.
class CurvedHeaderPage extends StatelessWidget {
  final String? title;
  final double headerHeight;
  final Widget child;
  final Widget? leading; // e.g., a menu button
  final HeaderTitleAlignment titleAlignment;
  final List<Widget>? actions; // right-side header actions
  final Color? headerColor;

  const CurvedHeaderPage({
    super.key,
    this.title,
    this.headerHeight = 200,
    required this.child,
    this.leading,
    this.titleAlignment = HeaderTitleAlignment.center,
    this.actions,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (titleAlignment == HeaderTitleAlignment.center)
                BlueGreenHeader(height: headerHeight, title: title, backgroundColor: headerColor ?? const Color(0xFF7FD9CE))
              else
                BlueGreenHeader(height: headerHeight, backgroundColor: headerColor ?? const Color(0xFF7FD9CE)),

              if (titleAlignment == HeaderTitleAlignment.center) ...[
                if (leading != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: SafeArea(child: leading!),
                  ),
                if (actions != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SafeArea(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
                  ),
              ] else ...[
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (leading != null) leading!,
                        if (title != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
