import 'package:flutter/material.dart';
import 'package:recolle/theme/app_colors.dart';
import '../models/live_ticket.dart';

class TicketCard extends StatefulWidget {
  final LiveTicket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard>
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
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  LinearGradient? _getGradient(TicketColor color) {
    if (color == TicketColor.blackGold) {
      return const LinearGradient(
        colors: [
          AppColors.surfaceLight, // Slightly lighter black
          Color(0xFF000000),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return null;
  }

  Color _getBackgroundColor(TicketColor color) {
    switch (color) {
      case TicketColor.blackGold:
        return AppColors.surface;
      case TicketColor.red:
        return AppColors.ticketRed; // Dark Red
      case TicketColor.blue:
        return AppColors.ticketBlue; // Dark Blue
      case TicketColor.white:
        return AppColors.ticketWhite; // White smoke
    }
  }

  Color _getTextColor(TicketColor color) {
    if (color == TicketColor.white) {
      return Colors.black87;
    }
    return AppColors.textPrimary; // Default for dark cards
  }

  Color _getAccentColor(TicketColor color) {
    if (color == TicketColor.blackGold) {
      return AppColors.gold; // Gold
    }
    if (color == TicketColor.white) {
      return Colors.grey[600]!;
    }
    return AppColors.textSecondary;
  }

  String _formatDate(DateTime date) {
    // Simple formatter to avoid intl dependency
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    const weekDays = ['月', '火', '水', '木', '金', '土', '日'];
    final w = weekDays[date.weekday - 1];
    return '$y.$m.$d ($w)';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(widget.ticket.color);
    final textColor = _getTextColor(widget.ticket.color);
    final accentColor = _getAccentColor(widget.ticket.color);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent, // Handled by CustomPaint/Clip
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomPaint(
            painter: TicketPainter(
              color: bgColor,
              borderColor: widget.ticket.color == TicketColor.blackGold
                  ? AppColors.gold
                  : Colors.transparent,
            ),
            child: ClipPath(
              clipper: TicketClipper(),
              child: Container(
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _getGradient(widget.ticket.color),
                  color: widget.ticket.color != TicketColor.blackGold
                      ? bgColor
                      : null,
                ),
                child: Row(
                  children: [
                    // --- Left Side (Main Info) ---
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.ticket.artistName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.ticket.liveName,
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.ticket.venue,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.ticket.date),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- Divider ---
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomPaint(
                        painter: DashedLinePainter(
                          color: accentColor.withOpacity(0.3),
                        ),
                      ),
                    ),

                    // --- Right Side (Score) ---
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.ticket.color == TicketColor.blackGold)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.gold,
                                    AppColors.goldLight,
                                    AppColors.gold,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                'SCORE',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            )
                          else
                            Text(
                              'SCORE',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            widget.ticket.score.toString(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier', // Monospace feel
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 20,
                            color: accentColor.withOpacity(0.5),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          Text(
                            '10',
                            style: TextStyle(color: accentColor, fontSize: 14),
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
      ),
    );
  }
}

// Custom Clipper for Ticket Shape
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double cornerRadius = 24.0;
    const double notchRadius = 10.0;
    const double notchPositionRatio = 0.72; // Where the notch is horizontally

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

// Painter for background/border if needed
class TicketPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  TicketPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    // This is mainly for shadow casting if needed,
    // but standard container shadow works reasonably well with ClipPath
    // if using PhysicalShape, but here we used Container decoration shadow
    // which might not clip perfectly to the notches.
    // For this level of fidelity, simple box shadow is usually acceptable.

    if (borderColor != Colors.transparent) {
      // Placeholder for future border drawing
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
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
