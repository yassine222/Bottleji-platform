import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/controllers/user_mode_controller.dart';
import '../providers/training_provider.dart';
import '../../data/models/training_content.dart';
import 'video_player_screen.dart';
import 'training_detail_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

class TrainingsScreen extends ConsumerStatefulWidget {
  const TrainingsScreen({super.key});

  @override
  ConsumerState<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends ConsumerState<TrainingsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final userModeAsync = ref.watch(userModeControllerProvider);
    final trainingContentAsync = ref.watch(trainingContentProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).trainingCenter),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              final userMode = ref.read(userModeControllerProvider).valueOrNull;
              final isHousehold = userMode == UserMode.household;
              _showInfoDialog(context, isHousehold);
            },
          ),
        ],
      ),
      body: userModeAsync.when(
        data: (userMode) {
          debugPrint('🔍 Training: Received userMode: $userMode (type: ${userMode.runtimeType})');
          debugPrint('🔍 Training: UserMode.household: ${UserMode.household}');
          debugPrint('🔍 Training: UserMode.collector: ${UserMode.collector}');
          debugPrint('🔍 Training: userMode == UserMode.household: ${userMode == UserMode.household}');
          debugPrint('🔍 Training: userMode == UserMode.collector: ${userMode == UserMode.collector}');
          
          final isHousehold = userMode == UserMode.household;
          final isCollector = userMode == UserMode.collector;
          
          return trainingContentAsync.when(
            data: (allContent) {
              debugPrint('🔍 Filtering ${allContent.length} items with category: $_selectedCategory');
              debugPrint('   Current mode - Household: $isHousehold, Collector: $isCollector');
              
              // Filter content based on CURRENT active mode (not user roles)
              List<TrainingContent> filteredContent = allContent.where((content) {
                // Category filter - convert camelCase enum to snake_case for comparison
                final categoryString = content.category.toString().split('.').last;
                final categorySnakeCase = categoryString
                    .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
                
                // Remove leading underscore if present
                final cleanCategory = categorySnakeCase.startsWith('_') 
                    ? categorySnakeCase.substring(1) 
                    : categorySnakeCase;
                
                bool matchesCategory = _selectedCategory == 'all' || cleanCategory == _selectedCategory;

                // Tag-based mode filter - ONLY check current active mode
                bool matchesMode = false;
                
                // If content has tags, use tag-based filtering
                if (content.tags.isNotEmpty) {
                  if (isHousehold) {
                    // Household mode: see content tagged with 'household'
                    matchesMode = content.tags.contains('household');
                  } else if (isCollector) {
                    // Collector mode: see content tagged with 'collector'
                    matchesMode = content.tags.contains('collector');
                  }
                } else {
                  // Fallback to category-based filtering for content without tags
                  if (isHousehold) {
                    matchesMode = content.isRelevantForHousehold();
                  } else if (isCollector) {
                    matchesMode = content.isRelevantForCollector();
                  }
                }
                
                debugPrint('  Content: ${content.title}, Tags: ${content.tags}, Mode: ${isHousehold ? "household" : "collector"}, Matches: $matchesMode');

                return matchesCategory && matchesMode;
              }).toList();
              
              debugPrint('✅ Filtered to ${filteredContent.length} items');

              return Column(
                children: [
                  // Category Filter
                  _buildCategoryFilter(context, isHousehold, isCollector),
                  
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
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load training content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00695C),
          ),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading user mode: $error'),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, bool isHousehold, bool isCollector) {
    final l10n = AppLocalizations.of(context);
    final categories = [
      {'value': 'all', 'label': l10n.all, 'icon': '📚'},
      {'value': 'getting_started', 'label': l10n.gettingStarted, 'icon': '🚀'},
      {'value': 'best_practices', 'label': l10n.bestPractices, 'icon': '💡'},
      {'value': 'troubleshooting', 'label': l10n.help, 'icon': '🔧'},
      if (isCollector) ...[
        {'value': 'collector_application', 'label': l10n.collector, 'icon': '📋'},
        {'value': 'advanced_features', 'label': l10n.advanced, 'icon': '⚡'},
      ],
      {'value': 'payments', 'label': l10n.payments, 'icon': '💳'},
    ];

    return Container(
      color: Theme.of(context).colorScheme.surface,
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: const Color(0xFF00695C),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF00695C) : Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          
          // NEW Badge for Videos
          if (content.isNew)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎉 NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
        debugPrint('🎬 Video content: ${content.title}');
        debugPrint('   thumbnailUrl: ${content.thumbnailUrl}');
        debugPrint('   Has thumbnail: ${content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty}');
        
        if (content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Image.network(
              content.thumbnailUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                debugPrint('✅ Thumbnail loaded successfully');
                return child;
              }
              debugPrint('⏳ Loading thumbnail... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00695C),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Thumbnail load error: $error');
                return _buildDefaultVideoPlaceholder();
              },
            ),
          );
        }
        debugPrint('⚠️ No thumbnail URL, using placeholder');
        return _buildDefaultVideoPlaceholder();
        
      case TrainingType.image:
        if (content.mediaUrl != null && content.mediaUrl!.isNotEmpty) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Image.network(
              content.mediaUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00695C),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _buildDefaultImagePlaceholder(),
            ),
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

  Widget _buildBadge(BuildContext context, String icon, String label, Color bgColor, Color textColor) {
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Training Content Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new training materials',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleContentTap(BuildContext context, TrainingContent content) {
    // Track view count
    ref.read(trainingApiClientProvider).incrementViewCount(content.id);
    
    switch (content.type) {
      case TrainingType.video:
        if (content.mediaUrl != null && content.mediaUrl!.isNotEmpty) {
          debugPrint('🎥 Opening video player for: ${content.title}');
          debugPrint('   Video URL: ${content.mediaUrl}');
          debugPrint('   Thumbnail URL: ${content.thumbnailUrl}');
          
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
    } else {
          debugPrint('❌ Cannot play video: mediaUrl is null or empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video URL is not available'),
              backgroundColor: Colors.red,
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
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF00695C)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).trainingCenterInfo),
          ],
        ),
        content: Text(
          isHousehold
              ? AppLocalizations.of(context).trainingCenterInfoHousehold
              : AppLocalizations.of(context).trainingCenterInfoCollector,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00695C),
            ),
            child: Text(AppLocalizations.of(context).gotIt),
          ),
        ],
      ),
    );
  }
}
