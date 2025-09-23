import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/support_ticket.dart';
import '../providers/support_ticket_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? preFilledData;

  const CreateTicketScreen({super.key, this.preFilledData});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketCategory _selectedCategory = TicketCategory.generalSupport;
  TicketPriority _selectedPriority = TicketPriority.medium;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePreFilledData();
  }

  void _initializePreFilledData() {
    if (widget.preFilledData != null) {
      final data = widget.preFilledData!;

      if (data['itemTitle'] != null) {
        _titleController.text = data['itemTitle'];
      } else if (data['title'] != null) {
        _titleController.text = data['title'];
      }

      if (data['itemDescription'] != null) {
        _descriptionController.text = data['itemDescription'];
      } else if (data['description'] != null) {
        _descriptionController.text = data['description'];
      }

      if (data['category'] != null) {
        _selectedCategory = _getCategoryFromString(data['category']);
      }

      if (data['metadata'] != null && data['metadata']['severity'] != null) {
        _selectedPriority =
            _getPriorityFromSeverity(data['metadata']['severity']);
      }
    }
  }

  TicketCategory _getCategoryFromString(String categoryString) {
    switch (categoryString) {
      case 'authentication':
        return TicketCategory.authentication;
      case 'app_technical':
        return TicketCategory.appTechnical;
      case 'drop_creation':
        return TicketCategory.dropCreation;
      case 'collection_navigation':
        return TicketCategory.collectionNavigation;
      case 'collector_application':
        return TicketCategory.collectorApplication;
      case 'payment_rewards':
        return TicketCategory.paymentRewards;
      case 'statistics_history':
        return TicketCategory.statisticsHistory;
      case 'role_switching':
        return TicketCategory.roleSwitching;
      case 'communication':
        return TicketCategory.communication;
      case 'general_support':
        return TicketCategory.generalSupport;
      default:
        return TicketCategory.generalSupport;
    }
  }

  TicketPriority _getPriorityFromSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return TicketPriority.urgent;
      case 'high':
        return TicketPriority.high;
      case 'medium':
        return TicketPriority.medium;
      case 'low':
        return TicketPriority.low;
      default:
        return TicketPriority.medium;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(supportTicketProvider.notifier).createTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            priority: _selectedPriority,
            contextMetadata: widget.preFilledData?['metadata'],
            relatedDropId: widget.preFilledData?['metadata']?['dropId'],
            relatedCollectionId:
                widget.preFilledData?['metadata']?['collectionId'],
            relatedApplicationId:
                widget.preFilledData?['metadata']?['applicationId'],
            location: widget.preFilledData?['metadata']?['location'],
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Brief description of your issue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<TicketCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: TicketCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<TicketPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority *',
                  border: OutlineInputBorder(),
                ),
                items: TicketPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          _getPriorityIcon(priority),
                          color: _getPriorityColor(priority),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_getPriorityDisplayName(priority)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPriority = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText:
                      'Please provide detailed information about your issue...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Ticket',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(TicketCategory category) {
    switch (category) {
      case TicketCategory.authentication:
        return '🔐 Authentication & Account';
      case TicketCategory.appTechnical:
        return '📱 App Technical Issues';
      case TicketCategory.dropCreation:
        return '🏠 Drop Creation & Management';
      case TicketCategory.collectionNavigation:
        return '🚚 Collection & Navigation';
      case TicketCategory.collectorApplication:
        return '👤 Collector Application';
      case TicketCategory.paymentRewards:
        return '💰 Payment & Rewards';
      case TicketCategory.statisticsHistory:
        return '📊 Statistics & History';
      case TicketCategory.roleSwitching:
        return '🔄 Role Switching';
      case TicketCategory.communication:
        return '📞 Communication';
      case TicketCategory.generalSupport:
        return '🛠️ General Support';
    }
  }

  String _getPriorityDisplayName(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Low Priority';
      case TicketPriority.medium:
        return 'Medium Priority';
      case TicketPriority.high:
        return 'High Priority';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Icons.keyboard_arrow_down;
      case TicketPriority.medium:
        return Icons.remove;
      case TicketPriority.high:
        return Icons.keyboard_arrow_up;
      case TicketPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.green;
      case TicketPriority.medium:
        return Colors.orange;
      case TicketPriority.high:
        return Colors.red;
      case TicketPriority.urgent:
        return Colors.purple;
    }
  }
}
