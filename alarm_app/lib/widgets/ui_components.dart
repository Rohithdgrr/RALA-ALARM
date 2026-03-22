import 'package:flutter/material.dart';
import 'dart:math' as math;

// ==================== GRADIENT BUTTONS ====================

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final double borderRadius;
  final double height;
  final IconData? icon;
  final bool isLoading;
  final double width;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradientColors = const [Color(0xFF4A90D9), Color(0xFF7B68EE)],
    this.borderRadius = 16,
    this.height = 56,
    this.icon,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.onPressed == null
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : widget.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withOpacity(_isPressed ? 0.2 : 0.4),
                    blurRadius: _isPressed ? 8 : 16,
                    offset: Offset(0, _isPressed ? 2 : 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GradientIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final double size;
  final String? tooltip;
  final double borderRadius;

  const GradientIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.gradientColors = const [Color(0xFF4A90D9), Color(0xFF7B68EE)],
    this.size = 48,
    this.tooltip,
    this.borderRadius = 12,
  });

  @override
  State<GradientIconButton> createState() => _GradientIconButtonState();
}

class _GradientIconButtonState extends State<GradientIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    return GestureDetector(
      onTap: null,
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.1),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnabled
                      ? widget.gradientColors
                      : [Colors.grey.shade500, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isEnabled ? widget.gradientColors[0] : Colors.black)
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== GRADIENT CARDS ====================

class GradientCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final bool animateOnHover;

  const GradientCard({
    super.key,
    required this.child,
    this.gradientColors = const [Color(0xFF4A90D9), Color(0xFF7B68EE)],
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.animateOnHover = true,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shadowAnimation = Tween<double>(begin: 12.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.animateOnHover ? (_) => _controller.forward() : null,
      onTapUp: widget.animateOnHover ? (_) => _controller.reverse() : null,
      onTapCancel: widget.animateOnHover ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withOpacity(0.35),
                    blurRadius: _shadowAnimation.value,
                    offset: Offset(0, _shadowAnimation.value / 3),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? tintColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white).withOpacity(0.15),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==================== ANIMATED ICONS ====================

class AnimatedIconWidget extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool animate;
  final String? semanticLabel;

  const AnimatedIconWidget({
    super.key,
    required this.icon,
    this.color = const Color(0xFF4A90D9),
    this.size = 24,
    this.animate = true,
    this.semanticLabel,
  });

  @override
  State<AnimatedIconWidget> createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<AnimatedIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Icon(widget.icon, color: widget.color, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_controller.value * 0.1),
          child: Opacity(
            opacity: 0.8 + (_controller.value * 0.2),
            child: Icon(widget.icon, color: widget.color, size: widget.size),
          ),
        );
      },
    );
  }
}

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final int durationMs;

  const PulsingIcon({
    super.key,
    required this.icon,
    this.color = const Color(0xFF4A90D9),
    this.size = 24,
    this.durationMs = 1000,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.size * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.1 + _controller.value * 0.2),
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}

// ==================== ANIMATED BACKGROUNDS ====================

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<List<Color>> gradientSequence;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.gradientSequence = const [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      [Color(0xFFf093fb), Color(0xFFf5576c)],
      [Color(0xFF4facfe), Color(0xFF00f2fe)],
      [Color(0xFF43e97b), Color(0xFF38f9d7)],
    ],
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.gradientSequence.length;
        });
        _controller.forward(from: 0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = widget.gradientSequence[_currentIndex];
    final nextIndex = (_currentIndex + 1) % widget.gradientSequence.length;
    final nextGradient = widget.gradientSequence[nextIndex];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(currentGradient[0], nextGradient[0], _animation.value)!,
                Color.lerp(currentGradient[1], nextGradient[1], _animation.value)!,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 30,
    this.particleColor = Colors.white,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    particles = List.generate(widget.particleCount, (_) => Particle.random());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                progress: _controller.value,
                color: widget.particleColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle.random()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = 2 + math.Random().nextDouble() * 6,
        speed = 0.5 + math.Random().nextDouble() * 1.5,
        opacity = 0.1 + math.Random().nextDouble() * 0.5;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.0;
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * (1 - y * 0.5))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

// ==================== ANIMATED LIST ITEMS ====================

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ==================== FLOATING ACTION BUTTON ====================

class GradientFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final String? tooltip;

  const GradientFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.gradientColors = const [Color(0xFF4A90D9), Color(0xFF7B68EE)],
    this.tooltip,
  });

  @override
  State<GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<GradientFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors[0].withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: _rotationAnimation.value * math.pi,
              child: Icon(widget.icon, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}

// ==================== TOGGLE SWITCH ====================

class GradientToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Color> activeColors;
  final List<Color> inactiveColors;
  final double width;
  final double height;

  const GradientToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColors = const [Color(0xFF00C853), Color(0xFF00E676)],
    this.inactiveColors = const [Color(0xFFFF5252), Color(0xFFFF1744)],
    this.width = 56,
    this.height = 32,
  });

  @override
  State<GradientToggle> createState() => _GradientToggleState();
}

class _GradientToggleState extends State<GradientToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (widget.value) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(GradientToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.value 
                    ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                    : [const Color(0xFFFF5252), const Color(0xFFFF8A80)],
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: (widget.value ? const Color(0xFF00C853) : const Color(0xFFFF5252)).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // ON/OFF text indicator
                Positioned(
                  left: widget.value ? null : 8,
                  right: widget.value ? 8 : null,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      widget.value ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
                // Animated thumb
                Positioned(
                  top: 3,
                  left: 3 + (_controller.value * (widget.width - widget.height - 2)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.height - 6,
                    height: widget.height - 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: (widget.value ? const Color(0xFF00C853) : const Color(0xFFFF5252)).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
