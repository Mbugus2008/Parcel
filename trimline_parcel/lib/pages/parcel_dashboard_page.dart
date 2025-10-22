// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../utilities/status_color.dart';
import '../widgets/payment_dialog.dart';
import 'addeditparcel.dart';

class ParcelDashboardPage extends StatefulWidget {
  const ParcelDashboardPage({super.key});

  @override
  State<ParcelDashboardPage> createState() => _ParcelDashboardPageState();
}

class _ParcelDashboardPageState extends State<ParcelDashboardPage> {
  final ParcelController _controller = Get.find<ParcelController>();

  late final TextEditingController _searchController;

  ParcelStatus? _selectedStatus;

  int _currentStep = 0;

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(text: _controller.searchQuery);

    _selectedStatus = _controller.statusFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _controller.searchQuery.isNotEmpty || _controller.statusFilter != null;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        leading: Builder(
          builder: (scaffoldContext) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.black),
              tooltip: 'Menu',
              onPressed: () {
                final scaffold = Scaffold.maybeOf(scaffoldContext);
                if (scaffold == null) {
                  return;
                }

                if (scaffold.hasDrawer) {
                  scaffold.openDrawer();
                } else if (scaffold.hasEndDrawer) {
                  scaffold.openEndDrawer();
                }
              },
            );
          },
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: _isSearching
              ? Row(
                  // ensure search field fills the app bar area
                  children: [
                    Expanded(
                      child: _buildSearchField(
                        context,
                        autofocus: true,
                        onSubmitted: () => setState(() => _isSearching = false),
                        fieldKey: const ValueKey('search-field'),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('title'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Parcel Dashboard',
                          style: TextStyle(color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final device = _controller.activePrinter;
                          if (device == null) {
                            return const Icon(
                              Icons.print_disabled,
                              color: Colors.redAccent,
                              size: 20,
                            );
                          } else {
                            return const Icon(
                              Icons.print_rounded,
                              color: Colors.green,
                              size: 20,
                            );
                          }
                        }),
                      ],
                    ),
                    if (hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Filtered',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              tooltip: 'Close search',
              onPressed: () {
                setState(() => _isSearching = false);

                FocusScope.of(context).unfocus();
              },
              icon: const Icon(Icons.close_rounded, color: Colors.black),
            )
          else
            IconButton(
              tooltip: 'Search parcels',
              onPressed: () {
                // populate the field with any existing query and show search
                _searchController.text = _controller.searchQuery;
                setState(() => _isSearching = true);
              },
              icon: const Icon(Icons.search, color: Colors.black),
            ),

          // hide the rest of the actions while searching
          if (!_isSearching) ...[
            IconButton(
              tooltip: 'Filter by status',

              // TODO: Add dropdown instead of buttomsheet
              onPressed: _openFilterSheet,

              icon: Icon(
                Icons.filter_list_rounded,
                color: hasActiveFilters ? Colors.amber : Colors.black,
              ),
            ),
            if (hasActiveFilters)
              IconButton(
                tooltip: 'Clear filters',
                onPressed: _onClearFilters,
                icon: const Icon(Icons.clear_all_rounded, color: Colors.black),
              ),
            IconButton(
              onPressed: () => Get.to(() => const AddEditParcelPage()),
              icon: const Icon(Icons.add_rounded),
              color: Colors.black,
              tooltip: 'Add parcel',
            ),
          ],
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Obx(() {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.parcels.isEmpty) {
              return const Center(
                child: Text(
                  'No parcels available yet',
                  style: TextStyle(color: Colors.black87),
                ),
              );
            }

            final hasFilters = _controller.searchQuery.isNotEmpty ||
                _controller.statusFilter != null;

            final visibleParcels =
                hasFilters ? _controller.filteredParcels : _controller.parcels;

            final groups = _groupParcelsByStatus(visibleParcels);

            final firstNonEmptyIndex = _firstNonEmptyStep(groups);

            final statuses = _controller.supportedStatuses;

            final currentIndex = statuses.isEmpty
                ? 0
                : _currentStep.clamp(0, statuses.length - 1);

            final currentParcels = statuses.isEmpty
                ? const <Parcel>[]
                : groups[statuses[currentIndex]] ?? <Parcel>[];

            if (currentParcels.isEmpty &&
                firstNonEmptyIndex != null &&
                firstNonEmptyIndex != currentIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _currentStep = firstNonEmptyIndex);
                }
              });
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              children: [
                if (hasFilters && visibleParcels.isEmpty)
                  _buildNoResultsBanner(context),
                _buildStatusStepper(context, groups),
                const SizedBox(height: 2),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final statuses = _controller.supportedStatuses;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1F2A44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter by status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFilterOption(
                sheetContext,
                label: 'All statuses',
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white70,
                ),
                selected: _selectedStatus == null,
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  _onStatusFilterChanged(null);
                },
              ),
              const Divider(color: Colors.white24, height: 24),
              for (final status in statuses)
                _buildFilterOption(
                  sheetContext,
                  label: _controller.statusLabel(status),
                  icon: Icon(
                    _statusIcon(status),
                    color: getStatusColor(status),
                  ),
                  selected: _selectedStatus == status,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    _onStatusFilterChanged(status);
                  },
                ),
              if (_selectedStatus != null || _controller.searchQuery.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();

                      _onClearFilters();
                    },
                    child: const Text('Clear filters'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPrinterSheet() async {
    _controller.refreshPrinters();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1F2A44),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Obx(() {
            final printers = _controller.availablePrintersRx.toList();
            final isScanning = _controller.isScanningPrinters;
            final active = _controller.activePrinter;
            final pendingCount = _controller.pendingParcels.length;
            final isPrinting = _controller.isPrinting;
            final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bluetooth printer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pendingCount == 0
                        ? 'There are no pending parcels to print right now.'
                        : 'Select a printer to send ${pendingCount == 1 ? '1 pending parcel.' : '$pendingCount pending parcels.'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (active != null)
                    _buildActivePrinterBanner(theme: theme, device: active),
                  if (active != null) const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Available printers',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: isScanning
                            ? null
                            : () => _controller.refreshPrinters(),
                        icon: isScanning
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                        label: Text(
                          isScanning ? 'Scanning...' : 'Rescan',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (printers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isScanning
                                ? Icons.bluetooth_searching_rounded
                                : Icons.bluetooth_disabled_rounded,
                            color: Colors.white54,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isScanning
                                ? 'Scanning for printers...'
                                : 'No printers found nearby',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: printers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final device = printers[index];
                          final isActive = active?.address == device.address;
                          return _buildPrinterTile(
                            theme: theme,
                            device: device,
                            isActive: isActive,
                            onTap: () => _controller.selectPrinter(device),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isPrinting ||
                              active == null ||
                              pendingCount == 0
                          ? null
                          : () => _controller.printPendingParcelsViaBluetooth(),
                      icon: isPrinting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.print_rounded),
                      label: Text(
                        isPrinting
                            ? 'Printing...'
                            : pendingCount == 0
                                ? 'No pending parcels'
                                : 'Print pending parcels ($pendingCount)',
                      ),
                    ),
                  ),
                  if (active != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isPrinting
                              ? null
                              : () => _controller.disconnectPrinter(),
                          child: const Text('Disconnect printer'),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildActivePrinterBanner({
    required ThemeData theme,
    required PrinterDevice device,
  }) {
    final displayName = (device.name.trim().isNotEmpty)
        ? device.name.trim()
        : 'Connected printer';
    final address = device.address ?? 'Unknown address';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.lightGreenAccent.withValues(alpha: 0.4)),
        color: Colors.lightGreenAccent.withValues(alpha: 0.12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.lightGreenAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Text(
                  address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterTile({
    required ThemeData theme,
    required PrinterDevice device,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final displayName = (device.name.trim().isNotEmpty)
        ? device.name.trim()
        : 'Unnamed printer';
    final address = device.address ?? 'No address';

    return Card(
      color: Colors.white.withValues(alpha: isActive ? 0.16 : 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? Colors.lightGreenAccent.withValues(alpha: 0.6)
              : Colors.white12,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.print_rounded,
          color: isActive ? Colors.lightGreenAccent : Colors.white54,
        ),
        title: Text(
          displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          address,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        trailing: Icon(
          isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isActive ? Colors.lightGreenAccent : Colors.white30,
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String label,
    required Widget icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: icon,
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: Colors.white70)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSearchField(
    BuildContext context, {
    VoidCallback? onSubmitted,
    bool autofocus = false,
    Key? fieldKey,
  }) {
    final theme = Theme.of(context);

    return TextField(
      key: fieldKey,
      controller: _searchController,
      autofocus: autofocus,
      onChanged: _onSearchChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: 'Search parcels...',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                color: Colors.white54,
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty && _controller.searchQuery.isEmpty) {
      return;
    }

    _searchController.clear();

    _onSearchChanged('');
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentStep = 0;
    });

    _controller.setSearchQuery(value);
  }

  void _onStatusFilterChanged(ParcelStatus? status) {
    final statuses = _controller.supportedStatuses;

    final targetIndex = status == null ? 0 : statuses.indexOf(status);

    setState(() {
      _selectedStatus = status;

      _currentStep = targetIndex >= 0 ? targetIndex : 0;
    });

    _controller.setStatusFilter(status);
  }

  void _onClearFilters() {
    if (_searchController.text.isEmpty && _selectedStatus == null) {
      return;
    }

    _searchController.clear();

    setState(() {
      _selectedStatus = null;

      _currentStep = 0;
    });

    _controller.setSearchQuery('');

    _controller.setStatusFilter(null);
  }

  int? _firstNonEmptyStep(Map<ParcelStatus, List<Parcel>> groups) {
    final statuses = _controller.supportedStatuses;

    for (var index = 0; index < statuses.length; index++) {
      if (groups[statuses[index]]?.isNotEmpty ?? false) {
        return index;
      }
    }

    return null;
  }

  Map<ParcelStatus, List<Parcel>> _groupParcelsByStatus(List<Parcel> parcels) {
    final groups = <ParcelStatus, List<Parcel>>{
      for (final status in _controller.supportedStatuses) status: <Parcel>[],
    };

    for (final parcel in parcels) {
      final status = parcel.Status ?? ParcelStatus.pending;

      groups.putIfAbsent(status, () => <Parcel>[]).add(parcel);
    }

    return groups;
  }

  Widget _buildNoResultsBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No parcels match your current filters.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: _onClearFilters,
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(
    BuildContext context,
    Map<ParcelStatus, List<Parcel>> groups,
  ) {
    final statuses = _controller.supportedStatuses;

    final theme = Theme.of(context);

    final currentStep =
        statuses.isEmpty ? 0 : _currentStep.clamp(0, statuses.length - 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF0F0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: theme.copyWith(
              canvasColor: Colors.transparent,
              colorScheme: theme.colorScheme.copyWith(
                primary: Colors.white,
                onPrimary: Colors.black,
                onSurface: Colors.white70,
              ),
              dividerColor: Colors.white24,
            ),
            child: Builder(
              builder: (context) {
                return Stepper(
                  stepIconBuilder: (stepIndex, stepState) {
                    final status = statuses[stepIndex];

                    final color = getStatusColor(status);

                    final isActive = stepIndex == currentStep;

                    final isComplete = stepState == StepState.complete;

                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: isActive || isComplete ? 0.28 : 0.14,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: isActive ? 0.9 : 0.6),
                          width: 1.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(_statusIcon(status), size: 18, color: color),
                    );
                  },
                  type: StepperType.vertical,
                  currentStep: currentStep,
                  physics: const NeverScrollableScrollPhysics(),
                  controlsBuilder: (context, _) => const SizedBox.shrink(),
                  onStepTapped: (index) => setState(() => _currentStep = index),
                  onStepContinue: currentStep >= statuses.length - 1
                      ? null
                      : () => setState(() => _currentStep = currentStep + 1),
                  onStepCancel: currentStep <= 0
                      ? null
                      : () => setState(() => _currentStep = currentStep - 1),
                  steps: [
                    for (var index = 0; index < statuses.length; index++)
                      _buildStatusStep(
                        context: context,
                        status: statuses[index],
                        parcels: groups[statuses[index]] ?? <Parcel>[],
                        index: index,
                        currentStep: currentStep,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStatusStep({
    required BuildContext context,
    required ParcelStatus status,
    required List<Parcel> parcels,
    required int index,
    required int currentStep,
  }) {
    final theme = Theme.of(context);

    final statusColor = getStatusColor(status);

    final hasParcels = parcels.isNotEmpty;

    final bool isBeforeCurrent = index < currentStep;

    final bool isCurrent = index == currentStep;

    final StepState stepState;

    if (isBeforeCurrent) {
      stepState = StepState.complete;
    } else if (!hasParcels) {
      stepState = StepState.disabled;
    } else if (isCurrent) {
      stepState = StepState.editing;
    } else {
      stepState = StepState.indexed;
    }

    final bool isActive = isBeforeCurrent || isCurrent || hasParcels;

    return Step(
      state: stepState,

      isActive: isActive,

      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _controller.statusLabel(status),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasParcels ? '${parcels.length} ' : '0',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),

      // subtitle: Padding(

      //   padding: const EdgeInsets.only(top: 4),

      //   child: Text(

      //     _statusDescription(status),

      //     style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),

      //   ),

      // ),
      content: _buildStepContent(context, parcels, status, statusColor),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    List<Parcel> parcels,
    ParcelStatus status,
    Color statusColor,
  ) {
    final theme = Theme.of(context);

    if (parcels.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No parcels here.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
        ),
      );
    }

    final parcelRows = parcels
        .map(
          (parcel) => _buildStepParcelRow(
            context: context,
            parcel: parcel,
            statusColor: statusColor,
          ),
        )
        .toList();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top) *
            0.5,
      ),
      child: Scrollbar(
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: parcelRows,
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.black,
      letterSpacing: 0.2,
    );

    final cleanedLabel = label.trim();

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        // 💙 blueish border
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.6),
          width: 1.5,
        ),
        // soft shadow for “floating” effect
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accentColor.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(cleanedLabel, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildContactChip({
    required ThemeData theme,
    required String? label,
    required String? detail,
    required IconData icon,
    required Color chipColor,
  }) {
    final nameText = label?.trim();

    final detailText = detail?.trim();

    final primaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.black,
      letterSpacing: 0.2,
    );

    final secondaryStyle =
        primaryStyle?.copyWith(color: Colors.black54, fontSize: 16);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        // 💙 blueish border
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.6),
          width: 1.5,
        ),
        // soft shadow for “floating” effect
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor.withValues(alpha: 0.85), size: 16),
          const SizedBox(width: 8),
          if (nameText != null && nameText.isNotEmpty)
            Text(nameText, style: primaryStyle),
          if (nameText != null &&
              nameText.isNotEmpty &&
              detailText != null &&
              detailText.isNotEmpty)
            Spacer(),
          if (detailText != null && detailText.isNotEmpty)
            Text(detailText, style: secondaryStyle),
        ],
      ),
    );
  }

  Widget _buildStepParcelRow({
    required BuildContext context,
    required Parcel parcel,
    required Color statusColor,
  }) {
    final theme = Theme.of(context);

    String? route = '';
    switch (parcel.Status) {
      case ParcelStatus.pending:
        route = parcel.To ?? '';
        break;

      default:
        route = parcel.From ?? '';
        break;
    }
    ;
    final sentDate = parcel.Date_sent != null
        ? DateFormat('dd MMM').format(parcel.Date_sent!)
        : 'No date';

    final vehicle = parcel.Vehicle?.trim();

    final driver = parcel.Driver?.trim();

    final weight = parcel.Weight?.trim();

    final senderName = parcel.Sender_Name?.trim();

    final senderPhone = parcel.Sender_Phone?.trim();

    final receiverName = parcel.Receiver_Name?.trim();

    final receiverPhone = parcel.Receiver_Phone?.trim();

    final contactChips = <Widget>[];

    if ((senderName != null && senderName.isNotEmpty) ||
        (senderPhone != null && senderPhone.isNotEmpty)) {
      contactChips.add(
        _buildContactChip(
          theme: theme,
          label: senderName,
          detail: senderPhone,
          icon: Icons.send_rounded,
          chipColor: statusColor,
        ),
      );
    }

    if ((receiverName != null && receiverName.isNotEmpty) ||
        (receiverPhone != null && receiverPhone.isNotEmpty)) {
      contactChips.add(
        _buildContactChip(
          theme: theme,
          label: receiverName,
          detail: receiverPhone,
          icon: Icons.inbox_rounded,
          chipColor: statusColor,
        ),
      );
    }

    final infoPills = <Widget>[];

    if (vehicle != null && vehicle.isNotEmpty) {
      infoPills.add(
        _buildInfoPill(
          theme: theme,
          icon: Icons.local_shipping_rounded,
          label: vehicle,
          accentColor: statusColor,
        ),
      );
    }

    if (driver != null && driver.isNotEmpty) {
      infoPills.add(
        _buildInfoPill(
          theme: theme,
          icon: Icons.badge_rounded,
          label: driver,
          accentColor: statusColor,
        ),
      );
    }

    if (weight != null && weight.isNotEmpty) {
      infoPills.add(
        _buildInfoPill(
          theme: theme,
          icon: Icons.scale_rounded,
          label: weight,
          accentColor: statusColor,
        ),
      );
    }

    final cardRadius = BorderRadius.circular(5);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: cardRadius,
          onTap: () => Get.to(() => AddEditParcelPage(parcel: parcel)),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              // 💙 blueish border
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.6),
                width: 1.5,
              ),
              // soft shadow for “floating” effect
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.Document_No ?? 'Unknown reference',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.alt_route_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          route,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sentDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (contactChips.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 2, runSpacing: 2, children: contactChips),
                  ],
                  if (infoPills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 2, runSpacing: 2, children: infoPills),
                  ],
                  if (parcel.Status == ParcelStatus.pending) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _showDispatchDialog(context, parcel),
                        child: const Text('Dispatch'),
                      ),
                    ),
                  ],
                  if (parcel.Status == ParcelStatus.inTransit) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _controller.updateParcelStatus(
                          parcel,
                          ParcelStatus.received,
                        ),
                        child: const Text('Receive'),
                      ),
                    ),
                  ],
                  if (parcel.Status == ParcelStatus.pending ||
                      parcel.Status == ParcelStatus.received) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => showPaymentDialog(context, parcel),
                        child: const Text('Pay'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDispatchDialog(BuildContext context, Parcel parcel) async {
    final driverController = TextEditingController(text: parcel.Driver ?? '');
    final vehicleController = TextEditingController(text: parcel.Vehicle ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Prepare Dispatch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: vehicleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      hintText: 'Enter vehicle registration',
                      labelStyle: TextStyle(color: Colors.white),
                      floatingLabelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0x14FFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0x2EFFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0x66FFFFFF)),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: driverController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Driver name',
                            hintText: 'Enter driver responsible',
                            labelStyle: TextStyle(color: Colors.white),
                            floatingLabelStyle: TextStyle(color: Colors.white),
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0x14FFFFFF),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0x33FFFFFF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0x2EFFFFFF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0x66FFFFFF)),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final driver = driverController.text.trim();
                          final vehicle = vehicleController.text.trim();
                          if (driver.isEmpty || vehicle.isEmpty) {
                            Get.snackbar(
                              'Validation Error',
                              'Please enter both driver name and vehicle.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.9,
                              ),
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          _controller.dispatchParcelWithDetails(
                            parcel,
                            driver: driver,
                            vehicle: vehicle,
                          );
                        },
                        child: const Text('Dispatch'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Dispose local controllers created for the dialog
    try {
      driverController.dispose();
      vehicleController.dispose();
    } catch (_) {}
  }

  Drawer _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(color: Color(0xFF233556)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Trimline Parcel",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage shipments at a glance",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text("Dashboard"),
              selected: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_rounded),
              title: const Text("Log New Parcel"),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const AddEditParcelPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list_rounded),
              title: const Text("Filter parcels"),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(_openFilterSheet);
              },
            ),
            Obx(() {
              final device = _controller.activePrinter;
              final subtitleText = () {
                if (device == null) {
                  return 'No printer selected';
                }
                final name = device.name.trim();
                if (name.isNotEmpty) {
                  return name;
                }
                final address = device.address?.trim() ?? '';
                return address.isNotEmpty ? address : 'No printer selected';
              }();
              return ListTile(
                leading: const Icon(Icons.print_rounded),
                title: const Text('Printer settings'),
                subtitle: Text(subtitleText, style: theme.textTheme.bodySmall),
                onTap: () {
                  Navigator.of(context).pop();
                  Future.microtask(_openPrinterSheet);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text("Support"),
              subtitle: const Text("Contact logistics for help"),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return Icons.pending_actions_rounded;

      case ParcelStatus.inTransit:
        return Icons.local_shipping_rounded;

      case ParcelStatus.received:
        return Icons.home_work_rounded;

      case ParcelStatus.collected:
        return Icons.verified_rounded;
    }
  }
}
