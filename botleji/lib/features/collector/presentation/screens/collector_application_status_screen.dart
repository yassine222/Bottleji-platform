import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/l10n/app_localizations.dart';
import 'package:botleji/core/theme/app_colors.dart';
import 'package:botleji/features/auth/data/models/user_data.dart' as auth_models;
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/collector/controllers/collector_application_controller.dart';
import 'package:botleji/features/collector/data/models/collector_application.dart';
import 'package:botleji/features/collector/presentation/screens/collector_application_screen.dart';

const appGreenColor = Color(0xFF00695C);

class CollectorApplicationStatusScreen extends ConsumerStatefulWidget {
  const CollectorApplicationStatusScreen({super.key});

  @override
  ConsumerState<CollectorApplicationStatusScreen> createState() => _CollectorApplicationStatusScreenState();
}

class _CollectorApplicationStatusScreenState extends ConsumerState<CollectorApplicationStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Load the user's application when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collectorApplicationControllerProvider.notifier).getMyApplication();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationAsync = ref.watch(collectorApplicationControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).applicationStatus,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: applicationAsync.when(
        data: (application) {
          if (application == null) {
            return _buildNoApplicationFound();
          }
          return _buildApplicationDetails(application as CollectorApplication);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: appGreenColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).errorLoadingApplication,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  


  Widget _buildNoApplicationFound() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noApplicationFound,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.youHaventSubmittedApplicationYet,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorApplicationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.applyNow),
            style: FilledButton.styleFrom(
              backgroundColor: appGreenColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationDetails(CollectorApplication application) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(application),
          const SizedBox(height: 24),
          
          // Application Details
          _buildApplicationInfo(application),
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(application),
        ],
      ),
    );
  }

  Widget _buildStatusCard(CollectorApplication application) {
    final l10n = AppLocalizations.of(context);
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (application.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = l10n.pendingReview;
        statusDescription = l10n.yourApplicationIsBeingReviewed;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = l10n.approved;
        statusDescription = l10n.congratulationsApplicationApproved;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = l10n.rejected;
        statusDescription = l10n.applicationNotApprovedCanApplyAgain;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = l10n.unknown;
        statusDescription = l10n.applicationStatusUnknown;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 48,
            color: statusColor,
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationInfo(CollectorApplication application) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.applicationDetails,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: appGreenColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(l10n.applicationId, application.id),
          _buildInfoRow(l10n.idType, application.idCardType ?? l10n.notSpecified),
          if (application.idCardNumber != null)
            _buildInfoRow(l10n.idNumber, application.idCardNumber!),
          if (application.idCardIssuingAuthority != null)
            _buildInfoRow(l10n.issuingAuthority, application.idCardIssuingAuthority!),
          if (application.idCardExpiryDate != null)
            _buildInfoRow(l10n.expiryDateLabel, _formatDate(application.idCardExpiryDate!)),
          if (application.passportIssueDate != null)
            _buildInfoRow(l10n.issueDateLabel, _formatDate(application.passportIssueDate!)),
          if (application.passportExpiryDate != null)
            _buildInfoRow(l10n.expiryDateLabel, _formatDate(application.passportExpiryDate!)),
          _buildInfoRow(l10n.appliedOn, _formatDate(application.appliedAt ?? DateTime.now())),
          if (application.reviewedAt != null)
            _buildInfoRow(l10n.reviewedOn, _formatDate(application.reviewedAt!)),
          if (application.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rejectionReason,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    application.rejectionReason!,
                    style: TextStyle(
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (application.reviewNotes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewNotes,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    application.reviewNotes!,
                    style: TextStyle(
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CollectorApplication application) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (application.status.toLowerCase() == 'rejected') ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CollectorApplicationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: Text(l10n.applyAgain),
              style: FilledButton.styleFrom(
                backgroundColor: appGreenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else if (application.status.toLowerCase() == 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Show a dialog explaining the process
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.applicationInReview),
                    content: Text(l10n.applicationInReviewDialogContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info),
              label: Text(l10n.reviewProcess),
              style: OutlinedButton.styleFrom(
                foregroundColor: appGreenColor,
                side: BorderSide(color: appGreenColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 