import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';

class ProjectSummaryScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onFeedbackTap;

  const ProjectSummaryScreen({
    super.key,
    required this.isDarkMode,
    required this.onFeedbackTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    final backgroundColor = isDarkMode ? TColors.backgroundDark : TColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
  
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left:16, right: 16, top: 16, bottom: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Overview Cards (2x2 grid)
            _buildOverviewSection(cardColor, textPrimary, textSecondary),
            const SizedBox(height: 24),
            
            // Status Overview with Chart
            _buildStatusOverviewSection(cardColor, textPrimary, textSecondary),
            const SizedBox(height: 24),
            
            // Priority Breakdown with Progress Bars
            _buildPrioritySection(cardColor, textPrimary, textSecondary),
            const SizedBox(height: 24),
            
            // Team Assignment Overview
            _buildTeamAssignmentSection(cardColor, textPrimary, textSecondary),
            const SizedBox(height: 24),
            
            // Feedback Section
            _buildFeedbackSection(cardColor, textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Color cardColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       
        const SizedBox(height: 8), // reduced from 16
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Done',
                '24',
                Iconsax.tick_circle,
                TColors.green,
                cardColor,
                textPrimary,
                textSecondary,
              ),
            ),
            const SizedBox(width: 8), // reduced from 12
            Expanded(
              child: _buildOverviewCard(
                'Updated',
                '8',
                Iconsax.edit,
                TColors.lightBlue,
                cardColor,
                textPrimary,
                textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // reduced from 12
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Created',
                '32',
                Iconsax.add_circle,
                TColors.accentBlue,
                cardColor,
                textPrimary,
                textSecondary,
              ),
            ),
            const SizedBox(width: 8), // reduced from 12
            Expanded(
              child: _buildOverviewCard(
                'Due Soon',
                '5',
                Iconsax.clock,
                TColors.yellow,
                cardColor,
                textPrimary,
                textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String count, IconData icon, Color iconColor, Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(12), // reduced from 20
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12), // reduced from 16
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // slightly reduced
            blurRadius: 6, // reduced from 10
            offset: const Offset(0, 2), // reduced
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8), // reduced from 12
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8), // reduced from 12
            ),
            child: Icon(icon, color: iconColor, size: 18), // reduced from 24
          ),
          const SizedBox(height: 8), // reduced from 16
          Row(
            children: [
            Text(
            count,
            style: TextStyle(
              fontSize: 20, // reduced from 28
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
           const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11, // reduced from 14
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2), 
            ],
          ),
          Text(
            "in the last 7 days",
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
         
        ],
      ),
    );
  }

  Widget _buildStatusOverviewSection(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColors.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.chart_1, color: TColors.lightBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Status Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    color: TColors.green,
                    value: 40,
                    title: '40%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: TColors.lightBlue,
                    value: 35,
                    title: '35%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: TColors.yellow,
                    value: 25,
                    title: '25%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Done', TColors.green, textPrimary),
              _buildLegendItem('In Progress', TColors.lightBlue, textPrimary),
              _buildLegendItem('To Do', TColors.yellow, textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySection(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.flag, color: TColors.error, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Priority Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPriorityProgressBar('Highest', 15, const Color(0xFFDC2626), textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildPriorityProgressBar('High', 25, TColors.yellow, textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildPriorityProgressBar('Medium', 35, TColors.lightBlue, textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildPriorityProgressBar('Low', 25, TColors.green, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildPriorityProgressBar(String label, double percentage, Color color, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 8,
          percent: percentage / 100,
          backgroundColor: color.withOpacity(0.2),
          progressColor: color,
          barRadius: const Radius.circular(4),
          animation: true,
          animationDuration: 1000,
        ),
      ],
    );
  }

  Widget _buildTeamAssignmentSection(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.people, color: TColors.accentBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Team Assignment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAssignmentCard('Active Members', '12', Iconsax.user_tick, TColors.green, cardColor, textPrimary, textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAssignmentCard('Avg Tasks/Member', '2.7', Iconsax.task, TColors.lightBlue, cardColor, textPrimary, textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(String title, String value, IconData icon, Color iconColor, Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(Color cardColor, Color textPrimary, Color textSecondary) {
    return GestureDetector(
      onTap: onFeedbackTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: TColors.blueGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: TColors.primaryBlue.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.message_text,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Give Feedback',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help us improve your experience',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}