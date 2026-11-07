import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  late final PageController _pageController;
  late List<double?> _pageHeights;
  bool _isWrapping = false;

  @override
  void initState() {
    super.initState();
    _pageHeights = List<double?>.filled(widget.pages.length, null);
    _pageController = PageController(initialPage: widget.currentPage + 1);
  }

  @override
  void didUpdateWidget(covariant ProgressOverviewPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages.length != oldWidget.pages.length) {
      _pageHeights = List<double?>.filled(widget.pages.length, null);
    }

    if (widget.currentPage != oldWidget.currentPage &&
        !_isWrapping &&
        _pageController.hasClients) {
      _pageController.animateToPage(
        widget.currentPage + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _reportPageHeight(int index, Size size) {
    if (!mounted || index >= _pageHeights.length) return;
    final oldHeight = _pageHeights[index];
    if (oldHeight != null && (oldHeight - size.height).abs() < 0.5) return;

    setState(() {
      _pageHeights[index] = size.height;
    });
  }

  void _handlePageChanged(int virtualPage) {
    final pageCount = widget.pages.length;
    if (pageCount == 0) return;

    if (virtualPage == 0 || virtualPage == pageCount + 1) {
      final wrappedPage = virtualPage == 0 ? pageCount - 1 : 0;
      _isWrapping = true;
      widget.onPageChanged(wrappedPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(virtualPage == 0 ? pageCount : 1);
        }
        _isWrapping = false;
      });
      return;
    }

    final page = virtualPage - 1;
    if (page != widget.currentPage) {
      widget.onPageChanged(page);
    }
  }

  int _pageIndexForVirtualPage(int virtualPage) {
    if (virtualPage == 0) return widget.pages.length - 1;
    if (virtualPage == widget.pages.length + 1) return 0;
    return virtualPage - 1;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ["Today's progress", 'Weekly progress', 'Monthly activity'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final activeHeight =
            _pageHeights[widget.currentPage] ??
            _pageHeights.firstWhere(
              (height) => height != null,
              orElse: () => null,
            ) ??
            220;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Offstage(
              child: UnconstrainedBox(
                constrainedAxis: Axis.horizontal,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.pages.length, (index) {
                      return SizedBox(
                        width: width,
                        child: _SizeReporter(
                          onSizeChanged: (size) =>
                              _reportPageHeight(index, size),
                          child: widget.pages[index],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              child: SizedBox(
                height: activeHeight,
                child: PageView.builder(
                  key: const ValueKey('home-progress-overview-swipe-area'),
                  controller: _pageController,
                  itemCount: widget.pages.length + 2,
                  onPageChanged: _handlePageChanged,
                  clipBehavior: Clip.none,
                  itemBuilder: (context, virtualPage) {
                    final page =
                        widget.pages[_pageIndexForVirtualPage(virtualPage)];
                    return OverflowBox(
                      alignment: Alignment.topCenter,
                      minWidth: width,
                      maxWidth: width,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: SizedBox(width: width, child: page),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pages.length, (page) {
                final isSelected = widget.currentPage == page;
                return Semantics(
                  key: ValueKey('progress-page-indicator-$page'),
                  button: true,
                  label: labels[page],
                  selected: isSelected,
                  child: InkWell(
                    onTap: () => widget.onPageChanged(page),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: isSelected ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
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
      },
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSizeChanged;

  const _SizeReporter({required this.onSizeChanged, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSizeReporter renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _reportedSize;

  @override
  void performLayout() {
    super.performLayout();
    if (_reportedSize == size) return;
    _reportedSize = size;
    final measuredSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSizeChanged(measuredSize);
    });
  }
}
