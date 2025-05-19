// Let's create a filter chip group component to make searching by skill, job type, etc. more intuitive

import 'package:flutter/material.dart';

class FilterChipGroup extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;
  final bool allowMultiple;
  final IconData? icon;

  const FilterChipGroup({
    Key? key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.allowMultiple = true,
    this.icon,
  }) : super(key: key);

  @override
  _FilterChipGroupState createState() => _FilterChipGroupState();
}

class _FilterChipGroupState extends State<FilterChipGroup> {
  late List<String> _selectedOptions;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.from(widget.selectedOptions);
  }

  @override
  void didUpdateWidget(FilterChipGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedOptions != widget.selectedOptions) {
      _selectedOptions = List.from(widget.selectedOptions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with expand/collapse button
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  _selectedOptions.isEmpty
                      ? 'Any'
                      : _selectedOptions.length == 1
                      ? _selectedOptions.first
                      : '${_selectedOptions.length} selected',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),

        // Filter chips
        if (_isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.map((option) {
                final isSelected = _selectedOptions.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (!widget.allowMultiple) {
                        _selectedOptions.clear();
                      }

                      if (selected) {
                        _selectedOptions.add(option);
                      } else {
                        _selectedOptions.remove(option);
                      }

                      widget.onSelectionChanged(_selectedOptions);
                    });
                  },
                  backgroundColor: Colors.blueAccent,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
          ),

        const Divider(),
      ],
    );
  }
}