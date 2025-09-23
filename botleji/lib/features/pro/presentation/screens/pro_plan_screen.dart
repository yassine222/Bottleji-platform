import 'package:botleji/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProPlanScreen extends StatelessWidget {
  const ProPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlanCard(
                context,
                title: '🆓 Free Plan',
                price: '\$0',
                features: const [
                  Feature(
                    icon: '📍',
                    title: 'View Drop-offs',
                    description: 'View limited pins in nearby area',
                  ),
                  Feature(
                    icon: '✅',
                    title: 'Accept Pickup',
                    description: 'Accept drops (limit: 5/day)',
                  ),
                  Feature(
                    icon: '🧾',
                    title: 'Pickup History',
                    description: 'View log of completed pickups',
                  ),
                  Feature(
                    icon: '📊',
                    title: 'Basic Stats',
                    description: 'View number of pickups, total bottles collected',
                  ),
                  Feature(
                    icon: '🔔',
                    title: 'Basic Notifications',
                    description: 'Pickup updates only',
                  ),
                  Feature(
                    icon: '👤',
                    title: 'Profile Management',
                    description: 'Change photo, name, preferences',
                  ),
                ],
                isPro: false,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 24),
              _buildPlanCard(
                context,
                title: '💎 Pro Plan',
                price: '\$9.99/month',
                features: const [
                  Feature(
                    icon: '🗺️',
                    title: 'Smart Route Optimization',
                    description: 'Auto-generate optimal pickup route',
                  ),
                  Feature(
                    icon: '🔄',
                    title: 'Unlimited Pickups',
                    description: 'No daily pickup limit',
                  ),
                  Feature(
                    icon: '📍',
                    title: 'Expanded Radius',
                    description: 'See all pins city-wide',
                  ),
                  Feature(
                    icon: '📊',
                    title: 'Advanced Stats',
                    description: 'CO₂ impact, weight, distance tracking',
                  ),
                  Feature(
                    icon: '📦',
                    title: 'Drop Details',
                    description: 'View bottle quantity and notes',
                  ),
                  Feature(
                    icon: '✅',
                    title: 'Mark Drop as Collected',
                    description: 'Mark each point completed during route',
                  ),
                  Feature(
                    icon: '🧭',
                    title: 'Route Tracking',
                    description: 'Real-time collection path on map',
                  ),
                  Feature(
                    icon: '🚩',
                    title: 'Report Pins',
                    description: 'Flag suspicious locations',
                  ),
                  Feature(
                    icon: '📞',
                    title: 'Support Access',
                    description: 'Priority help & issue reporting',
                  ),
                ],
                isPro: true,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement subscription logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<Feature> features,
    required bool isPro,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPro 
            ? Colors.amber.withOpacity(0.1) 
            : isDarkMode 
                ? AppColors.darkBackground 
                : AppColors.lightBackground,
        border: Border.all(
          color: isPro 
              ? Colors.amber 
              : isDarkMode 
                  ? AppColors.darkPrimary 
                  : AppColors.lightPrimary,
          width: isPro ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPro 
                  ? Colors.amber 
                  : isDarkMode 
                      ? AppColors.darkPrimary 
                      : AppColors.lightPrimary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPro 
                        ? Colors.black87 
                        : isDarkMode 
                            ? AppColors.darkTextPrimary 
                            : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isPro 
                        ? Colors.black87 
                        : isDarkMode 
                            ? AppColors.darkTextPrimary 
                            : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode 
                                  ? AppColors.darkTextPrimary 
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.description,
                            style: TextStyle(
                              color: isDarkMode 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }




class Feature {
  final String icon;
  final String title;
  final String description;

  const Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
} 