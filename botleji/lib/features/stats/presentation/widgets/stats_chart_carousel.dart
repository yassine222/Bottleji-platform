import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/collection/presentation/providers/collection_attempts_provider.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

class StatsChartCarousel extends ConsumerStatefulWidget {
  final CollectorStats stats;

  const StatsChartCarousel({
    super.key,
    required this.stats,
  });

  @override
  ConsumerState<StatsChartCarousel> createState() => _StatsChartCarouselState();
}

class _StatsChartCarouselState extends ConsumerState<StatsChartCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page indicator
        _buildPageIndicator(),
        const SizedBox(height: 16),
        
        // Chart carousel
        SizedBox(
          height: 260,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              _buildCollectedChart(),
              _buildExpiredChart(),
              _buildCancelledChart(),
            ],
          ),
        ),
        const SizedBox(height: 16), // Add bottom spacing
      ],
    );
  }


  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index 
                ? const Color(0xFF00695C) 
                : const Color(0xFF00695C).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildCollectedChart() {
    return _buildChartContent(
      title: 'Collected',
      value: widget.stats.collected,
      color: Colors.green,
      icon: Icons.recycling,
      chart: _buildAreaChart(
        title: 'Collections Over Time',
        color: Colors.green,
        data: _generateCollectedData(),
      ),
    );
  }

  Widget _buildExpiredChart() {
    return _buildChartContent(
      title: 'Expired',
      value: widget.stats.expired,
      color: Colors.purple,
      icon: Icons.timer_off,
      chart: _buildAreaChart(
        title: 'Expired Over Time',
        color: Colors.purple,
        data: _generateExpiredData(),
      ),
    );
  }

  Widget _buildCancelledChart() {
    return _buildChartContent(
      title: 'Cancelled',
      value: widget.stats.cancelled,
      color: Colors.red,
      icon: Icons.cancel,
      chart: _buildAreaChart(
        title: 'Cancelled Over Time',
        color: Colors.red,
        data: _generateCancelledData(),
      ),
    );
  }

  Widget _buildChartContent({
    required String title,
    required int value,
    required Color color,
    required IconData icon,
    required Widget chart,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '$value total',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chart
          SizedBox(
            height: 150,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChart({
    required String title,
    required Color color,
    required List<FlSpot> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.3),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < 7) {
                    final now = DateTime.now();
                    final date = now.subtract(Duration(days: 6 - index));
                    final today = now.weekday;
                    final yesterday = today == 1 ? 7 : today - 1; // Handle Sunday as 1
                    
                    String dayLabel;
                    if (date.weekday == today) {
                      dayLabel = 'Today';
                    } else if (date.weekday == yesterday) {
                      dayLabel = 'Yesterday';
                    } else {
                      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      dayLabel = dayNames[date.weekday - 1];
                    }
                    
                    return Text(
                      dayLabel,
                      style: const TextStyle(fontSize: 9),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateCollectedData() {
    return _generateRealDailyData('collected');
  }

  List<FlSpot> _generateExpiredData() {
    return _generateRealDailyData('expired');
  }

  List<FlSpot> _generateCancelledData() {
    return _generateRealDailyData('cancelled');
  }


  List<FlSpot> _generateRealDailyData(String outcome) {
    try {
      // Get collection attempts from the provider (read only, don't watch)
      final attemptsAsync = ref.read(collectionAttemptsProvider);
      
      return attemptsAsync.when(
        data: (response) {
          return _generateRealDailyDataFromResponse(response, outcome);
        },
        loading: () {
          return List.generate(7, (index) => FlSpot(index.toDouble(), 0.0));
        },
        error: (error, stack) {
          return List.generate(7, (index) => FlSpot(index.toDouble(), 0.0));
        },
      );
    } catch (e) {
      // Return empty data on error
      return List.generate(7, (index) => FlSpot(index.toDouble(), 0.0));
    }
  }

  List<FlSpot> _generateRealDailyDataFromResponse(CollectionAttemptsListResponse response, String outcome) {
    
    // Group attempts by date and outcome
    final Map<DateTime, int> dailyCounts = {};
    
    // Initialize last 7 days with 0 counts
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      dailyCounts[dateOnly] = 0;
    }
    
    // Count attempts by date and outcome
    int matchingAttempts = 0;
    for (final attempt in response.attempts) {
      if (attempt.outcome == outcome && attempt.completedAt != null) {
        matchingAttempts++;
        final completedDate = attempt.completedAt!.toLocal();
        final dateOnly = DateTime(completedDate.year, completedDate.month, completedDate.day);
        
        // Check if this date is within the last 7 days
        final daysDiff = now.difference(dateOnly).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyCounts[dateOnly] = (dailyCounts[dateOnly] ?? 0) + 1;
          print('🕐 Found $outcome attempt on ${dateOnly.toString().split(' ')[0]}');
        }
      }
    }
    
    print('🕐 Found $matchingAttempts $outcome attempts in last 7 days');
    
    // Generate chart data for last 7 days
    final List<FlSpot> chartData = [];
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final count = dailyCounts[dateOnly] ?? 0;
      chartData.add(FlSpot(i.toDouble(), count.toDouble()));
      print('🕐 Day $i: ${dateOnly.toString().split(' ')[0]} = $count $outcome');
    }
    
    return chartData;
  }

}
