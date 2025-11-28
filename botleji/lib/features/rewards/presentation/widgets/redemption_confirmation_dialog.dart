import 'package:flutter/material.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/l10n/app_localizations.dart';

class RedemptionConfirmationDialog extends StatefulWidget {
  final RewardItem item;
  final int userPoints;
  final Function(DeliveryAddress, {String? selectedSize, String? sizeType}) onConfirm;

  const RedemptionConfirmationDialog({
    super.key,
    required this.item,
    required this.userPoints,
    required this.onConfirm,
  });

  @override
  State<RedemptionConfirmationDialog> createState() => _RedemptionConfirmationDialogState();
}

class _RedemptionConfirmationDialogState extends State<RedemptionConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? selectedSize;
  String? selectedSizeType;

  @override
  void initState() {
    super.initState();
    // Auto-select if only one wearable type
    if (widget.item.isFootwear && !widget.item.isJacket && !widget.item.isBottoms) {
      selectedSizeType = 'footwear';
    } else if (widget.item.isJacket && !widget.item.isFootwear && !widget.item.isBottoms) {
      selectedSizeType = 'jacket';
    } else if (widget.item.isBottoms && !widget.item.isFootwear && !widget.item.isJacket) {
      selectedSizeType = 'bottoms';
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = widget.userPoints >= widget.item.pointCost;
    final isInStock = widget.item.stock > 0;
    final canRedeem = canAfford && isInStock && widget.item.isActive;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).confirmOrder,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.item.pointCost} points',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).yourPointsValue(widget.userPoints),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: canAfford ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Delivery Address Form
                    Text(
                      AppLocalizations.of(context).deliveryAddress,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Street Address
                    TextFormField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context).streetAddress} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context).streetAddressRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // City and State Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: '${AppLocalizations.of(context).city} *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context).cityRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: '${AppLocalizations.of(context).state} *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context).stateRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ZIP Code and Country Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _zipCodeController,
                            decoration: InputDecoration(
                              labelText: '${AppLocalizations.of(context).zipCode} *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context).zipCodeRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: InputDecoration(
                              labelText: '${AppLocalizations.of(context).country} *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context).countryRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context).phoneNumber} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context).phoneNumberRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Additional Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).additionalNotes,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),

                    // Size Selection (only for wearable items)
                    if (_isWearableItem()) ...[
                      Text(
                        AppLocalizations.of(context).sizeSelection,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSizeSelection(),
                      const SizedBox(height: 20),
                    ],

                    // Warning if cannot redeem
                    if (!canRedeem) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getErrorMessage(canAfford, isInStock, widget.item.isActive),
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom action buttons
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: canRedeem ? _handleConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: Text(AppLocalizations.of(context).placeOrder),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      // Check if size selection is required but not provided
      if (_isWearableItem() && (selectedSize == null || selectedSizeType == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pleaseSelectSize),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final deliveryAddress = DeliveryAddress(
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        country: _countryController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        additionalNotes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );

      widget.onConfirm(deliveryAddress, selectedSize: selectedSize, sizeType: selectedSizeType);
      Navigator.of(context).pop();
    }
  }

  String _getErrorMessage(bool canAfford, bool isInStock, bool isActive) {
    final l10n = AppLocalizations.of(context);
    if (!isActive) return l10n.thisItemNotAvailableForRedemption;
    if (!isInStock) return l10n.thisItemOutOfStock;
    if (!canAfford) return l10n.youDontHaveEnoughPointsToRedeem;
    return l10n.cannotRedeemThisItem;
  }

  bool _isWearableItem() {
    return widget.item.isFootwear || widget.item.isJacket || widget.item.isBottoms;
  }

  Widget _buildSizeSelection() {
    final wearableTypes = <String>[];
    if (widget.item.isFootwear) wearableTypes.add('footwear');
    if (widget.item.isJacket) wearableTypes.add('jacket');
    if (widget.item.isBottoms) wearableTypes.add('bottoms');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size type selection (if multiple types)
          if (wearableTypes.length > 1) ...[
            Text(
              AppLocalizations.of(context).itemType,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...wearableTypes.map((type) => _buildSizeTypeOption(type)).toList(),
            const SizedBox(height: 16),
          ],

          // Size selection
          if (selectedSizeType != null) ...[
            Text(
              AppLocalizations.of(context).size,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSizeGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildSizeTypeOption(String type) {
    final isSelected = selectedSizeType == type;
    final icon = _getTypeIcon(type);
    final label = _getTypeLabel(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSizeType = type;
            selectedSize = null; // Reset size when type changes
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeGrid() {
    final sizes = _getSizeOptions(selectedSizeType!);
    
    return Container(
      height: 120,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: sizes.length,
        itemBuilder: (context, index) {
          final size = sizes[index];
          final isSelected = selectedSize == size;
          
          return InkWell(
            onTap: () {
              setState(() {
                selectedSize = size;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getSizeOptions(String type) {
    switch (type) {
      case 'footwear':
        return [
          'EU 36', 'EU 37', 'EU 38', 'EU 39', 'EU 40', 'EU 41', 'EU 42', 'EU 43', 'EU 44', 'EU 45'
        ];
      case 'jacket':
      case 'bottoms':
        return ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
      default:
        return [];
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'footwear':
        return Icons.sports_soccer;
      case 'jacket':
        return Icons.checkroom;
      case 'bottoms':
        return Icons.local_laundry_service;
      default:
        return Icons.straighten;
    }
  }

  String _getTypeLabel(String type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case 'footwear':
        return l10n.footwear;
      case 'jacket':
        return l10n.jackets;
      case 'bottoms':
        return l10n.bottoms;
      default:
        return type;
    }
  }
}