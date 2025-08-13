import 'package:flutter/material.dart';
import 'package:secure_money_management/services/onboarding_service.dart';

/// Widget to create highlighted hints and tooltips for onboarding
class FeatureHint extends StatefulWidget {
  final Widget child;
  final String message;
  final String? stepId;
  final VoidCallback? onTap;
  final bool showHint;
  final Color highlightColor;
  final EdgeInsets tooltipPadding;
  
  const FeatureHint({
    super.key,
    required this.child,
    required this.message,
    this.stepId,
    this.onTap,
    this.showHint = true,
    this.highlightColor = Colors.blueAccent,
    this.tooltipPadding = const EdgeInsets.all(16),
  });

  @override
  State<FeatureHint> createState() => _FeatureHintState();
}

class _FeatureHintState extends State<FeatureHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isHintVisible = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.showHint) {
      _checkAndShowHint();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _checkAndShowHint() async {
    if (widget.stepId != null) {
      final isCompleted = await OnboardingService.isStepCompleted(widget.stepId!);
      if (!isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHintWithDelay();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHintWithDelay();
      });
    }
  }

  void _showHintWithDelay() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showHint();
      }
    });
  }

  void _showHint() {
    if (!mounted) return;
    
    setState(() {
      _isHintVisible = true;
    });
    
    _animationController.repeat(reverse: true);
    
    // Create overlay
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _hideHint();
    });
  }

  void _hideHint() {
    if (!mounted) return;
    
    _animationController.stop();
    _removeOverlay();
    
    setState(() {
      _isHintVisible = false;
    });

    // Mark step as completed if stepId is provided
    if (widget.stepId != null) {
      OnboardingService.completeStep(widget.stepId!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 8,
        top: offset.dy - 8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width + 16,
            height: size.height + 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.highlightColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.highlightColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Tooltip
                Positioned(
                  top: size.height + 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 250),
                      padding: widget.tooltipPadding,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _hideHint,
                            child: const Text(
                              'Got it!',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isHintVisible) {
          _hideHint();
        }
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHintVisible ? _pulseAnimation.value : 1.0,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Helper widget for creating tooltips without animation
class StaticTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final Color backgroundColor;

  const StaticTooltip({
    super.key,
    required this.child,
    required this.message,
    this.backgroundColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}
