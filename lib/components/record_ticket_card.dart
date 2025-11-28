import 'package:flutter/material.dart';
import 'package:recolle/features/records/models/record.dart';
import 'package:recolle/core/theme/app_colors.dart';

class RecordTicketCard extends StatefulWidget {
  final Record record;
  final VoidCallback onTap;

  const RecordTicketCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  State<RecordTicketCard> createState() => _RecordTicketCardState();
}

class _RecordTicketCardState extends State<RecordTicketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipPath(
            clipper: TicketClipper(),
            child: Container(
              height: 120, // 少し高さを調整
              decoration: const BoxDecoration(color: AppColors.surface),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Image with Dark Overlay
                  Image.network(
                    widget.record.ticketImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppColors.surfaceLight);
                    },
                  ),
                  // Dark Gradient Overlay to make text readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.9), // Left (Text side)
                          Colors.black.withOpacity(0.6), // Center
                          Colors.black.withOpacity(0.4), // Right
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),

                  // 2. Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        // Main Info (Left)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title (Main)
                              Text(
                                widget.record.title,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Artist Name
                              Text(
                                widget.record.artistOrAuthor,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Dashed Line Divider
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: CustomPaint(
                            painter: DashedLinePainter(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),

                        // Date (Right)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.record.date.year.toString(),
                              style: TextStyle(
                                color: AppColors.gold.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.record.date.month.toString().padLeft(2, '0')}.${widget.record.date.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double cornerRadius = 16.0;
    const double notchRadius = 8.0;
    const double notchPositionRatio = 0.75; // Notch position

    path.moveTo(cornerRadius, 0);

    // Top line
    path.lineTo(size.width * notchPositionRatio - notchRadius, 0);

    // Top Notch
    path.arcToPoint(
      Offset(size.width * notchPositionRatio + notchRadius, 0),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(size.width - cornerRadius, 0);

    // Top Right Corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right line
    path.lineTo(size.width, size.height - cornerRadius);

    // Bottom Right Corner
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bottom line
    path.lineTo(size.width * notchPositionRatio + notchRadius, size.height);

    // Bottom Notch
    path.arcToPoint(
      Offset(size.width * notchPositionRatio - notchRadius, size.height),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(cornerRadius, size.height);

    // Bottom Left Corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left line
    path.lineTo(0, cornerRadius);

    // Top Left Corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
