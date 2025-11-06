import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/collection/presentation/providers/collection_attempts_provider.dart';
import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'package:botleji/core/services/timezone_service.dart';

class StatsChartCarousel extends ConsumerStatefulWidget {
  final CollectorStats stats;
  final String timeRange;

  const StatsChartCarousel({
    super.key,
    required this.stats,
    required this.timeRange,
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
          height: 320,
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
      value: _getWeeklyCount('collected'),
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
      value: _getWeeklyCount('expired'),
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
      value: _getWeeklyCount('cancelled'),
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
                      '$value total ${_getTimeRangeText()}',
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
            height: 200,
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
    final sortedData = [...data]..sort((a, b) => a.x.compareTo(b.x));
    final minX = sortedData.isEmpty ? null : sortedData.first.x - 0.4;
    final maxX = sortedData.isEmpty ? null : sortedData.last.x + 0.4;
    final maxY = data.isEmpty
        ? 5.0
        : data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b).ceil().toDouble();

    return Container(
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
            ),
          ),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY == 0 ? 5 : (maxY * 1.2).ceil().toDouble(),
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
                  if ((value - value.roundToDouble()).abs() > 0.01) {
                    return const SizedBox.shrink();
                  }
                  final index = value.round();
                  final dataPoints = _getDataPointsForTimeRange();

                  if (index >= 0 && index < dataPoints) {
                    return Text(
                      _getXAxisLabel(index),
                      style: const TextStyle(fontSize: 9),
                    );
                  }
                  return const SizedBox.shrink();
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
    return _generateRealData('collected');
  }

  List<FlSpot> _generateExpiredData() {
    return _generateRealData('expired');
  }

  List<FlSpot> _generateCancelledData() {
    return _generateRealData('cancelled');
  }

  int _getWeeklyCount(String outcome) {
    try {
      final attemptsAsync = ref.read(collectionAttemptsProvider);
      
      return attemptsAsync.when(
        data: (response) {
          if (response.attempts.isEmpty) {
            return 0;
          }
          return _getWeeklyCountFromCollectionAttempts(response.attempts, outcome);
        },
        loading: () => 0,
        error: (error, stack) => 0,
      );
    } catch (e) {
      return 0;
    }
  }

  int _getWeeklyCountFromCollectionAttempts(List<CollectionAttempt> attempts, String outcome) {
    final now = TimezoneService.now();
    int count = 0;
    
    for (final attempt in attempts) {
      if (attempt.outcome == outcome) {
        final completedDate = TimezoneService.toGermanTime(attempt.completedAt ?? attempt.updatedAt);
        final dateOnly = DateTime(completedDate.year, completedDate.month, completedDate.day);
        
        // Check if this date is within the last 7 days
        final daysDiff = now.difference(dateOnly).inDays;
        
        if (daysDiff >= 0 && daysDiff < 7) {
          count++;
        }
      }
    }
    
    return count;
  }


  List<FlSpot> _generateRealData(String outcome) {
    try {
      // Get chart attempts from the collection attempts provider
      final attemptsAsync = ref.read(collectionAttemptsProvider);
      
      return attemptsAsync.when(
        data: (response) {
          if (response.attempts.isEmpty) {
            return _getEmptyDataForTimeRange();
          }
          return _generateDataFromCollectionAttempts(response.attempts, outcome);
        },
        loading: () {
          return _getEmptyDataForTimeRange();
        },
        error: (error, stack) {
          return _getEmptyDataForTimeRange();
        },
      );
    } catch (e) {
      // Return empty data on error
      return _getEmptyDataForTimeRange();
    }
  }

  List<FlSpot> _getEmptyDataForTimeRange() {
    final dataPoints = _getDataPointsForTimeRange();
    return List.generate(dataPoints, (index) => FlSpot(index.toDouble(), 0.0));
  }

  int _getDataPointsForTimeRange() {
    switch (widget.timeRange) {
      case 'week':
        return 7; // 7 days
      case 'month':
        return TimezoneService.now().day; // Days in current month
      case 'year':
        return 12; // 12 months
      case '':
        return 12; // All time - show last 12 months
      default:
        return 7;
    }
  }

  List<FlSpot> _generateDataFromCollectionAttempts(List<CollectionAttempt> attempts, String outcome) {
    final dataPoints = _getDataPointsForTimeRange();
    final Map<String, int> counts = {};
    
    // Initialize counts
    for (int i = 0; i < dataPoints; i++) {
      counts[_getKeyForIndex(i)] = 0;
    }
    
    // Count attempts by outcome and time period
    for (final attempt in attempts) {
      if (attempt.outcome == outcome) {
        final completedDate = TimezoneService.toGermanTime(attempt.completedAt ?? attempt.updatedAt);
        final key = _getKeyForDate(completedDate);
        if (counts.containsKey(key)) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    
    // Generate chart data
    final List<FlSpot> chartData = [];
    for (int i = 0; i < dataPoints; i++) {
      final key = _getKeyForIndex(i);
      final count = counts[key] ?? 0;
      chartData.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    
    return chartData;
  }

  String _getKeyForIndex(int index) {
    final now = TimezoneService.now();
    switch (widget.timeRange) {
      case 'week':
        final date = now.subtract(Duration(days: 6 - index));
        return '${date.year}-${date.month}-${date.day}';
      case 'month':
        return '${now.year}-${now.month}-${index + 1}';
      case 'year':
        return '${now.year}-${index + 1}';
      case '':
        final monthsAgo = 11 - index;
        final date = DateTime(now.year, now.month - monthsAgo, 1);
        return '${date.year}-${date.month}';
      default:
        return index.toString();
    }
  }

  String _getKeyForDate(DateTime date) {
    switch (widget.timeRange) {
      case 'week':
        return '${date.year}-${date.month}-${date.day}';
      case 'month':
        return '${date.year}-${date.month}-${date.day}';
      case 'year':
        return '${date.year}-${date.month}';
      case '':
        return '${date.year}-${date.month}';
      default:
        return date.toString();
    }
  }

  String _getXAxisLabel(int index) {
    final now = TimezoneService.now();
    switch (widget.timeRange) {
      case 'week':
        final date = now.subtract(Duration(days: 6 - index));
        if (date.weekday == now.weekday) {
          return 'Today';
        } else if (date.weekday == (now.weekday == 1 ? 7 : now.weekday - 1)) {
          return 'Yesterday';
        } else {
          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return dayNames[date.weekday - 1];
        }
      case 'month':
        return '${index + 1}';
      case 'year':
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return monthNames[index];
      case '':
        final monthsAgo = 11 - index;
        final date = DateTime(now.year, now.month - monthsAgo, 1);
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return monthNames[date.month - 1];
      default:
        return index.toString();
    }
  }

  String _getTimeRangeText() {
    switch (widget.timeRange) {
      case 'week':
        return 'this week';
      case 'month':
        return 'this month';
      case 'year':
        return 'this year';
      case '':
        return 'all time';
      default:
        return 'this week';
    }
  }

}
