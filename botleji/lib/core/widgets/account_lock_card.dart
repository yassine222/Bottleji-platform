import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:botleji/l10n/app_localizations.dart';

class AccountLockCard extends StatefulWidget {
  final DateTime lockedUntil;
  final VoidCallback onDismiss;

  const AccountLockCard({
    super.key,
    required this.lockedUntil,
    required this.onDismiss,
  });

  @override
  State<AccountLockCard> createState() => _AccountLockCardState();
}

class _AccountLockCardState extends State<AccountLockCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
      }
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final difference = widget.lockedUntil.difference(now);
    _timeRemaining = difference.isNegative ? Duration.zero : difference;
  }

  String _formatUnlockTime(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') {
      // Arabic date format
      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      final hour = widget.lockedUntil.hour;
      final minute = widget.lockedUntil.minute;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      return '${widget.lockedUntil.day} ${months[widget.lockedUntil.month - 1]} ${widget.lockedUntil.year}، $timeStr';
    } else {
      // English date format
      return DateFormat('MMM d, h:mm a').format(widget.lockedUntil);
    }
  }

  String _getTimeRemaining(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_timeRemaining == Duration.zero) {
      return l10n.lockExpired;
    }

    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    if (hours > 0) {
      return '$hours ${hours > 1 ? l10n.hours : l10n.hour} $minutes ${minutes != 1 ? l10n.minutes : l10n.minute}';
    } else if (minutes > 0) {
      return '$minutes ${minutes != 1 ? l10n.minutes : l10n.minute} $seconds ${seconds != 1 ? l10n.seconds : l10n.second}';
    } else {
      return '$seconds ${seconds != 1 ? l10n.seconds : l10n.second}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 24), // Reduced horizontal margin, added bottom padding
      padding: const EdgeInsets.all(20), // Increased padding
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_clock,
              size: 48,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            AppLocalizations.of(context).accountTemporarilyLocked,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Reason
          Text(
            AppLocalizations.of(context).accountLockedReason,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade800,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Time remaining
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).unlocksIn(_getTimeRemaining(context)),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Unlock time
          Text(
            AppLocalizations.of(context).availableAgainAt(_formatUnlockTime(context)),
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Info message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).accountLockedInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Dismiss button
          TextButton.icon(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close, size: 18),
            label: Text(AppLocalizations.of(context).iUnderstand),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Overlay version for center screen display
class AccountLockOverlay extends StatelessWidget {
  final DateTime lockedUntil;
  final VoidCallback onDismiss;

  const AccountLockOverlay({
    super.key,
    required this.lockedUntil,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 80), // Added bottom padding for nav bar
            child: AccountLockCard(
              lockedUntil: lockedUntil,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );
  }
}

