import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:gantt_chart/gantt_chart.dart';

class GanttTimelineDashboard extends StatelessWidget {
  const GanttTimelineDashboard({Key? key, required String title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gantt Timeline Dashboard'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Neumorphic(
        style: const NeumorphicStyle(
          depth: 8,
          intensity: 0.5,
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildGanttChart(),
        ),
      ),
    );
  }

  Widget _buildGanttChart() {
    return GanttChartView(
      maxDuration: const Duration(days: 30 * 2), // Two-month max view
      startDate: DateTime(2024, 9, 1), // Start date for the Gantt timeline
      dayWidth: 40, // Column width for each day
      eventHeight: 35, // Row height for each event
      stickyAreaWidth: 220, // Sticky area for task names
      showStickyArea: true, // Show sticky area
      showDays: true, // Show days on the timeline
      startOfTheWeek: WeekDay.sunday, // Week starts on Sunday
      weekEnds: const {WeekDay.friday, WeekDay.saturday}, // Custom weekends

      // Custom holiday logic
      isExtraHoliday: (context, day) {
        return DateUtils.isSameDay(
            DateTime(2024, 10, 1), day); // Custom holiday
      },

      // Events: Defining tasks with both relative and absolute start times
      events: [
        // Task relative to the startDate
        GanttRelativeEvent(
          relativeToStart: const Duration(days: 0), // Start from day 0
          duration: const Duration(days: 5), // Last 5 days
          displayName: 'Project Planning', // Task display name
        ),
        // Task with absolute start and end dates
        GanttAbsoluteEvent(
          startDate: DateTime(2024, 9, 10), // Start on this date
          endDate: DateTime(2024, 9, 15), // End on this date
          displayName: 'Design Mockups', // Task display name
        ),
        GanttAbsoluteEvent(
          startDate: DateTime(2024, 9, 16),
          endDate: DateTime(2024, 9, 25),
          displayName: 'Development Phase',
        ),
        GanttAbsoluteEvent(
          startDate: DateTime(2024, 9, 26),
          endDate: DateTime(2024, 9, 30),
          displayName: 'Testing & QA',
        ),
      ],
    );
  }
}
