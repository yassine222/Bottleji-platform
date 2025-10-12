import 'package:flutter/material.dart';

class WelcomeBackCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const WelcomeBackCard({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
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
              color: Colors.green.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: 40,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          // Title
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Message
          Text(
            'Your account has been unlocked. You can now start collecting drops again!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade800,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Success indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Reminder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remember to complete collections within the time limit to avoid future warnings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Dismiss button
          ElevatedButton(
            onPressed: onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start Collecting'),
          ),
        ],
      ),
    );
  }
}

// Overlay version for center screen display
class WelcomeBackOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const WelcomeBackOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: WelcomeBackCard(onDismiss: onDismiss),
          ),
        ),
      ),
    );
  }
}

