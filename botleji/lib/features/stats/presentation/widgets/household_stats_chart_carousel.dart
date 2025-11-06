import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:botleji/core/services/timezone_service.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';

class HouseholdStatsChartCarousel extends StatefulWidget {
  final List<Drop> drops;
  final String timeRange;

  const HouseholdStatsChartCarousel({
    super.key,
    required this.drops,
    required this.timeRange,
  });

  @override
  State<HouseholdStatsChartCarousel> createState() => _HouseholdStatsChartCarouselState();
}

class _HouseholdStatsChartCarouselState extends State<HouseholdStatsChartCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<_Co2Bucket> _latestCo2Buckets = const [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drops.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildPageIndicator(),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: [
              _buildRecyclingVolumeChart(),
              _buildDropActivityChart(),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No data for this range yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Create new drops to see your progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = _currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF00695C).withValues(alpha: isActive ? 1.0 : 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildRecyclingVolumeChart() {
    _latestCo2Buckets = _generateCo2Buckets();
    final totalCo2 = _latestCo2Buckets.fold<double>(0, (sum, bucket) => sum + bucket.totalCo2);

    final barGroups = _generateCo2BarGroups();
    final maxY = barGroups.isEmpty
        ? 5.0
        : barGroups
            .map((group) => group.barRods.fold<double>(0, (maxValue, rod) => rod.toY > maxValue ? rod.toY : maxValue))
            .reduce((a, b) => a > b ? a : b)
            .ceil()
            .toDouble();

    return _buildChartCard(
      title: 'CO₂ Volume Saved',
      secondaryText: 'Total CO₂ Saved: ${totalCo2.toStringAsFixed(1)} kg',
      primaryColor: const Color(0xFF2E7D32),
      icon: Icons.recycling,
      chart: _buildBarChart(
        color: const Color(0xFF2E7D32),
        groups: barGroups,
        maxY: maxY == 0 ? 5 : (maxY * 1.2).ceil().toDouble(),
        touchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dataIndex = group.x.toInt();
              if (dataIndex < 0 || dataIndex >= _latestCo2Buckets.length) {
                return null;
              }
              final bucket = _latestCo2Buckets[dataIndex];
              return BarTooltipItem(
                'Plastic CO₂: ${bucket.plasticCo2.toStringAsFixed(2)} kg\n'
                'Cans CO₂: ${bucket.canCo2.toStringAsFixed(2)} kg\n'
                'Total CO₂: ${bucket.totalCo2.toStringAsFixed(2)} kg',
                const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDropActivityChart() {
    final totalDrops = _calculateTotalDropsCreated();
    final data = _generateDropActivityData();

    return _buildChartCard(
      title: 'Drop Activity',
      secondaryText: 'Drops Created (${_getTimeRangeText()}): $totalDrops',
      primaryColor: const Color(0xFF1E88E5),
      icon: Icons.assignment_outlined,
      chart: _buildAreaChart(
        color: const Color(0xFF1E88E5),
        data: data,
        touchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String secondaryText,
    required Color primaryColor,
    required IconData icon,
    required Widget chart,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
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
                      secondaryText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildAreaChart({
    required Color color,
    required List<FlSpot> data,
    LineTouchData? touchData,
  }) {
    final maxY = data.isEmpty
        ? 5.0
        : data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b).ceil().toDouble();
    final minX = data.isEmpty ? null : data.first.x - 0.4;
    final maxX = data.isEmpty ? null : data.last.x + 0.4;

    return LineChart(
      LineChartData(
        lineTouchData: touchData ?? LineTouchData(enabled: true),
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
              color: color.withValues(alpha: 0.25),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if ((value - value.roundToDouble()).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                final index = value.round();
                final dataPoints = _getDataPointsForTimeRange();
                if (index < 0 || index >= dataPoints) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _getXAxisLabel(index),
                  style: const TextStyle(fontSize: 9),
                );
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
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart({
    required Color color,
    required List<BarChartGroupData> groups,
    double? maxY,
    BarTouchData? touchData,
  }) {
    final effectiveMaxY = (maxY == null || maxY == 0) ? 5.0 : maxY;

    return BarChart(
      BarChartData(
        barTouchData: touchData ?? BarTouchData(enabled: true),
        alignment: BarChartAlignment.spaceAround,
        maxY: effectiveMaxY,
        minY: 0,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if ((value - value.roundToDouble()).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                final index = value.round();
                if (index < 0 || index >= groups.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _getXAxisLabel(index),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  List<_Co2Bucket> _generateCo2Buckets() {
    final dataPoints = _getDataPointsForTimeRange();
    if (dataPoints == 0) {
      return const [];
    }

    final keys = List.generate(dataPoints, (index) => _getKeyForIndex(index));
    final Map<String, _Co2Bucket> buckets = {
      for (final key in keys) key: const _Co2Bucket(),
    };

    for (final drop in widget.drops) {
      if (drop.status != DropStatus.collected) continue;
      final metricDate = _getCollectionMetricDate(drop);
      if (!_isWithinRange(metricDate)) continue;

      final key = _getKeyForDate(metricDate);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]!.add(
          plastic: drop.numberOfBottles,
          cans: drop.numberOfCans,
        );
      }
    }

    return keys.map((key) => buckets[key] ?? const _Co2Bucket()).toList();
  }

  int _calculateTotalDropsCreated() {
    return widget.drops.where((drop) => _isWithinRange(drop.createdAt)).length;
  }

  List<FlSpot> _generateDropActivityData() {
    return _generateDataFromDrops(
      valueSelector: (drop) => 1.0,
      dropFilter: (drop) => true,
    );
  }

  List<BarChartGroupData> _generateCo2BarGroups() {
    if (_latestCo2Buckets.isEmpty) {
      return [];
    }

    return List.generate(_latestCo2Buckets.length, (index) {
      final bucket = _latestCo2Buckets[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: bucket.totalCo2,
            width: 18,
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  List<FlSpot> _generateDataFromDrops({
    required double Function(Drop drop) valueSelector,
    required bool Function(Drop drop) dropFilter,
  }) {
    final dataPoints = _getDataPointsForTimeRange();
    final Map<String, double> buckets = {};

    for (int i = 0; i < dataPoints; i++) {
      buckets[_getKeyForIndex(i)] = 0;
    }

    for (final drop in widget.drops) {
      if (!dropFilter(drop)) continue;
      if (!_isWithinRange(drop.createdAt)) continue;

      final key = _getKeyForDate(drop.createdAt);
      if (buckets.containsKey(key)) {
        buckets[key] = (buckets[key] ?? 0) + valueSelector(drop);
      }
    }

    return List.generate(dataPoints, (index) {
      final key = _getKeyForIndex(index);
      final value = buckets[key] ?? 0;
      return FlSpot(index.toDouble(), value.toDouble());
    });
  }

  bool _isWithinRange(DateTime date) {
    final now = TimezoneService.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    switch (widget.timeRange) {
      case 'week':
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        return !normalizedDate.isBefore(start) && !normalizedDate.isAfter(now);
      case 'month':
        return normalizedDate.year == now.year && normalizedDate.month == now.month;
      case 'year':
        return normalizedDate.year == now.year;
      case '':
        final monthsApart = (now.year - normalizedDate.year) * 12 + (now.month - normalizedDate.month);
        return monthsApart >= 0 && monthsApart < 12;
      default:
        return true;
    }
  }

  int _getDataPointsForTimeRange() {
    switch (widget.timeRange) {
      case 'week':
        return 7;
      case 'month':
        return TimezoneService.now().day;
      case 'year':
        return 12;
      case '':
        return 12;
      default:
        return 7;
    }
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
    final normalizedDate = DateTime(date.year, date.month, date.day);
    switch (widget.timeRange) {
      case 'week':
      case 'month':
        return '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';
      case 'year':
        return '${normalizedDate.year}-${normalizedDate.month}';
      case '':
        return '${normalizedDate.year}-${normalizedDate.month}';
      default:
        return normalizedDate.toIso8601String();
    }
  }

  String _getXAxisLabel(int index) {
    final now = TimezoneService.now();
    switch (widget.timeRange) {
      case 'week':
        final date = now.subtract(Duration(days: 6 - index));
        final today = DateTime(now.year, now.month, now.day);
        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          return 'Today';
        }
        final yesterday = today.subtract(const Duration(days: 1));
        if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
          return 'Yesterday';
        }
        const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return dayNames[date.weekday - 1];
      case 'month':
        return '${index + 1}';
      case 'year':
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return monthNames[index];
      case '':
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthsAgo = 11 - index;
        final date = DateTime(now.year, now.month - monthsAgo, 1);
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
        return 'across the past year';
      default:
        return 'this week';
    }
  }

  DateTime _getCollectionMetricDate(Drop drop) {
    if (drop.status == DropStatus.collected) {
      final collectedAt = drop.collectedAt;
      if (collectedAt != null) {
        return collectedAt;
      }
      return drop.modifiedAt;
    }
    return drop.createdAt;
  }
}

class _Co2Bucket {
  final int plasticCount;
  final int canCount;

  const _Co2Bucket({
    this.plasticCount = 0,
    this.canCount = 0,
  });

  double get plasticCo2 => plasticCount * 0.15;
  double get canCo2 => canCount * 0.17;
  double get totalCo2 => plasticCo2 + canCo2;

  _Co2Bucket add({required int plastic, required int cans}) {
    return _Co2Bucket(
      plasticCount: plasticCount + plastic,
      canCount: canCount + cans,
    );
  }
}

