import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class AllTeamScreen extends StatelessWidget {
  const AllTeamScreen({super.key});

  // Dummy data for demonstration
  List<Map<String, dynamic>> get _teams => [
        {
          "name": "Omni",
          "members": 12,
          "lead": "Andrew",
          "icon": Icons.groups_rounded,
          "color": TColors.buttonPrimary,
        },
        {
          "name": "Designers",
          "members": 7,
          "lead": "Alice",
          "icon": Icons.palette_rounded,
          "color": TColors.purple,
        },
        {
          "name": "QA",
          "members": 5,
          "lead": "Bob",
          "icon": Icons.bug_report_rounded,
          "color": TColors.quickActionYellow,
        },
        {
          "name": "Product",
          "members": 8,
          "lead": "Jane",
          "icon": Icons.lightbulb_rounded,
          "color": TColors.green,
        },
      ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    if (_teams.isEmpty) {
      return Center(
        child: Text(
          'No teams found.',
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white70 : TColors.textSecondaryDark,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: _teams.length,
        itemBuilder: (context, idx) {
          final team = _teams[idx];
          return _buildTeamCard(context, team, isDarkMode);
        },
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Map<String, dynamic> team, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Team Icon
            CircleAvatar(
              radius: 20,
              backgroundColor: (team['color'] as Color).withOpacity(0.13),
              child: Icon(
                team['icon'] as IconData,
                color: team['color'] as Color,
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            // Team Name
            Text(
              team['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDarkMode ? Colors.white : TColors.backgroundDark,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Members
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_rounded, size: 11, color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimaryLight),
                const SizedBox(width: 3),
                Text(
                  '${team['members']} members',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Lead
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_rounded, size: 11, color: isDarkMode ? TColors.green : TColors.buttonPrimary),
                const SizedBox(width: 3),
                Text(
                  'Lead: ${team['lead']}',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // View Team Button
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_rounded, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'View Team',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // TODO: Navigate to team detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Team detail coming soon!')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
