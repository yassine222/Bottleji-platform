import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/providers/user_mode_provider.dart';

class TrainingsScreen extends ConsumerWidget {
  const TrainingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMode = ref.watch(userModeProvider);
    final isHousehold = userMode == UserMode.household;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainings'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // only 4 defined trainings
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getTrainingIcon(index, isHousehold),
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTrainingTitle(index, isHousehold),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTrainingDescription(index, isHousehold),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '30 mins',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              // TODO: Start training
                            },
                            child: const Text('Start Training'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getTrainingIcon(int index, bool isHousehold) {
    if (isHousehold) {
      switch (index) {
        case 0:
          return Icons.recycling;
        case 1:
          return Icons.compost;
        case 2:
          return Icons.eco;
        case 3:
          return Icons.water_drop;
        default:
          return Icons.help_outline;
      }
    } else {
      switch (index) {
        case 0:
          return Icons.route;
        case 1:
          return Icons.local_shipping;
        case 2:
          return Icons.inventory;
        case 3:
          return Icons.safety_check;
        default:
          return Icons.help_outline;
      }
    }
  }

  String _getTrainingTitle(int index, bool isHousehold) {
    if (isHousehold) {
      switch (index) {
        case 0:
          return 'Waste Segregation Basics';
        case 1:
          return 'Home Composting Guide';
        case 2:
          return 'Eco-Friendly Living';
        case 3:
          return 'Water Conservation';
        default:
          return 'Unknown Training';
      }
    } else {
      switch (index) {
        case 0:
          return 'Route Optimization';
        case 1:
          return 'Vehicle Maintenance';
        case 2:
          return 'Waste Management';
        case 3:
          return 'Safety Protocols';
        default:
          return 'Unknown Training';
      }
    }
  }

  String _getTrainingDescription(int index, bool isHousehold) {
    if (isHousehold) {
      switch (index) {
        case 0:
          return 'Learn how to properly segregate different types of waste for efficient recycling.';
        case 1:
          return 'Start your own composting system at home and reduce organic waste.';
        case 2:
          return 'Discover practical tips for reducing your environmental impact.';
        case 3:
          return 'Learn effective methods to conserve water in your daily activities.';
        default:
          return 'No description available.';
      }
    } else {
      switch (index) {
        case 0:
          return 'Learn techniques for optimizing collection routes and saving fuel.';
        case 1:
          return 'Essential maintenance practices for collection vehicles.';
        case 2:
          return 'Advanced waste handling and processing procedures.';
        case 3:
          return 'Important safety guidelines for waste collection operations.';
        default:
          return 'No description available.';
      }
    }
  }
}
