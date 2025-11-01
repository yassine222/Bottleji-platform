import 'package:flutter/material.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';

class SizeSelectionDialog extends StatefulWidget {
  final RewardItem item;
  final Function(String size, String sizeType) onSizeSelected;

  const SizeSelectionDialog({
    super.key,
    required this.item,
    required this.onSizeSelected,
  });

  @override
  State<SizeSelectionDialog> createState() => _SizeSelectionDialogState();
}

class _SizeSelectionDialogState extends State<SizeSelectionDialog> {
  String? selectedSize;
  String? selectedSizeType;

  // Size options for different wearable types
  final Map<String, List<String>> sizeOptions = {
    'footwear': [
      'US 6', 'US 6.5', 'US 7', 'US 7.5', 'US 8', 'US 8.5', 'US 9', 'US 9.5',
      'US 10', 'US 10.5', 'US 11', 'US 11.5', 'US 12', 'US 12.5', 'US 13',
      'US 13.5', 'US 14', 'US 15'
    ],
    'jacket': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
    'bottoms': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
  };

  @override
  void initState() {
    super.initState();
    // Auto-select if only one wearable type
    final wearableTypes = <String>[];
    if (widget.item.isFootwear) wearableTypes.add('footwear');
    if (widget.item.isJacket) wearableTypes.add('jacket');
    if (widget.item.isBottoms) wearableTypes.add('bottoms');
    
    if (wearableTypes.length == 1) {
      selectedSizeType = wearableTypes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which wearable types this item has
    final wearableTypes = <String>[];
    if (widget.item.isFootwear) wearableTypes.add('footwear');
    if (widget.item.isJacket) wearableTypes.add('jacket');
    if (widget.item.isBottoms) wearableTypes.add('bottoms');

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.straighten,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Select Size'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  if (widget.item.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        widget.item.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
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
                        Text(
                          '${widget.item.pointCost} points',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Size type selection (if multiple types)
            if (wearableTypes.length > 1) ...[
              Text(
                'Item Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                'Size',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildSizeGrid(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedSize != null ? _handleConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Size'),
        ),
      ],
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
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[50],
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeGrid() {
    final sizes = sizeOptions[selectedSizeType!] ?? [];
    
    return Container(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
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
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    switch (type) {
      case 'footwear':
        return 'Footwear (Shoe Size)';
      case 'jacket':
        return 'Jackets (Clothing Size)';
      case 'bottoms':
        return 'Bottoms (Clothing Size)';
      default:
        return type;
    }
  }

  void _handleConfirm() {
    if (selectedSize != null && selectedSizeType != null) {
      widget.onSizeSelected(selectedSize!, selectedSizeType!);
      Navigator.of(context).pop();
    }
  }
}
