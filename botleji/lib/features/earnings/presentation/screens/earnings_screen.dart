import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';
import 'package:botleji/l10n/app_localizations.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).earnings),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh user data to get latest earnings
          ref.invalidate(authNotifierProvider);
        },
        child: userDataAsync.when(
          data: (userData) {
            final earningsHistory = userData?.earningsHistory ?? [];
            
            // Sort by date (newest first)
            final sortedHistory = List<Map<String, dynamic>>.from(earningsHistory);
            sortedHistory.sort((a, b) {
              final dateA = a['date'] != null 
                  ? (a['date'] is String 
                      ? DateTime.parse(a['date']) 
                      : a['date'] is DateTime
                          ? a['date'] as DateTime
                          : DateTime.now())
                  : DateTime(1970);
              final dateB = b['date'] != null
                  ? (b['date'] is String
                      ? DateTime.parse(b['date'])
                      : b['date'] is DateTime
                          ? b['date'] as DateTime
                          : DateTime.now())
                  : DateTime(1970);
              return dateB.compareTo(dateA);
            });
            
            if (sortedHistory.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).noEarningsHistoryYet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).earningsWillAppearHere,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: sortedHistory.length,
              itemBuilder: (context, index) {
                if (index >= sortedHistory.length) {
                  return const SizedBox.shrink();
                }

                final item = sortedHistory[index];
                return _buildEarningsHistoryItem(context, item);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            return Center(
              child: Text(
                AppLocalizations.of(context).errorLoadingEarnings(error.toString()),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEarningsHistoryItem(BuildContext context, Map<String, dynamic> item) {
    final locale = Localizations.localeOf(context);
    // Use locale-aware date formatting but force Western numerals
    final dateFormat = locale.languageCode == 'ar'
        ? DateFormat('dd MMM yyyy', 'en') // Use 'en' locale to force Western numerals: "22 Nov 2025"
        : DateFormat('MMM dd, yyyy', locale.toString()); // English format: "Nov 22, 2025"
    // Use locale-aware time formatting but force Western numerals
    final timeFormat = locale.languageCode == 'ar'
        ? DateFormat('HH:mm', 'en') // Use 'en' locale to force Western numerals: 24-hour format
        : DateFormat('h:mm a', locale.toString()); // English: 12-hour with AM/PM
    
    final earnings = (item['earnings'] ?? 0).toDouble();
    final collectionCount = item['collectionCount'] ?? 0;
    final date = item['date'] != null
        ? (item['date'] is String
            ? DateTime.parse(item['date'])
            : item['date'] as DateTime)
        : DateTime.now();
    final startTime = item['startTime'] != null
        ? (item['startTime'] is String
            ? DateTime.parse(item['startTime'])
            : item['startTime'] as DateTime)
        : date;
    final lastCollectionTime = item['lastCollectionTime'] != null
        ? (item['lastCollectionTime'] is String
            ? DateTime.parse(item['lastCollectionTime'])
            : item['lastCollectionTime'] as DateTime)
        : date;
    final isActive = item['isActive'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF00695C),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$collectionCount ${collectionCount == 1 ? AppLocalizations.of(context).collection : AppLocalizations.of(context).collections}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? AppLocalizations.of(context).active : AppLocalizations.of(context).completed,
                    style: TextStyle(
                      color: isActive ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).totalEarnings,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DropValueCalculator.formatEstimatedValue(earnings),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF00695C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context).sessionTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(startTime)} - ${timeFormat.format(lastCollectionTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

