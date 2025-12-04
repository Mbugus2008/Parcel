import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../utilities/status_color.dart';
import '../utils/updater.dart';
import '../widgets/parcel_card.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/summary_card.dart';
import 'addeditparcel.dart';
import 'addeditparcel_v2.dart'; // V2 for testing
import 'login.dart';

class ParcelDashboardPage extends StatefulWidget {
  const ParcelDashboardPage({super.key});

  @override
  State<ParcelDashboardPage> createState() => _ParcelDashboardPageState();
}

class _ParcelDashboardPageState extends State<ParcelDashboardPage>
    with SingleTickerProviderStateMixin {
  final ParcelController _controller = Get.find<ParcelController>();

  late final TextEditingController _searchController;
  late TabController _tabController;

  ParcelStatus? _selectedStatus;

  int _currentStep = 0;

  bool _isSearching = false;

  // Tab index: 0=All, 1=Pending, 2=In Transit, 3=Received, 4=Collected
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(text: _controller.searchQuery);

    // Initialize tab controller with 5 tabs: All + 4 statuses
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          // Update status filter based on tab
          if (_selectedTabIndex == 0) {
            _selectedStatus = null;
            _controller.setStatusFilter(null);
          } else {
            final statuses = _controller.supportedStatuses;
            if (_selectedTabIndex - 1 < statuses.length) {
              _selectedStatus = statuses[_selectedTabIndex - 1];
              _controller.setStatusFilter(_selectedStatus);
            }
          }
        });
      }
    });

    _selectedStatus = _controller.statusFilter;

    // Check for app updates silently on dashboard load
    Future.delayed(const Duration(seconds: 2), () {
      Get.find<UpdateController>().checkForUpdate(showUpToDate: false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();

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
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parcel Dashboard',
                            style: TextStyle(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Connectivity indicator
                              Obx(() {
                                final connectivityService =
                                    Get.find<ConnectivityService>();
                                if (connectivityService.isOffline) {
                                  return const Icon(
                                    Icons.cloud_off,
                                    color: Colors.redAccent,
                                    size: 18,
                                  );
                                } else {
                                  return const Icon(
                                    Icons.cloud_done,
                                    color: Colors.green,
                                    size: 18,
                                  );
                                }
                              }),
                              const SizedBox(width: 8),
                              // Printer indicator
                              Obx(() {
                                final device = _controller.activePrinter;
                                if (device == null) {
                                  return const Icon(
                                    Icons.print_disabled,
                                    color: Colors.redAccent,
                                    size: 18,
                                  );
                                } else {
                                  return const Icon(
                                    Icons.print_rounded,
                                    color: Colors.green,
                                    size: 18,
                                  );
                                }
                              }),
                            ],
                          ),
                        ],
                      ),
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
            PopupMenuButton<ParcelStatus?>(
              tooltip: 'Filter by status',
              icon: Icon(
                Icons.filter_list_rounded,
                color: hasActiveFilters ? Colors.amber : Colors.black,
              ),
              onSelected: (status) => _onStatusFilterChanged(status),
              itemBuilder: (context) => [
                PopupMenuItem<ParcelStatus?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: _selectedStatus == null
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text('All statuses'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ..._controller.supportedStatuses.map(
                  (status) => PopupMenuItem<ParcelStatus?>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(status),
                          color: getStatusColor(status),
                        ),
                        const SizedBox(width: 12),
                        Text(_controller.statusLabel(status)),
                      ],
                    ),
                  ),
                ),
              ],
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
      floatingActionButton: FloatingActionButton.extended(
        // Using V2 for testing - change back to AddEditParcelPage if issues
        onPressed: () => Get.to(() => const AddEditParcelPageV2()),
        backgroundColor: const Color(0xFF233556),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Parcel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF5F7FA)),
        child: SafeArea(
          child: Obx(() {
            // Access reactive values to trigger rebuilds
            final isLoading = _controller.isLoadingRx.value;
            final parcels = _controller.parcelsRx.toList();
            final filteredParcels = _controller.filteredParcelsRx.toList();
            final searchQuery = _controller.searchQueryRx.value;
            final statusFilter = _controller.statusFilterRx.value;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (parcels.isEmpty) {
              return _buildEmptyState(context);
            }

            final hasFilters = searchQuery.isNotEmpty || statusFilter != null;

            final visibleParcels = hasFilters ? filteredParcels : parcels;

            final groups =
                _groupParcelsByStatus(parcels); // Use all parcels for counts

            // Get parcels for current tab
            final tabParcels =
                _getTabParcels(visibleParcels, _selectedTabIndex);

            return RefreshIndicator(
              onRefresh: () => _controller.loadParcels(),
              color: Theme.of(context).colorScheme.primary,
              child: Column(
                children: [
                  // Summary Cards Section
                  _buildSummaryCards(context, groups, parcels),
                  const SizedBox(height: 8),
                  // Tab Bar
                  _buildStatusTabs(context, groups),
                  // Parcel List
                  Expanded(
                    child: tabParcels.isEmpty
                        ? _buildNoResultsBanner(context)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: tabParcels.length,
                            itemBuilder: (context, index) {
                              return ParcelCard(parcel: tabParcels[index]);
                            },
                          ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Get parcels based on selected tab index
  List<Parcel> _getTabParcels(List<Parcel> parcels, int tabIndex) {
    if (tabIndex == 0) return parcels; // All parcels
    final statuses = _controller.supportedStatuses;
    if (tabIndex - 1 >= statuses.length) return parcels;
    final targetStatus = statuses[tabIndex - 1];
    return parcels.where((p) => p.Status == targetStatus).toList();
  }

  /// Build summary cards row
  Widget _buildSummaryCards(
    BuildContext context,
    Map<ParcelStatus, List<Parcel>> groups,
    List<Parcel> allParcels,
  ) {
    final pending = groups[ParcelStatus.pending]?.length ?? 0;
    final inTransit = groups[ParcelStatus.inTransit]?.length ?? 0;
    final received = groups[ParcelStatus.received]?.length ?? 0;
    final collected = groups[ParcelStatus.collected]?.length ?? 0;

    // Count today's parcels
    final today = DateTime.now();
    final todayParcels = allParcels.where((p) {
      final date = p.Date_sent;
      if (date == null) return false;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          // First row: Pending, In Transit
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  icon: Icons.pending_actions_rounded,
                  value: '$pending',
                  title: 'Pending',
                  gradientColors: const [Color(0xFFFF6B9D), Color(0xFFC44569)],
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  icon: Icons.local_shipping_rounded,
                  value: '$inTransit',
                  title: 'In Transit',
                  gradientColors: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Received, Collected, Today
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  icon: Icons.home_work_rounded,
                  value: '$received',
                  title: 'Received',
                  gradientColors: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
                  onTap: () => _tabController.animateTo(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  icon: Icons.verified_rounded,
                  value: '$collected',
                  title: 'Collected',
                  gradientColors: const [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
                  onTap: () => _tabController.animateTo(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  icon: Icons.today_rounded,
                  value: '$todayParcels',
                  title: 'Today',
                  gradientColors: const [Color(0xFFFA709A), Color(0xFFFEE140)],
                  onTap: () {}, // Could filter by date
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build horizontal status tabs
  Widget _buildStatusTabs(
    BuildContext context,
    Map<ParcelStatus, List<Parcel>> groups,
  ) {
    final theme = Theme.of(context);
    final statuses = _controller.supportedStatuses;
    final allCount =
        groups.values.fold<int>(0, (sum, list) => sum + list.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(6),
        tabs: [
          _buildTab('All', allCount, null),
          ...statuses.map((status) => _buildTab(
                _controller.statusLabel(status),
                groups[status]?.length ?? 0,
                status,
              )),
        ],
      ),
    );
  }

  /// Build individual tab with count badge
  Widget _buildTab(String label, int count, ParcelStatus? status) {
    final color = status != null ? getStatusColor(status) : Colors.grey;
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an attractive empty state when no parcels exist
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Parcels Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by logging your first parcel.\nAll your shipments will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const AddEditParcelPage()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log New Parcel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
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
      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
      cursorColor: Colors.blue,
      decoration: InputDecoration(
        hintText: 'Search parcels...',
        hintStyle:
            theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                color: Colors.grey.shade600,
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No parcels found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No parcels match your current filters.\nTry adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _onClearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear filters'),
            ),
          ],
        ),
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

    // Add number of items
    final itemsCount = parcel.parcelDetails.length;
    if (itemsCount > 0) {
      infoPills.add(
        _buildInfoPill(
          theme: theme,
          icon: Icons.inventory_2_rounded,
          label: '$itemsCount ${itemsCount == 1 ? 'item' : 'items'}',
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
                  // User avatar
                  Obx(() {
                    final user = Get.find<AuthService>().currentUser;
                    return CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(
                        user?.name?.isNotEmpty == true
                            ? user!.name![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  // User name
                  Obx(() {
                    final user = Get.find<AuthService>().currentUser;
                    return Text(
                      user?.name ?? 'Welcome',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                  const SizedBox(height: 2),
                  // User role/account type
                  Obx(() {
                    final user = Get.find<AuthService>().currentUser;
                    final role = user?.accountType?.displayName ?? 'User';
                    return Text(
                      role,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    );
                  }),
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
            const Divider(),
            Obx(() {
              final connectivityService = Get.find<ConnectivityService>();
              return ListTile(
                leading: Icon(
                  connectivityService.isOffline ? Icons.cloud_off : Icons.sync,
                  color: connectivityService.isOffline ? Colors.red : null,
                ),
                title: Text(
                  connectivityService.isOffline ? "Offline Mode" : "Sync Data",
                ),
                subtitle: Text(
                  connectivityService.isOffline
                      ? "Changes will sync when online"
                      : "Tap to refresh data",
                ),
                onTap: connectivityService.isOffline
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _controller.loadParcels();
                        await Get.find<ConnectivityService>().forceCheck();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data refreshed'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
              );
            }),
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
              leading: const Icon(Icons.system_update_rounded),
              title: const Text("Check for Updates"),
              subtitle: const Text("Download latest version"),
              onTap: () {
                Navigator.of(context).pop();
                Get.find<UpdateController>().checkForUpdate(showUpToDate: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text("Support"),
              subtitle: const Text("Contact logistics for help"),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                await Get.find<AuthService>().logout();
                Get.offAll(() => const LoginScreen());
              },
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
