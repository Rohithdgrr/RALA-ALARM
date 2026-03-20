import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                  _controller.value,
                )!,
                Color.lerp(
                  const Color(0xFF764ba2),
                  const Color(0xFF667eea),
                  _controller.value,
                )!,
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
  final bool isDark;
  
  const ParticleBackground({super.key, required this.child, this.isDark = false});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Generate particles
    for (int i = 0; i < 20; i++) {
      particles.add(Particle.random());
    }
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
          decoration: BoxDecoration(
            gradient: widget.isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFf8f9fa), Color(0xFFe9ecef)],
                  ),
          ),
          child: Stack(
            children: [
              // Animated particles
              ...particles.map((particle) {
                final offset = (particle.speed * _controller.value) % 1.0;
                return Positioned(
                  left: particle.x * MediaQuery.of(context).size.width,
                  top: (particle.y + offset) % 1.0 * MediaQuery.of(context).size.height,
                  child: Opacity(
                    opacity: particle.opacity * (0.3 + 0.7 * (1 - offset)),
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4A90D9).withOpacity(0.6),
                            const Color(0xFF7B68EE).withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              widget.child,
            ],
          ),
        );
      },
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
      : x = 0.1 + (0.8 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000),
        y = 0.1 + (0.8 * ((DateTime.now().millisecondsSinceEpoch ~/ 100) % 1000) / 1000),
        size = 4 + (DateTime.now().millisecondsSinceEpoch % 12).toDouble(),
        speed = 0.2 + ((DateTime.now().millisecondsSinceEpoch % 5) / 10),
        opacity = 0.3 + ((DateTime.now().millisecondsSinceEpoch % 5) / 10);
}
