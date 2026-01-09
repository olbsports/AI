import 'package:flutter/material.dart';
import '../../models/planning.dart';
import '../../theme/app_theme.dart';

/// Expandable FAB for quick event creation
class QuickAddEventFAB extends StatefulWidget {
  final Function(EventType type, DateTime? date) onEventTypeSelected;
  final VoidCallback? onHealthReminderTap;
  final DateTime? selectedDate;

  const QuickAddEventFAB({
    super.key,
    required this.onEventTypeSelected,
    this.onHealthReminderTap,
    this.selectedDate,
  });

  @override
  State<QuickAddEventFAB> createState() => _QuickAddEventFABState();
}

class _QuickAddEventFABState extends State<QuickAddEventFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  // Quick access event types
  static const _quickTypes = [
    EventType.training,
    EventType.lesson,
    EventType.competition,
    EventType.veterinary,
    EventType.farrier,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded menu items
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Health reminder option
                if (widget.onHealthReminderTap != null) ...[
                  _buildMiniAction(
                    icon: Icons.vaccines,
                    label: 'Rappel sante',
                    color: const Color(0xFFFFEB3B),
                    onTap: () {
                      _toggle();
                      widget.onHealthReminderTap!();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Quick event types
                ..._quickTypes.reversed.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMiniAction(
                      icon: type.icon,
                      label: type.displayName,
                      color: Color(type.defaultColor),
                      onTap: () {
                        _toggle();
                        widget.onEventTypeSelected(type, widget.selectedDate);
                      },
                    ),
                  );
                }),

                // More types option
                _buildMiniAction(
                  icon: Icons.more_horiz,
                  label: 'Plus d\'options',
                  color: AppColors.textSecondary,
                  onTap: () {
                    _toggle();
                    _showAllTypesSheet(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(_isExpanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Mini FAB
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllTypesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AllEventTypesSheet(
        onTypeSelected: (type) {
          Navigator.pop(context);
          widget.onEventTypeSelected(type, widget.selectedDate);
        },
      ),
    );
  }
}

/// Sheet showing all event types
class _AllEventTypesSheet extends StatelessWidget {
  final Function(EventType) onTypeSelected;

  const _AllEventTypesSheet({required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type d\'evenement',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: EventType.values.map((type) {
              final color = Color(type.defaultColor);
              return InkWell(
                onTap: () => onTypeSelected(type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon, color: color, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Simple FAB with speed dial options
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialChild> children;
  final Widget? child;
  final Color? backgroundColor;

  const SpeedDialFAB({
    super.key,
    required this.children,
    this.child,
    this.backgroundColor,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Children (speed dial options)
        ...widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(
                index * 0.1,
                0.5 + index * 0.1,
                curve: Curves.easeOut,
              ),
            ),
          );

          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (child.label != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          child.label!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (child.label != null) const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'speed_dial_$index',
                      backgroundColor: child.backgroundColor,
                      onPressed: () {
                        _toggle();
                        child.onTap();
                      },
                      child: child.child,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Main FAB
        FloatingActionButton(
          backgroundColor: widget.backgroundColor,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: widget.child ?? Icon(_isOpen ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Speed dial child item
class SpeedDialChild {
  final Widget child;
  final String? label;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const SpeedDialChild({
    required this.child,
    this.label,
    this.backgroundColor,
    required this.onTap,
  });
}

/// Animated FAB that shows/hides based on scroll
class HidingFAB extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPressed;
  final Widget? child;
  final String? tooltip;

  const HidingFAB({
    super.key,
    required this.scrollController,
    required this.onPressed,
    this.child,
    this.tooltip,
  });

  @override
  State<HidingFAB> createState() => _HidingFABState();
}

class _HidingFABState extends State<HidingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _visible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.value = 1.0;
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;

    if (delta > 5 && _visible) {
      setState(() => _visible = false);
      _controller.reverse();
    } else if (delta < -5 && !_visible) {
      setState(() => _visible = true);
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        child: widget.child ?? const Icon(Icons.add),
      ),
    );
  }
}
