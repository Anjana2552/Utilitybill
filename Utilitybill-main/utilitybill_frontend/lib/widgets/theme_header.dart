import 'package:flutter/material.dart';

enum HeaderShape { wave, square }

class BlueGreenHeader extends StatelessWidget {
  final double height;
  final String? title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? overlay;
  final double overlayYOffset;
  final Color? backgroundColor;
  final HeaderShape shape;
  final HeaderTitleAlignment titleAlignment;
  const BlueGreenHeader({
    super.key,
    this.height = 260,
    this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.overlay,
    this.overlayYOffset = 0,
    this.backgroundColor,
    this.shape = HeaderShape.wave,
    this.titleAlignment = HeaderTitleAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (shape == HeaderShape.wave)
            ClipPath(
              clipper: _WaveClipper(offset: 0),
              child: _buildBackground(context),
            )
          else
            _buildBackground(context),
          if (overlay != null)
            Center(
              child: Transform.translate(
                offset: Offset(0, overlayYOffset),
                child: overlay,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final Color bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final Color onBg = Theme.of(context).colorScheme.onPrimary;
    return Container(
      color: bg,
      child: (title == null && subtitle == null)
          ? null
          : (titleAlignment == HeaderTitleAlignment.center
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            textAlign: TextAlign.center,
                            style:
                                titleStyle ??
                                TextStyle(
                                  color: onBg,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style:
                                subtitleStyle ??
                                TextStyle(
                                  color: onBg.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              textAlign: TextAlign.left,
                              style:
                                  titleStyle ??
                                  TextStyle(
                                    color: onBg,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.left,
                              style:
                                  subtitleStyle ??
                                  TextStyle(
                                    color: onBg.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
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
  final Widget? bottomLeft; // extra widget under title on left-aligned header

  const CurvedHeaderPage({
    super.key,
    this.title,
    this.headerHeight = 200,
    required this.child,
    this.leading,
    this.titleAlignment = HeaderTitleAlignment.center,
    this.actions,
    this.headerColor,
    this.bottomLeft,
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
                BlueGreenHeader(
                  height: headerHeight,
                  title: title,
                  backgroundColor:
                      headerColor ?? Theme.of(context).colorScheme.primary,
                )
              else
                BlueGreenHeader(
                  height: headerHeight,
                  backgroundColor:
                      headerColor ?? Theme.of(context).colorScheme.primary,
                ),

              if (titleAlignment == HeaderTitleAlignment.center) ...[
                if (leading != null)
                  Positioned(top: 8, left: 8, child: SafeArea(child: leading!)),
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ),
                if (bottomLeft != null)
                  Positioned(
                    left: 20,
                    top: 64,
                    child: SafeArea(child: bottomLeft!),
                  ),
              ],
            ],
          ),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }
}
