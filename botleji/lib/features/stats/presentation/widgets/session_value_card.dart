import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/l10n/app_localizations.dart';

/// Floating card showing total value collected in current session
class SessionValueCard extends ConsumerStatefulWidget {
  const SessionValueCard({super.key});

  @override
  ConsumerState<SessionValueCard> createState() => _SessionValueCardState();
}

class _SessionValueCardState extends ConsumerState<SessionValueCard> {
  static const String _isMinimizedKey = 'session_value_card_minimized';
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _loadMinimizedState();
  }

  Future<void> _loadMinimizedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isMinimized = prefs.getBool(_isMinimizedKey) ?? false;
      setState(() {
        _isMinimized = isMinimized;
      });
    } catch (e) {
      debugPrint('Error loading minimized state: $e');
    }
  }

  Future<void> _saveMinimizedState(bool minimized) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isMinimizedKey, minimized);
    } catch (e) {
      debugPrint('Error saving minimized state: $e');
    }
  }

  void _toggleMinimized() {
    setState(() {
      _isMinimized = !_isMinimized;
      _saveMinimizedState(_isMinimized);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show in collector mode
    final userMode = ref.watch(userModeControllerProvider);
    final isCollector = userMode.maybeWhen(
      data: (mode) => mode == UserMode.collector,
      orElse: () => false,
    );

    if (!isCollector) {
      return const SizedBox.shrink();
    }

    // Check if there's an active collection (to adjust position)
    final activeCollection = ref.watch(navigationControllerProvider);
    final hasActiveCollection = activeCollection != null;

    // Get earnings from user data (like reward history) - primary source
    final userDataAsync = ref.watch(authNotifierProvider);
    
    return userDataAsync.when(
      data: (userData) {
        // Get today's earnings from user data
        double todayEarnings = 0.0;
        int todayCollectionCount = 0;
        
        print('💰 SessionValueCard - Checking earningsHistory...');
        print('💰 SessionValueCard - userData is null: ${userData == null}');
        print('💰 SessionValueCard - userData ID: ${userData?.id}');
        print('💰 SessionValueCard - userData email: ${userData?.email}');
        print('💰 SessionValueCard - earningsHistory is null: ${userData?.earningsHistory == null}');
        print('💰 SessionValueCard - earningsHistory length: ${userData?.earningsHistory?.length ?? 0}');
        print('💰 SessionValueCard - totalEarnings: ${userData?.totalEarnings}');
        print('💰 SessionValueCard - rewardHistory length: ${userData?.rewardHistory?.length ?? 0}');
        if (userData?.earningsHistory != null) {
          print('💰 SessionValueCard - earningsHistory content: ${userData!.earningsHistory}');
        }
        
        if (userData?.earningsHistory != null && userData!.earningsHistory!.isNotEmpty) {
          print('💰 SessionValueCard - earningsHistory items: ${userData.earningsHistory}');
          
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          print('💰 SessionValueCard - Today date: $today');
          
          // Try to find today's entry
          Map<String, dynamic>? todayEntry;
          
          for (var entry in userData.earningsHistory!) {
            print('💰 SessionValueCard - Checking entry: $entry');
            if (entry['date'] == null) {
              print('💰 SessionValueCard - Entry has no date field');
              continue;
            }
            
            DateTime? entryDate;
            try {
              if (entry['date'] is String) {
                // Parse as UTC first, then convert to local for display
                final parsed = DateTime.parse(entry['date'] as String);
                entryDate = parsed.isUtc ? parsed.toLocal() : parsed;
                print('💰 SessionValueCard - Parsed date from string: $entryDate (UTC: ${parsed.isUtc ? parsed : parsed.toUtc()})');
              } else if (entry['date'] is DateTime) {
                final dt = entry['date'] as DateTime;
                entryDate = dt.isUtc ? dt.toLocal() : dt;
                print('💰 SessionValueCard - Date is already DateTime: $entryDate');
              } else {
                print('💰 SessionValueCard - Date is unknown type: ${entry['date'].runtimeType}');
                continue;
              }
              
              // Normalize both dates to UTC midnight for comparison (matching backend logic)
              final entryDateUTC = entryDate.toUtc();
              final entryDateOnly = DateTime.utc(entryDateUTC.year, entryDateUTC.month, entryDateUTC.day);
              
              final nowUTC = DateTime.now().toUtc();
              final todayOnly = DateTime.utc(nowUTC.year, nowUTC.month, nowUTC.day);
              
              print('💰 SessionValueCard - Entry date (UTC midnight): $entryDateOnly');
              print('💰 SessionValueCard - Today (UTC midnight): $todayOnly');
              
              // Check if this is today's entry (compare UTC dates)
              if (entryDateOnly.year == todayOnly.year && 
                  entryDateOnly.month == todayOnly.month && 
                  entryDateOnly.day == todayOnly.day) {
                todayEntry = entry;
                print('💰 SessionValueCard - ✅ Found today entry!');
                break; // Found today's entry, no need to continue
              }
            } catch (e) {
              print('💰 SessionValueCard - Error parsing date: $e');
              continue;
            }
          }
          
          // Only use today's entry if it exists AND has an active session
          // Don't fall back to most recent entry - only show current active session
          if (todayEntry != null && todayEntry.isNotEmpty) {
            final isActive = todayEntry['isActive'] ?? false;
            
            // Only show earnings if there's an active session today
            if (isActive) {
              print('💰 SessionValueCard - Using today\'s active entry');
              print('💰 SessionValueCard - Entry keys: ${todayEntry.keys}');
              print('💰 SessionValueCard - Entry earnings value: ${todayEntry['earnings']} (type: ${todayEntry['earnings'].runtimeType})');
              print('💰 SessionValueCard - Entry collectionCount value: ${todayEntry['collectionCount']} (type: ${todayEntry['collectionCount'].runtimeType})');
              
              final earningsValue = todayEntry['earnings'];
              if (earningsValue != null) {
                if (earningsValue is double) {
                  todayEarnings = earningsValue;
                } else if (earningsValue is int) {
                  todayEarnings = earningsValue.toDouble();
                } else if (earningsValue is num) {
                  todayEarnings = earningsValue.toDouble();
                } else if (earningsValue is String) {
                  todayEarnings = double.tryParse(earningsValue) ?? 0.0;
                }
              }
              
              final countValue = todayEntry['collectionCount'];
              if (countValue != null) {
                if (countValue is int) {
                  todayCollectionCount = countValue;
                } else if (countValue is num) {
                  todayCollectionCount = countValue.toInt();
                } else if (countValue is String) {
                  todayCollectionCount = int.tryParse(countValue) ?? 0;
                }
              }
              
              print('💰 SessionValueCard - ✅ Final values: ${todayEarnings} TND, ${todayCollectionCount} collections');
            } else {
              print('💰 SessionValueCard - Today\'s entry exists but is not active, showing 0');
            }
          } else {
            print('💰 SessionValueCard - ❌ No entry found for today, showing 0');
          }
        } else {
          print('💰 SessionValueCard - ❌ No earningsHistory in user data or it\'s empty');
        }
        
        return _buildCard(
          context,
          todayEarnings,
          todayCollectionCount,
          hasActiveCollection: hasActiveCollection,
        );
      },
      loading: () {
        return _buildCard(
          context,
          0.0,
          0,
          isLoading: true,
          hasActiveCollection: hasActiveCollection,
        );
      },
      error: (error, stack) {
        print('❌ SessionValueCard - Error loading user data: $error');
        return _buildCard(
          context,
          0.0,
          0,
          hasActiveCollection: hasActiveCollection,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    double todayTotal,
    int todayCount, {
    bool isLoading = false,
    bool hasActiveCollection = false,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    final topPosition = (topPadding + 12).toDouble();

    return Positioned(
      top: topPosition,
      left: 16,
      right: null,
      child: GestureDetector(
        onTap: _toggleMinimized,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            maxWidth: _isMinimized ? 50 : 160,
            minHeight: 80,
            maxHeight: 80,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00695C),
                const Color(0xFF00695C).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: _isMinimized
                ? _buildMinimizedView()
                : _buildExpandedView(context, todayTotal, todayCount, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return Center(
      key: const ValueKey('minimized'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    double todayTotal,
    int todayCount,
    bool isLoading,
  ) {
    return Column(
      key: const ValueKey('expanded'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).todaysTotal,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          DropValueCalculator.formatEstimatedValue(todayTotal),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.inventory_2,
              color: Colors.white.withOpacity(0.8),
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isLoading
                    ? AppLocalizations.of(context).loading
                    : '${AppLocalizations.of(context).today}: $todayCount ${todayCount == 1 ? AppLocalizations.of(context).collection : AppLocalizations.of(context).collections}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
