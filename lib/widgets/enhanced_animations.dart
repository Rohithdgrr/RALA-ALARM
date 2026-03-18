import 'package:flutter/material.dart';
import 'dart:math' as math;

class SoundWaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double height;

  const SoundWaveAnimation({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFF4A90D9),
    this.height = 60,
  });

  @override
  State<SoundWaveAnimation> createState() => _SoundWaveAnimationState();
}

class _SoundWaveAnimationState extends State<SoundWaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SoundWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (index) {
              final delay = index * 0.2;
              final value = (_controller.value + delay) % 1.0;
              final height = widget.height * (0.3 + 0.7 * math.sin(value * math.pi));
              
              return Container(
                width: 8,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      widget.color.withOpacity(0.3),
                      widget.color,
                      widget.color.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class AnimatedTimeDisplay extends StatefulWidget {
  final DateTime time;
  final TextStyle? style;

  const AnimatedTimeDisplay({
    super.key,
    required this.time,
    this.style,
  });

  @override
  State<AnimatedTimeDisplay> createState() => _AnimatedTimeDisplayState();
}

class _AnimatedTimeDisplayState extends State<AnimatedTimeDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _displayTime = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _updateTime();
  }

  @override
  void didUpdateWidget(AnimatedTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.time != oldWidget.time) {
      _controller.forward(from: 0).then((_) {
        _updateTime();
        _controller.reverse();
      });
    }
  }

  void _updateTime() {
    final hour = widget.time.hour.toString().padLeft(2, '0');
    final minute = widget.time.minute.toString().padLeft(2, '0');
    setState(() {
      _displayTime = '$hour:$minute';
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
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - _animation.value * 0.5,
          child: Transform.translate(
            offset: Offset(0, _animation.value * -10),
            child: Text(
              _displayTime,
              style: widget.style ??
                  const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -2,
                  ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyStateIllustration extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyStateIllustration({
    super.key,
    this.title = 'No alarms set',
    this.subtitle = 'Tap + to add a new alarm',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom illustration using Flutter widgets
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A90D9).withOpacity(0.1),
                  const Color(0xFF7B68EE).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Clock body
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90D9).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
                // Clock face
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4A90D9).withOpacity(0.3),
                      width: 3,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                // Clock hands
                Transform.rotate(
                  angle: -0.8,
                  child: Container(
                    width: 4,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: 0.5,
                  child: Container(
                    width: 3,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B68EE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Center dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90D9),
                    shape: BoxShape.circle,
                  ),
                ),
                // Zzz animation
                Positioned(
                  top: 30,
                  right: 40,
                  child: _buildZzz(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZzz() {
    return Row(
      children: [
        _buildZ(Colors.black26, 12, 0),
        const SizedBox(width: 4),
        _buildZ(Colors.black38, 16, 0.2),
        const SizedBox(width: 4),
        _buildZ(const Color(0xFF4A90D9), 20, 0.4),
      ],
    );
  }

  Widget _buildZ(Color color, double size, double delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        final adjustedValue = ((value + delay) % 1.0);
        return Opacity(
          opacity: adjustedValue < 0.5 ? adjustedValue * 2 : 2 - adjustedValue * 2,
          child: Transform.translate(
            offset: Offset(0, -10 * adjustedValue),
            child: Text(
              'Z',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AlarmPreviewCard extends StatefulWidget {
  final TimeOfDay time;
  final String label;
  final bool vibrate;
  final String sound;

  const AlarmPreviewCard({
    super.key,
    required this.time,
    this.label = '',
    this.vibrate = true,
    this.sound = 'Default',
  });

  @override
  State<AlarmPreviewCard> createState() => _AlarmPreviewCardState();
}

class _AlarmPreviewCardState extends State<AlarmPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        final pulse = 1 + 0.05 * math.sin(_controller.value * 2 * math.pi);
        return Transform.scale(
          scale: pulse,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.alarm,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _formatTime(widget.time),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.vibrate)
                      _buildIcon(Icons.vibration, 'Vibrate'),
                    const SizedBox(width: 16),
                    _buildIcon(Icons.volume_up, widget.sound),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
