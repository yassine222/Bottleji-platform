import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/training_content.dart';

class TrainingDetailScreen extends StatelessWidget {
  final TrainingContent content;

  const TrainingDetailScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(content.title),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Section
            if (content.type == TrainingType.image && content.mediaUrl != null)
              Hero(
                tag: 'training_${content.id}',
                child: CachedNetworkImage(
                  imageUrl: content.mediaUrl!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00695C),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Content Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Badges
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
                      if (content.isFeatured)
                        _buildBadge(
                          '⭐',
                          'Featured',
                          Colors.yellow.shade50,
                          Colors.yellow.shade800,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Divider
                  Divider(color: Colors.grey.shade200, thickness: 1),
                  const SizedBox(height: 20),
                  
                  // Description Header
                  const Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Color(0xFF00695C),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
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
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  
                  // Story Content
                  if (content.type == TrainingType.story && content.content != null) ...[
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 20,
                          color: Color(0xFF00695C),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Story',
                          style: TextStyle(
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
                        color: Colors.grey.shade800,
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

  Widget _buildBadge(String icon, String label, Color bgColor, Color textColor) {
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

