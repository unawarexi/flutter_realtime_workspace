import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AdvancedPullRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoading;
  final bool enablePullDown;
  final bool enablePullUp;
  final String? refreshText;
  final String? loadingText;
  final Color? primaryColor;
  final RefreshStyle refreshStyle;
  final String? refreshKey; // <-- Add this

  const AdvancedPullRefresh({
    super.key,
    required this.child,
    this.onRefresh,
    this.onLoading,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.refreshText,
    this.loadingText,
    this.primaryColor,
    this.refreshStyle = RefreshStyle.Follow,
    this.refreshKey, // <-- Add this
  });

  @override
  State<AdvancedPullRefresh> createState() => _AdvancedPullRefreshState();
}

class _AdvancedPullRefreshState extends State<AdvancedPullRefresh>
    with TickerProviderStateMixin {
  late RefreshController _refreshController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Use global controller if key is provided, else local
    if (widget.refreshKey != null) {
      _refreshController =
          GlobalRefreshController().getController(widget.refreshKey!);
    } else {
      _refreshController = RefreshController(initialRefresh: false);
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Only dispose if not using global controller
    if (widget.refreshKey == null) {
      _refreshController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    _animationController.forward();
    try {
      await widget.onRefresh?.call();
      _refreshController.refreshCompleted();

      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Refreshed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      _refreshController.refreshFailed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Refresh failed: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      _animationController.reverse();
    }
  }

  void _onLoading() async {
    try {
      await widget.onLoading?.call();
      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: widget.enablePullDown,
      enablePullUp: widget.enablePullUp,
      onRefresh: widget.onRefresh != null ? _onRefresh : null,
      onLoading: widget.onLoading != null ? _onLoading : null,
      header: CustomHeader(
        builder: (context, mode) {
          return SizedBox(
            height: 80,
            child: Center(
              child:
                  _buildRefreshHeader(mode ?? RefreshStatus.idle, primaryColor),
            ),
          );
        },
        height: 80,
        refreshStyle: widget.refreshStyle,
      ),
      footer: CustomFooter(
        builder: (context, mode) {
          return SizedBox(
            height: 60,
            child: Center(
              child: _buildLoadingFooter(mode ?? LoadStatus.idle, primaryColor),
            ),
          );
        },
        height: 60,
      ),
      child: widget.child,
    );
  }

  Widget _buildRefreshHeader(RefreshStatus mode, Color primaryColor) {
    switch (mode) {
      case RefreshStatus.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_downward,
              color: primaryColor.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              widget.refreshText ?? 'Pull down to refresh',
              style: TextStyle(
                color: primaryColor.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case RefreshStatus.canRefresh:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 3.14159, // 180 degrees
                  child: Icon(
                    Icons.arrow_downward,
                    color: primaryColor,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Release to refresh',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case RefreshStatus.refreshing:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitThreeBounce(
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                'Refreshing...',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case RefreshStatus.completed:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Refresh completed',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case RefreshStatus.failed:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Refresh failed',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingFooter(LoadStatus mode, Color primaryColor) {
    switch (mode) {
      case LoadStatus.loading:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCircle(
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.loadingText ?? 'Loading more...',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case LoadStatus.canLoading:
        return Text(
          'Pull up to load more',
          style: TextStyle(
            color: primaryColor.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );

      case LoadStatus.noMore:
        return const Text(
          'No more data',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );

      case LoadStatus.failed:
        return const Text(
          'Load failed, tap to retry',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// Global refresh controller for app-wide access
class GlobalRefreshController {
  static final GlobalRefreshController _instance =
      GlobalRefreshController._internal();
  factory GlobalRefreshController() => _instance;
  GlobalRefreshController._internal();

  final Map<String, RefreshController> _controllers = {};

  RefreshController getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = RefreshController(initialRefresh: false);
    }
    return _controllers[key]!;
  }

  void refreshAll() {
    for (var controller in _controllers.values) {
      if (!controller.isRefresh && !controller.isLoading) {
        controller.requestRefresh();
      }
    }
  }

  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

// Enhanced version with network connectivity check
class NetworkAwareRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoading;
  final bool enablePullDown;
  final bool enablePullUp;

  const NetworkAwareRefresh({
    super.key,
    required this.child,
    this.onRefresh,
    this.onLoading,
    this.enablePullDown = true,
    this.enablePullUp = false,
  });

  @override
  State<NetworkAwareRefresh> createState() => _NetworkAwareRefreshState();
}

class _NetworkAwareRefreshState extends State<NetworkAwareRefresh> {
  final bool _isConnected = true;

  Future<void> _handleRefresh() async {
    // Check network connectivity before refreshing
    // You can add connectivity_plus package for real network checking
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('No internet connection'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedPullRefresh(
      onRefresh: _handleRefresh,
      onLoading: widget.onLoading,
      enablePullDown: widget.enablePullDown,
      enablePullUp: widget.enablePullUp,
      child: widget.child,
    );
  }
}
