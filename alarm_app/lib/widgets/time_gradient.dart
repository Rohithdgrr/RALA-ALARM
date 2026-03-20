import 'package:flutter/material.dart';
import 'dart:async';

class TimeBasedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;
  final int changeIntervalSeconds;

  const TimeBasedGradientBackground({
    super.key,
    required this.child,
    this.isDarkMode = false,
    this.changeIntervalSeconds = 5,
  });

  @override
  State<TimeBasedGradientBackground> createState() => _TimeBasedGradientBackgroundState();
}

class _TimeBasedGradientBackgroundState extends State<TimeBasedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _colorController;
  int _currentGradientIndex = 0;
  Timer? _gradientTimer;

  final List<List<Color>> _lightGradients = [
    const [Color(0xFF667eea), Color(0xFF764ba2)],
    const [Color(0xFFf093fb), Color(0xFFf5576c)],
    const [Color(0xFF4facfe), Color(0xFF00f2fe)],
    const [Color(0xFF43e97b), Color(0xFF38f9d7)],
    const [Color(0xFFfa709a), Color(0xFFfee140)],
    const [Color(0xFF30cfd0), Color(0xFF330867)],
    const [Color(0xFFa8edea), Color(0xFFfed6e3)],
    const [Color(0xFFff9a9e), Color(0xFFfecfef)],
    const [Color(0xFFffecd2), Color(0xFFfcb69f)],
    const [Color(0xFFff6b6b), Color(0xFF7B68EE)],
  ];

  final List<List<Color>> _darkGradients = [
    const [Color(0xFF1a1a2e), Color(0xFF16213e)],
    const [Color(0xFF0f0c29), Color(0xFF302b63)],
    const [Color(0xFF141E30), Color(0xFF243B55)],
    const [Color(0xFF000428), Color(0xFF004e92)],
    const [Color(0xFF1e130c), Color(0xFF9a8478)],
    const [Color(0xFF0b0c10), Color(0xFF1f2833)],
    const [Color(0xFF200122), Color(0xFF6f0000)],
    const [Color(0xFF0c0c0c), Color(0xFF1a1a1a)],
    const [Color(0xFF232526), Color(0xFF414345)],
    const [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.changeIntervalSeconds),
    );
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startGradientAnimation();
  }

  void _startGradientAnimation() {
    _gradientTimer = Timer.periodic(
      Duration(seconds: widget.changeIntervalSeconds),
      (timer) {
        if (mounted) {
          setState(() {
            _currentGradientIndex = (_currentGradientIndex + 1) % 
                (widget.isDarkMode ? _darkGradients.length : _lightGradients.length);
          });
          _colorController.forward(from: 0);
        }
      },
    );
    _gradientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientTimer?.cancel();
    _gradientController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  List<Color> get _currentGradients =>
      widget.isDarkMode ? _darkGradients[_currentGradientIndex] : _lightGradients[_currentGradientIndex];

  List<Color> get _nextGradients {
    final nextIndex = (_currentGradientIndex + 1) % 
        (widget.isDarkMode ? _darkGradients.length : _lightGradients.length);
    return widget.isDarkMode ? _darkGradients[nextIndex] : _lightGradients[nextIndex];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        final t = _colorController.value;
        final colors = [
          Color.lerp(_currentGradients[0], _nextGradients[0], t) ?? _currentGradients[0],
          Color.lerp(_currentGradients[1], _nextGradients[1], t) ?? _currentGradients[1],
        ];
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedGradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final EdgeInsets padding;

  const AnimatedGradientCard({
    super.key,
    required this.child,
    this.colors = const [Color(0xFF4A90D9), Color(0xFF7B68EE)],
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
