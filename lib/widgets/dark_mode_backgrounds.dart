import 'package:flutter/material.dart';

class DarkModeBackground extends StatelessWidget {
  final Widget child;

  const DarkModeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class AnimatedDarkBackground extends StatefulWidget {
  final Widget child;

  const AnimatedDarkBackground({super.key, required this.child});

  @override
  State<AnimatedDarkBackground> createState() => _AnimatedDarkBackgroundState();
}

class _AnimatedDarkBackgroundState extends State<AnimatedDarkBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 3.14 * 2,
              transform: GradientRotation(_controller.value * 3.14 * 2),
              colors: const [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
                Color(0xFF1a1a2e),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class StarryBackground extends StatefulWidget {
  final Widget child;

  const StarryBackground({super.key, required this.child});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with TickerProviderStateMixin {
  late List<Star> stars;

  @override
  void initState() {
    super.initState();
    stars = List.generate(50, (_) => Star.random());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0c0c1d),
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Stars
          ...stars.map((star) {
            return Positioned(
              left: star.x * MediaQuery.of(context).size.width,
              top: star.y * MediaQuery.of(context).size.height,
              child: TwinkleStar(
                size: star.size,
                opacity: star.opacity,
                duration: star.duration,
              ),
            );
          }),
          widget.child,
        ],
      ),
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final int duration;

  Star.random()
      : x = 0.1 + (0.8 * (DateTime.now().microsecond % 1000) / 1000),
        y = 0.1 + (0.8 * ((DateTime.now().millisecond * 37) % 1000) / 1000),
        size = 1 + (DateTime.now().millisecond % 3).toDouble(),
        opacity = 0.2 + ((DateTime.now().microsecond % 8) / 10),
        duration = 2000 + (DateTime.now().millisecond % 3000);
}

class TwinkleStar extends StatefulWidget {
  final double size;
  final double opacity;
  final int duration;

  const TwinkleStar({
    super.key,
    required this.size,
    required this.opacity,
    required this.duration,
  });

  @override
  State<TwinkleStar> createState() => _TwinkleStarState();
}

class _TwinkleStarState extends State<TwinkleStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
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
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(
              widget.opacity * (0.5 + 0.5 * _controller.value),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(
                  0.3 * (0.5 + 0.5 * _controller.value),
                ),
                blurRadius: widget.size * 2,
                spreadRadius: widget.size * 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}
