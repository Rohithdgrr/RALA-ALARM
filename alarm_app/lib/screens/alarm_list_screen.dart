import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import 'add_edit_alarm_screen.dart';
import 'settings_screen.dart';
import '../widgets/ui_components.dart';
import '../widgets/time_gradient.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  String _searchQuery = '';
  String _sortBy = 'time'; // 'time' or 'enabled'
  bool _showSortMenu = false;
  Timer? _timer;
  String _viewMode = 'list'; // 'list', 'compact', 'grid'

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Route<T> _fadeSlideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  DateTime? _nextOccurrence(Alarm alarm, DateTime now) {
    final base = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);

    if (alarm.repeatDays.isEmpty) {
      if (base.isAfter(now)) return base;
      return base.add(const Duration(days: 1));
    }

    DateTime? best;
    // alarm.repeatDays: 0-6 for Mon-Sun; DateTime.weekday: 1-7 for Mon-Sun
    for (final repeatDay in alarm.repeatDays) {
      final targetWeekday = repeatDay + 1;
      final delta = (targetWeekday - now.weekday + 7) % 7;
      var candidate = base.add(Duration(days: delta));
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 7));
      }
      if (best == null || candidate.isBefore(best)) {
        best = candidate;
      }
    }
    return best;
  }

  String _nextAlarmText(List<Alarm> alarms) {
    final now = DateTime.now();
    DateTime? soonest;

    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;
      final next = _nextOccurrence(alarm, now);
      if (next == null) continue;
      if (soonest == null || next.isBefore(soonest)) {
        soonest = next;
      }
    }

    if (soonest == null) return 'No upcoming alarms';
    final diff = soonest.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours <= 0 && minutes <= 0) return 'Next alarm now';
    if (hours == 0) return 'Next alarm in ${minutes} min';
    if (minutes == 0) return 'Next alarm in ${hours} hour${hours == 1 ? '' : 's'}';
    return 'Next alarm in ${hours}h ${minutes}m';
  }

  // Feature D: Group alarms by time of day
  Map<String, List<Alarm>> _groupAlarms(List<Alarm> alarms) {
    final Map<String, List<Alarm>> groups = {
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Night': [],
    };

    for (final alarm in alarms) {
      final hour = alarm.time.hour;
      if (hour >= 5 && hour < 12) {
        groups['Morning']!.add(alarm);
      } else if (hour >= 12 && hour < 17) {
        groups['Afternoon']!.add(alarm);
      } else if (hour >= 17 && hour < 21) {
        groups['Evening']!.add(alarm);
      } else {
        groups['Night']!.add(alarm);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  // Feature E: Sort and filter alarms
  List<Alarm> _processAlarms(List<Alarm> alarms) {
    var filtered = alarms.where((alarm) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return alarm.label.toLowerCase().contains(query) ||
          alarm.formattedTimeWithPeriod.toLowerCase().contains(query);
    }).toList();

    // Sort
    if (_sortBy == 'enabled') {
      filtered.sort((a, b) {
        if (a.isEnabled != b.isEnabled) {
          return a.isEnabled ? -1 : 1;
        }
        return a.time.hour * 60 + a.time.minute - (b.time.hour * 60 + b.time.minute);
      });
    } else {
      filtered.sort((a, b) => a.time.hour * 60 + a.time.minute - (b.time.hour * 60 + b.time.minute));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return TimeBasedGradientBackground(
      changeIntervalSeconds: 8,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: Consumer<AlarmProvider>(
            builder: (context, alarmProvider, _) {
              final subtitle = _nextAlarmText(alarmProvider.alarms);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // RALA Logo
                      Image.asset(
                        'assets/logo RALA.png',
                        height: 32,
                        width: 32,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.alarm_rounded,
                            color: Colors.white,
                            size: 28,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Alarm',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            // Search Button
            GradientIconButton(
              icon: Icons.search_rounded,
              size: 40,
              borderRadius: 8,
              gradientColors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: _AlarmSearchDelegate(
                    alarms: context.read<AlarmProvider>().alarms,
                    onSelect: (alarm) {
                      Navigator.of(context).push(
                        _fadeSlideRoute(AddEditAlarmScreen(alarm: alarm)),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Settings Button
            GradientIconButton(
              icon: Icons.settings_rounded,
              size: 40,
              borderRadius: 8,
              gradientColors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
              onPressed: () {
                Navigator.of(context).push(
                  _fadeSlideRoute(const SettingsScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
            // Sort Button
            Stack(
              children: [
                GradientIconButton(
                  icon: Icons.sort_rounded,
                  size: 40,
                  borderRadius: 8,
                  gradientColors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
                  onPressed: () {
                    setState(() => _showSortMenu = !_showSortMenu);
                  },
                ),
                if (_showSortMenu)
                  Positioned(
                    right: 8,
                    top: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSortOption('Time', 'time'),
                          _buildSortOption('Enabled first', 'enabled'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      body: GestureDetector(
        onTap: () => setState(() => _showSortMenu = false),
        child: Consumer<AlarmProvider>(
          builder: (context, alarmProvider, child) {
            final alarms = _processAlarms(alarmProvider.alarms);
            final groups = _groupAlarms(alarms);
            
            if (alarms.isEmpty) {
              return Center(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alarm_off_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No alarms set',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add a new alarm',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await alarmProvider.loadAlarms();
                return Future.delayed(const Duration(milliseconds: 500));
              },
              color: const Color(0xFF4A90D9),
              backgroundColor: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: groups.length,
                itemBuilder: (context, groupIndex) {
                  final groupName = groups.keys.elementAt(groupIndex);
                  final groupAlarms = groups[groupName]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Header - Feature D
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, groupIndex == 0 ? 0 : 20, 20, 12),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          tintColor: Colors.white,
                          child: Text(
                            groupName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      ...groupAlarms.asMap().entries.map((entry) {
                        final index = entry.key;
                        final alarm = entry.value;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _AlarmTile(alarm: alarm),
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: GradientFAB(
        icon: Icons.add_rounded,
        onPressed: () {
          Navigator.of(context).push(_fadeSlideRoute(const AddEditAlarmScreen()));
        },
      ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
          _showSortMenu = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90D9).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF4A90D9) : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, size: 16, color: Color(0xFF4A90D9)),
            ],
          ],
        ),
      ),
    );
  }
}

// Feature E: Search Delegate
class _AlarmSearchDelegate extends SearchDelegate<Alarm?> {
  final List<Alarm> alarms;
  final Function(Alarm) onSelect;

  _AlarmSearchDelegate({required this.alarms, required this.onSelect});

  @override
  String get searchFieldLabel => 'Search alarms';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.black38),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = alarms.where((alarm) {
      final q = query.toLowerCase();
      return alarm.label.toLowerCase().contains(q) ||
          alarm.formattedTimeWithPeriod.toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No alarms found', style: TextStyle(color: Colors.black45)),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final alarm = results[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90D9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alarm, color: Color(0xFF4A90D9)),
          ),
          title: Text(
            alarm.formattedTimeWithPeriod,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(alarm.label.isEmpty ? alarm.repeatDaysText : alarm.label),
                  trailing: Container(
                    width: 50,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: alarm.isEnabled
                          ? const LinearGradient(
                              colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                            )
                          : null,
                      color: alarm.isEnabled ? null : Colors.grey.shade300,
                    ),
                    child: Switch(
                      value: alarm.isEnabled,
                      activeColor: Colors.transparent,
                      onChanged: null,
                    ),
                  ),
          onTap: () {
            onSelect(alarm);
            close(context, alarm);
          },
        );
      },
    );
  }
}

class _AlarmTile extends StatefulWidget {
  final Alarm alarm;

  const _AlarmTile({required this.alarm});

  @override
  State<_AlarmTile> createState() => _AlarmTileState();
}

class _AlarmTileState extends State<_AlarmTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const List<String> _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  DateTime? _nextOccurrence(Alarm alarm) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);

    if (alarm.repeatDays.isEmpty) {
      if (base.isAfter(now)) return base;
      return base.add(const Duration(days: 1));
    }

    DateTime? best;
    for (final repeatDay in alarm.repeatDays) {
      final targetWeekday = repeatDay + 1;
      final delta = (targetWeekday - now.weekday + 7) % 7;
      var candidate = base.add(Duration(days: delta));
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 7));
      }
      if (best == null || candidate.isBefore(best)) {
        best = candidate;
      }
    }
    return best;
  }

  String _getRemainingTime(Alarm alarm) {
    if (!alarm.isEnabled) return 'Disabled';
    final next = _nextOccurrence(alarm);
    if (next == null) return '';
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return '';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours == 0 && minutes == 0) return 'Now';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final alarm = widget.alarm;
    final remainingTime = _getRemainingTime(alarm);
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Duplicate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Duplicate alarm
          final provider = context.read<AlarmProvider>();
          final newAlarm = Alarm(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            time: alarm.time,
            label: '${alarm.label} (Copy)',
            repeatDays: alarm.repeatDays,
            isEnabled: true,
            vibrate: alarm.vibrate,
            sound: alarm.sound,
          );
          provider.addAlarm(newAlarm);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Alarm duplicated'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<AlarmProvider>().deleteAlarm(alarm.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Alarm deleted'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        tintColor: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AddEditAlarmScreen(alarm: alarm),
                transitionDuration: const Duration(milliseconds: 250),
                reverseTransitionDuration: const Duration(milliseconds: 200),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final fade =
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
              ),
            );
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          alarm.formattedTimeWithPeriod.split(' ').first,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                            color: alarm.isEnabled ? Colors.white : Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          alarm.formattedTimeWithPeriod.split(' ').last,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: alarm.isEnabled ? Colors.white70 : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (alarm.label.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: alarm.isEnabled 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              alarm.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: alarm.isEnabled ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          alarm.repeatDaysText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: alarm.isEnabled ? Colors.white70 : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (alarm.isEnabled && remainingTime.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              remainingTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: List.generate(7, (index) {
                        final isActive = alarm.repeatDays.contains(index);
                        final bg = isActive
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1);
                        final fg = isActive ? Colors.white : Colors.white54;
                        return Container(
                          width: 30,
                          height: 30,
                          margin: EdgeInsets.only(right: index == 6 ? 0 : 8),
                          decoration: BoxDecoration(
                            color: alarm.repeatDays.isEmpty ? Colors.white.withOpacity(0.05) : bg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayLetters[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: alarm.repeatDays.isEmpty ? Colors.white38 : fg,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              GradientToggle(
                value: alarm.isEnabled,
                onChanged: (value) {
                  context.read<AlarmProvider>().toggleAlarm(alarm.id);
                },
                width: 56,
                height: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
