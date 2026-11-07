import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ProgressOverviewPager extends StatefulWidget {
  final int currentPage;
  final List<Widget> pages;
  final ValueChanged<int> onPageChanged;

  const ProgressOverviewPager({
    super.key,
    required this.currentPage,
    required this.pages,
    required this.onPageChanged,
  });

  @override
  State<ProgressOverviewPager> createState() => _ProgressOverviewPagerState();
}

class _ProgressOverviewPagerState extends State<ProgressOverviewPager> {
  double _dragDistance = 0;
  int _slideDirection = 1;

  @override
  void didUpdateWidget(covariant ProgressOverviewPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage != oldWidget.currentPage) {
      _slideDirection = widget.currentPage > oldWidget.currentPage ? 1 : -1;
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final delta = velocity.abs() >= 100 ? velocity : _dragDistance;
    if (delta.abs() < 36) return;

    final nextPage = widget.currentPage + (delta < 0 ? 1 : -1);
    if (nextPage < 0 || nextPage >= widget.pages.length) return;
    widget.onPageChanged(nextPage);
  }

  @override
  Widget build(BuildContext context) {
    const labels = ["Today's progress", 'Weekly progress', 'Monthly activity'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: const ValueKey('home-progress-overview-swipe-area'),
          onHorizontalDragStart: (_) => _dragDistance = 0,
          onHorizontalDragUpdate: (details) {
            _dragDistance += details.primaryDelta ?? 0;
          },
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) {
                final isCurrent =
                    child.key == ValueKey<int>(widget.currentPage);
                final offset = isCurrent
                    ? Offset(_slideDirection.toDouble(), 0)
                    : Offset(-_slideDirection.toDouble(), 0);

                return SlideTransition(
                  position: Tween<Offset>(
                    begin: offset,
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(widget.currentPage),
                child: widget.pages[widget.currentPage],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pages.length, (page) {
            final isSelected = widget.currentPage == page;
            return Semantics(
              button: true,
              label: labels[page],
              child: InkWell(
                key: ValueKey('progress-page-indicator-$page'),
                onTap: () => widget.onPageChanged(page),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: isSelected ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
