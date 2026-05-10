import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;
  
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Direct', 'Unread', 'Starred', 'Important'];
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor:  isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernAppBar(isDarkMode),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationStats(isDarkMode),
                      const SizedBox(height: 32),
                      _buildFilterTabs(isDarkMode),
                      const SizedBox(height: 32),
                      _buildEmptyState(isDarkMode),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(isDarkMode),
    );
  }

  Widget _buildModernAppBar(bool isDarkMode) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 80,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      // leading: Padding(
      //   padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12),
      //   child: GestureDetector(
      //     onTap: () => Navigator.pop(context),
      //     child: Container(
      //       decoration: BoxDecoration(
      //         color: isDarkMode
      //            // ? Colors.white.withOpacity(0.07)
      //             : Colors.black.withOpacity(0.06),
      //         shape: BoxShape.circle,
      //         boxShadow: [
      //           BoxShadow(
      //             color: isDarkMode
      //                // ? Colors.black.withOpacity(0.18)
      //                 : Colors.grey.withOpacity(0.10),
      //             blurRadius: 8,
      //             offset: const Offset(0, 2),
      //           ),
      //         ],
      //         border: Border.all(
      //           color: isDarkMode
      //             //  ? Colors.white.withOpacity(0.10)
      //               : const Color(0xFFE2E8F0),
      //           width: 1.2,
      //         ),
      //       ),
      //       child: Icon(
      //         Icons.arrow_back_rounded,
      //         color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
      //         size: 28,
      //       ),
      //     ),
      //   ),
      // ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E293B).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 24, bottom: 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stay updated with your workspace',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAppBarActions(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarActions(bool isDarkMode) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.search_rounded,
          onPressed: () {},
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.more_horiz_rounded,
          onPressed: () => _showMoreOptions(context),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.13)
                    : Colors.grey.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.10)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationStats(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total',
            value: '0',
            icon: Icons.notifications_none,
            color: const Color(0xFF1E40AF),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 6), // reduced spacing
        Expanded(
          child: _buildStatCard(
            title: 'Unread',
            value: '0',
            icon: Icons.mark_email_unread,
            color: const Color(0xFFDC2626),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 6), // reduced spacing
        Expanded(
          child: _buildStatCard(
            title: 'Starred',
            value: '0',
            icon: Icons.star_outline,
            color: const Color(0xFFF59E0B),
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // reduced padding
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF1E293B).withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(8), // reduced radius
        border: Border.all(
          color: isDarkMode 
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.05)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 6, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4), // reduced padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4), // reduced radius
            ),
            child: Icon(
              icon,
              color: color,
              size: 10, // reduced icon size
            ),
          ),
          const SizedBox(height: 4), // reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 14, // reduced font size
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 1), // reduced spacing
          Text(
            title,
            style: TextStyle(
              fontSize: 7, // reduced font size
              fontWeight: FontWeight.w500,
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by',
          style: TextStyle(
            fontSize: 10, // reduced font size
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6), // reduced spacing
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _tabs.map((tab) {
              final isSelected = _selectedTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 4), // reduced spacing
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTab = tab;
                    });
                  },
                  borderRadius: BorderRadius.circular(8), // reduced radius
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // reduced padding
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF1E40AF)
                          : isDarkMode 
                              ? const Color(0xFF1E293B).withOpacity(0.6)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8), // reduced radius
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF1E40AF)
                            : isDarkMode 
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withOpacity(0.12),
                          blurRadius: 6, // reduced blur
                          offset: const Offset(0, 2),
                        ),
                      ] : [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.02),
                          blurRadius: 3, // reduced blur
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 8, // reduced font size
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Colors.white
                            : isDarkMode 
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // reduced padding
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF1E293B).withOpacity(0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(8), // reduced radius
        border: Border.all(
          color: isDarkMode 
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8), // reduced padding
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1E40AF).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 18, // reduced icon size
              color: const Color(0xFF1E40AF).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8), // reduced spacing
          Text(
            "All caught up!",
            style: TextStyle(
              fontSize: 12, // reduced font size
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4), // reduced spacing
          Text(
            "No new notifications at the moment.\nWhen there's activity on your workspace,\nwe'll let you know right here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8, // reduced font size
              height: 1.2, // reduced line height
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8), // reduced spacing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // reduced padding
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // reduced radius
              border: Border.all(
                color: const Color(0xFF1E40AF).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh,
                  size: 10, // reduced icon size
                  color: Color(0xFF1E40AF),
                ),
                SizedBox(width: 4), // reduced spacing
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 8, // reduced font size
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB(bool isDarkMode) {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E40AF).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showSnoozeOptions(context),
          backgroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Snooze',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(10), // reduced margin
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(14), // reduced radius
            border: Border.all(
              color: isDarkMode 
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28, // reduced width
                height: 3, // reduced height
                margin: const EdgeInsets.only(top: 8), // reduced margin
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12), // reduced padding
                child: Column(
                  children: [
                    _buildBottomSheetItem(
                      icon: Icons.mark_email_read,
                      title: 'Mark all as read',
                      subtitle: 'Clear all unread notifications',
                      onTap: () => Navigator.pop(context),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6), // reduced spacing
                    _buildBottomSheetItem(
                      icon: Icons.settings,
                      title: 'Notification settings',
                      subtitle: 'Manage your preferences',
                      onTap: () => Navigator.pop(context),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6), // reduced spacing
                    _buildBottomSheetItem(
                      icon: Icons.delete_outline,
                      title: 'Clear all',
                      subtitle: 'Remove all notifications',
                      onTap: () => Navigator.pop(context),
                      isDarkMode: isDarkMode,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // reduced radius
      child: Container(
        padding: const EdgeInsets.all(10), // reduced padding
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF334155).withOpacity(0.22)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12), // reduced radius
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7), // reduced padding
              decoration: BoxDecoration(
                color: isDestructive 
                    ? const Color(0xFFDC2626).withOpacity(0.09)
                    : const Color(0xFF1E40AF).withOpacity(0.09),
                borderRadius: BorderRadius.circular(8), // reduced radius
              ),
              child: Icon(
                icon,
                color: isDestructive 
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF1E40AF),
                size: 16, // reduced icon size
              ),
            ),
            const SizedBox(width: 10), // reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13, // reduced font size
                      fontWeight: FontWeight.w600,
                      color: isDestructive 
                          ? const Color(0xFFDC2626)
                          : isDarkMode 
                              ? Colors.white
                              : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 1), // reduced spacing
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10, // reduced font size
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12, // reduced icon size
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnoozeOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(8), // reduced margin
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(10), // reduced radius
            border: Border.all(
              color: isDarkMode 
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24, // reduced width
                height: 2, // reduced height
                margin: const EdgeInsets.only(top: 6), // reduced margin
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(1), // reduced radius
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8), // reduced padding
                child: Column(
                  children: [
                    Text(
                      'Snooze Notifications',
                      style: TextStyle(
                        fontSize: 10, // reduced font size
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2), // reduced spacing
                    Text(
                      'Temporarily pause notifications for',
                      style: TextStyle(
                        fontSize: 7, // reduced font size
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6), // reduced spacing
                    ...['15 minutes', '30 minutes', '1 hour', '2 hours', '4 hours', '1 day']
                        .map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4), // reduced spacing
                        child: _buildSnoozeOption(option, isDarkMode),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSnoozeOption(String option, bool isDarkMode) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(8), // reduced radius
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8), // reduced padding
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF334155).withOpacity(0.3)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8), // reduced radius
          border: Border.all(
            color: isDarkMode 
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4), // reduced padding
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4), // reduced radius
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF1E40AF),
                size: 10, // reduced icon size
              ),
            ),
            const SizedBox(width: 6), // reduced spacing
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 8, // reduced font size
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 10, // reduced icon size
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}