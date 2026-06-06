import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(Icons.auto_awesome_outlined, 'AI Assistant', 'Smart help',
          const Color(0xFF8B5CF6), '/ai'),
      _Feature(Icons.cloud_outlined, 'Files & Storage', 'Manage documents',
          const Color(0xFF0EA5E9), '/storage'),
      _Feature(Icons.route_outlined, 'Workflows', 'Automate processes',
          const Color(0xFFEC4899), '/workflows'),
      _Feature(Icons.integration_instructions_outlined, 'Integrations',
          'Connect tools', const Color(0xFF14B8A6), '/integrations'),
      _Feature(Icons.confirmation_number_outlined, 'Tickets', 'Support queue',
          const Color(0xFFF59E0B), '/tickets'),
      _Feature(Icons.receipt_long_outlined, 'Billing', 'Manage invoices',
          const Color(0xFF10B981), '/billing'),
    ];

    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 560),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Features',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isDark ? TColors.textDark : TColors.textLight,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: TSizes.sm,
              mainAxisSpacing: TSizes.sm,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, i) {
              final f = features[i];
              return TWidgetAnimations.fadeIn(
                delay: Duration(milliseconds: 40 * i),
                child: GestureDetector(
                  onTap: () => context.push(f.route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.sm, vertical: TSizes.xs),
                    decoration: BoxDecoration(
                      color: isDark ? TColors.darkCard : TColors.lightSurface,
                      borderRadius: BorderRadius.circular(TSizes.radiusMd),
                      border: Border.all(
                          color: isDark
                              ? TColors.darkBorder
                              : TColors.lightBorder),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : Colors.grey)
                              .withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: f.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(f.icon, color: f.color, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                f.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? TColors.textDark
                                      : TColors.textLight,
                                ),
                              ),
                              Text(
                                f.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? TColors.darkMuted
                                      : TColors.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  _Feature(this.icon, this.title, this.subtitle, this.color, this.route);
}
