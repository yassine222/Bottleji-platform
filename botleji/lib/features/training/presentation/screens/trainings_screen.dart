import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_mode_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/training_provider.dart';
import '../../data/models/training_content.dart';
import 'video_player_screen.dart';
import 'training_detail_screen.dart';

class TrainingsScreen extends ConsumerStatefulWidget {
  const TrainingsScreen({super.key});

  @override
  ConsumerState<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends ConsumerState<TrainingsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final userMode = ref.watch(userModeProvider);
    final authState = ref.watch(authStateProvider);
    final isHousehold = userMode == UserMode.household;
    final isCollector = userMode == UserMode.collector;
    
    // Check if user has both roles
    final user = authState.whenData((data) => data).value;
    final hasCollectorRole = user?.roles.contains('collector') ?? false;
    final hasBothModes = hasCollectorRole;

    final trainingContentAsync = ref.watch(trainingContentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Training Center'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context, isHousehold);
            },
          ),
        ],
      ),
      body: trainingContentAsync.when(
        data: (allContent) {
          // Filter content based on user mode
          List<TrainingContent> filteredContent = allContent.where((content) {
            // Category filter
            bool matchesCategory = _selectedCategory == 'all' ||
                content.category.toString().split('.').last == _selectedCategory;

            // Mode filter
            bool matchesMode = false;
            if (hasBothModes) {
              matchesMode = true;
            } else if (isHousehold) {
              matchesMode = content.isRelevantForHousehold();
            } else if (isCollector) {
              matchesMode = content.isRelevantForCollector();
            }

            return matchesCategory && matchesMode;
          }).toList();

          return Column(
            children: [
              // Category Filter
              _buildCategoryFilter(context, isHousehold, isCollector, hasBothModes),
              
              // Content List
              Expanded(
                child: filteredContent.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredContent.length,
                        itemBuilder: (context, index) {
                          final content = filteredContent[index];
                          return _buildContentCard(context, content);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00695C),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load training content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(trainingContentProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, bool isHousehold, bool isCollector, bool hasBothModes) {
    final categories = [
      {'value': 'all', 'label': 'All', 'icon': '📚'},
      {'value': 'getting_started', 'label': 'Getting Started', 'icon': '🚀'},
      {'value': 'best_practices', 'label': 'Best Practices', 'icon': '💡'},
      {'value': 'troubleshooting', 'label': 'Help', 'icon': '🔧'},
      if (isCollector || hasBothModes) ...[
        {'value': 'collector_application', 'label': 'Collector', 'icon': '📋'},
        {'value': 'advanced_features', 'label': 'Advanced', 'icon': '⚡'},
      ],
      {'value': 'payments', 'label': 'Payments', 'icon': '💳'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category['value'];
            
            return FilterChip(
              label: Text(
                '${category['icon']} ${category['label']}',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF00695C),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['value']!;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF00695C),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF00695C) : Colors.grey.shade300,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, TrainingContent content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Section
          _buildMediaSection(context, content),
          
          // Content Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  content.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Badges Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      content.category.icon,
                      content.category.displayName,
                      Colors.grey.shade100,
                      Colors.grey.shade700,
                    ),
                    if (content.duration > 0)
                      _buildBadge(
                        '⏱️',
                        content.formattedDuration,
                        Colors.blue.shade50,
                        Colors.blue.shade700,
                      ),
                    if (content.isFeatured)
                      _buildBadge(
                        '⭐',
                        'Featured',
                        Colors.yellow.shade50,
                        Colors.yellow.shade800,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, TrainingContent content) {
    return GestureDetector(
      onTap: () => _handleContentTap(context, content),
      child: Stack(
        children: [
          // Media Container
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildMediaWidget(content),
            ),
          ),
          
          // Play Button Overlay for Videos
          if (content.type == TrainingType.video)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          
          // Duration Badge for Videos
          if (content.type == TrainingType.video && content.duration > 0)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  content.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget(TrainingContent content) {
    switch (content.type) {
      case TrainingType.video:
        if (content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty) {
          return Image.network(
            content.thumbnailUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00695C),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildDefaultVideoPlaceholder(),
          );
        }
        return _buildDefaultVideoPlaceholder();
        
      case TrainingType.image:
        if (content.mediaUrl != null && content.mediaUrl!.isNotEmpty) {
          return Image.network(
            content.mediaUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00695C),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildDefaultImagePlaceholder(),
          );
        }
        return _buildDefaultImagePlaceholder();
        
      case TrainingType.story:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00695C).withOpacity(0.8),
                const Color(0xFF004D40),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.menu_book,
              size: 80,
              color: Colors.white70,
            ),
          ),
        );
    }
  }

  Widget _buildDefaultVideoPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade900,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 80,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildDefaultImagePlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade900,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 80,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildBadge(String icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Training Content Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new training materials',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleContentTap(BuildContext context, TrainingContent content) {
    switch (content.type) {
      case TrainingType.video:
        if (content.mediaUrl != null && content.mediaUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoUrl: content.mediaUrl!,
                title: content.title,
                thumbnailUrl: content.thumbnailUrl,
              ),
            ),
          );
        }
        break;
        
      case TrainingType.image:
      case TrainingType.story:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingDetailScreen(content: content),
          ),
        );
        break;
    }
  }

  void _showInfoDialog(BuildContext context, bool isHousehold) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF00695C)),
            SizedBox(width: 8),
            Text('Training Center'),
          ],
        ),
        content: Text(
          isHousehold
              ? 'Access training content tailored for household users. Learn how to use Botleji effectively!'
              : 'Access training content for collectors. Master collection techniques and best practices!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00695C),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
