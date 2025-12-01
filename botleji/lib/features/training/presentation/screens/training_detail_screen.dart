import 'package:flutter/material.dart';
import '../../data/models/training_content.dart';
import 'package:botleji/l10n/app_localizations.dart';

class TrainingDetailScreen extends StatelessWidget {
  final TrainingContent content;

  const TrainingDetailScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Section
            if (content.type == TrainingType.image && content.mediaUrl != null)
              Hero(
                tag: 'training_${content.id}',
                child: Image.network(
                  content.mediaUrl!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00695C),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 300,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Content Section
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    content.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        context,
                        content.category.icon,
                        content.category.localizedDisplayName(context),
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      if (content.isNew)
                        _buildBadge(
                          context,
                          '🎉',
                          'NEW',
                          const Color(0xFF00695C).withOpacity(0.1),
                          const Color(0xFF00695C),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Divider
                  Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), thickness: 1),
                  const SizedBox(height: 20),
                  
                  // Description Header
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Color(0xFF00695C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    content.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.6,
                    ),
                  ),
                  
                  // Story Content
                  if (content.type == TrainingType.story && content.content != null) ...[
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), thickness: 1),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 20,
                          color: Color(0xFF00695C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).story,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content.content!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        height: 1.8,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

