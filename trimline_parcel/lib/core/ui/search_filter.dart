import 'package:flutter/material.dart';

/// Search widget with debounce and clear functionality
class SearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;
  final Duration debounceDuration;
  final TextEditingController? controller;
  final bool autofocus;

  const SearchWidget({
    super.key,
    required this.onSearch,
    this.hintText = 'Search...',
    this.debounceDuration = const Duration(milliseconds: 300),
    this.controller,
    this.autofocus = false,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
    });
    widget.onSearch(value);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Filter chip with selection state
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = selectedColor ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable filter chips
class FilterChipsRow extends StatelessWidget {
  final List<String> filters;
  final String? selectedFilter;
  final Function(String?) onFilterChanged;
  final bool showAll;
  final String allLabel;

  const FilterChipsRow({
    super.key,
    required this.filters,
    this.selectedFilter,
    required this.onFilterChanged,
    this.showAll = true,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showAll)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChipWidget(
                label: allLabel,
                isSelected: selectedFilter == null,
                onTap: () => onFilterChanged(null),
              ),
            ),
          ...filters.map((filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChipWidget(
                  label: filter,
                  isSelected: selectedFilter == filter,
                  onTap: () => onFilterChanged(filter),
                ),
              )),
        ],
      ),
    );
  }
}

/// Date range picker button
class DateRangeButton extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final Function(DateTimeRange?) onRangeSelected;
  final String placeholder;

  const DateRangeButton({
    super.key,
    this.selectedRange,
    required this.onRangeSelected,
    this.placeholder = 'Select Date Range',
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedRange != null;

    return GestureDetector(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: selectedRange,
        );
        onRangeSelected(range);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasSelection
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelection
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 20,
              color: hasSelection
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              hasSelection
                  ? '${_formatDate(selectedRange!.start)} - ${_formatDate(selectedRange!.end)}'
                  : placeholder,
              style: TextStyle(
                color: hasSelection
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onRangeSelected(null),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
