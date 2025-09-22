import 'dart:math' as math;



import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:intl/intl.dart';



import '../controllers/parcel_controller.dart';
import 'addeditparcel.dart';

import '../models/parcel_model.dart';

import '../utilities/status_color.dart';



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

        backgroundColor: const Color(0xFF233556),

        elevation: 0,

        titleSpacing: 16,

        title: AnimatedSwitcher(

          duration: const Duration(milliseconds: 250),

          transitionBuilder:

              (child, animation) => FadeTransition(

                opacity: animation,

                child: SizeTransition(

                  sizeFactor: animation,

                  axisAlignment: -1,

                  child: child,

                ),

              ),

          child:

              _isSearching

                  ? _buildSearchField(

                    context,

                    autofocus: true,

                    onSubmitted: () => setState(() => _isSearching = false),

                    fieldKey: const ValueKey('search-field'),

                  )

                  : Row(

                    key: const ValueKey('title'),

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const Text('Parcel Dashboard'),

                      if (hasActiveFilters)

                        Padding(

                          padding: const EdgeInsets.only(left: 8),

                          child: Container(

                            padding: const EdgeInsets.symmetric(

                              horizontal: 10,

                              vertical: 4,

                            ),

                            decoration: BoxDecoration(

                              color: Colors.white.withOpacity(0.12),

                              borderRadius: BorderRadius.circular(999),

                              border: Border.all(

                                color: Colors.white.withOpacity(0.24),

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

              icon: const Icon(Icons.close_rounded, color: Colors.white70),

            )

          else

            IconButton(

              tooltip: 'Search parcels',

              onPressed: () => setState(() => _isSearching = true),

              icon: const Icon(Icons.search, color: Colors.white),

            ),

          IconButton(

            tooltip: 'Filter by status',

            // TODO: Add dropdown instead of buttomsheet

            onPressed: _openFilterSheet,

            icon: Icon(

              Icons.filter_list_rounded,

              color: hasActiveFilters ? Colors.amberAccent : Colors.white,

            ),

          ),

          if (hasActiveFilters)

            IconButton(

              tooltip: 'Clear filters',

              onPressed: _onClearFilters,

              icon: const Icon(Icons.clear_all_rounded, color: Colors.white70),

            ),

        ],

      ),

      body: Container(

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            colors: [Color(0xFF101728), Color(0xFF1F2A44)],

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

          ),

        ),

        child: SafeArea(

          child: Obx(() {

            if (_controller.isLoading) {

              return const Center(child: CircularProgressIndicator());

            }



            if (_controller.parcels.isEmpty) {

              return const Center(

                child: Text(

                  'No parcels available yet',

                  style: TextStyle(color: Colors.white70),

                ),

              );

            }



            final hasFilters =

                _controller.searchQuery.isNotEmpty ||

                _controller.statusFilter != null;

            final visibleParcels =

                hasFilters ? _controller.filteredParcels : _controller.parcels;

            final groups = _groupParcelsByStatus(visibleParcels);

            final firstNonEmptyIndex = _firstNonEmptyStep(groups);



            final statuses = _controller.supportedStatuses;

            final currentIndex =

                statuses.isEmpty

                    ? 0

                    : _currentStep.clamp(0, statuses.length - 1);

            final currentParcels =

                statuses.isEmpty

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

      trailing:

          selected

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

        suffixIcon:

            _searchController.text.isEmpty

                ? null

                : IconButton(

                  icon: const Icon(Icons.clear),

                  color: Colors.white54,

                  onPressed: _clearSearch,

                ),

        filled: true,

        fillColor: Colors.white.withOpacity(0.08),

        contentPadding: const EdgeInsets.symmetric(

          horizontal: 12,

          vertical: 12,

        ),

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(12),

          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),

        ),

        enabledBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(12),

          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),

        ),

        focusedBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(12),

          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),

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

        color: Colors.white.withOpacity(0.08),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.white.withOpacity(0.12)),

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

          colors: [Color(0xFF283349), Color(0xFF202736)],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.25),

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

                        color: color.withOpacity(

                          isActive || isComplete ? 0.28 : 0.14,

                        ),

                        shape: BoxShape.circle,

                        border: Border.all(

                          color: color.withOpacity(isActive ? 0.9 : 0.6),

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

                  onStepContinue:

                      currentStep >= statuses.length - 1

                          ? null

                          : () =>

                              setState(() => _currentStep = currentStep + 1),

                  onStepCancel:

                      currentStep <= 0

                          ? null

                          : () =>

                              setState(() => _currentStep = currentStep - 1),

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

              color: statusColor.withOpacity(0.2),

              shape: BoxShape.circle,

            ),

            child: Icon(_statusIcon(status), size: 18, color: statusColor),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              _controller.statusLabel(status),

              style: theme.textTheme.titleMedium?.copyWith(

                color: Colors.white,

                fontWeight: FontWeight.w700,

                fontSize: 24,

              ),

            ),

          ),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

            decoration: BoxDecoration(

              color: statusColor.withOpacity(0.22),

              borderRadius: BorderRadius.circular(999),

            ),

            child: Text(

              hasParcels ? '${parcels.length} ' : '0',

              style: theme.textTheme.labelMedium?.copyWith(

                color: Colors.white,

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

      content: _buildStepContent(context, parcels, statusColor),

    );

  }



  Widget _buildStepContent(

    BuildContext context,

    List<Parcel> parcels,

    Color statusColor,

  ) {

    final theme = Theme.of(context);



    if (parcels.isEmpty) {

      return Align(

        alignment: Alignment.centerLeft,

        child: Text(

          'No parcels here.',

          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),

        ),

      );

    }



    final parcelRows =

        parcels

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

        maxHeight: MediaQuery.of(context).size.height * 0.3,

      ),

      child: Scrollbar(

        child: SingleChildScrollView(

          padding: EdgeInsets.zero,

          physics: const BouncingScrollPhysics(),

          primary: false,

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: parcelRows,

          ),

        ),

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

      color: Colors.white,

      letterSpacing: 0.2,

    );

    final secondaryStyle = primaryStyle?.copyWith(color: Colors.white70);

    final borderColor = chipColor.withOpacity(0.38);



    return Chip(

      avatar: Icon(icon, color: chipColor.withOpacity(0.85), size: 16),

      backgroundColor: chipColor.withOpacity(0.14),

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(16),

        side: BorderSide(color: borderColor),

      ),

      label: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

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

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

    );

  }



  Widget _buildStepParcelRow({

    required BuildContext context,

    required Parcel parcel,

    required Color statusColor,

  }) {

    final theme = Theme.of(context);

    final route = _formatRoute(parcel);

    final sentDate =

        parcel.Date_sent != null

            ? DateFormat('dd MMM').format(parcel.Date_sent!)

            : 'No date';



    final senderParts = <String>[];

    final senderName = parcel.Sender_Name?.trim();

    if (senderName != null && senderName.isNotEmpty) {

      senderParts.add(senderName);

    }

    final senderPhone = parcel.Sender_Phone?.trim();

    if (senderPhone != null && senderPhone.isNotEmpty) {

      senderParts.add(senderPhone);

    }

    final senderDisplay = senderParts.isEmpty ? null : senderParts.join(' | ');



    final receiverParts = <String>[];

    final receiverName = parcel.Receiver_Name?.trim();

    if (receiverName != null && receiverName.isNotEmpty) {

      receiverParts.add(receiverName);

    }

    final receiverPhone = parcel.Receiver_Phone?.trim();

    if (receiverPhone != null && receiverPhone.isNotEmpty) {

      receiverParts.add(receiverPhone);

    }

    final receiverDisplay =

        receiverParts.isEmpty ? null : receiverParts.join(' | ');



    final contactChips = <Widget>[];

    if (senderDisplay != null) {

      contactChips.add(

        _buildContactChip(

          theme: theme,

          label: parcel.Sender_Name,

          detail: parcel.Sender_Phone,

          icon: Icons.send_rounded,

          chipColor: statusColor,

        ),

      );

    }

    if (receiverDisplay != null) {

      contactChips.add(

        _buildContactChip(

          theme: theme,

          label: parcel.Receiver_Name,

          detail: parcel.Receiver_Phone,

          icon: Icons.inbox_rounded,

          chipColor: statusColor,

        ),

      );

    }

    return GestureDetector(

      onTap: () => Get.to(() => AddEditParcelPage(parcel: parcel)),

      child: Card(

        margin: const EdgeInsets.only(bottom: 10),

        color: Colors.white.withOpacity(0.04),

        elevation: 2,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(10),

          side: BorderSide(color: statusColor.withOpacity(0.25)),

        ),

        child: Padding(

          padding: const EdgeInsets.all(2),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const SizedBox(width: 12),



                  Text(

                    parcel.Document_No ?? 'Unknown reference',

                    style: theme.textTheme.titleSmall?.copyWith(

                      color: Colors.white,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  const Spacer(),

                  Text(

                    parcel.Vehicle ?? '',

                    style: theme.textTheme.bodySmall?.copyWith(

                      color: Colors.white60,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  const Spacer(),

                  Text(

                    sentDate,

                    style: theme.textTheme.bodySmall?.copyWith(

                      color: Colors.white60,

                    ),

                  ),

                ],

              ),



              Row(

                children: [

                  if (route != null) const SizedBox(width: 12),

                  Text(

                    parcel.From ?? '',

                    style: theme.textTheme.bodySmall?.copyWith(

                      color: Colors.white70,

                    ),

                  ),

                  const Spacer(),

                  const Icon(Icons.arrow_forward_rounded, color: Colors.white70),

                  const Spacer(),

                  Text(

                    parcel.To ?? '',

                    style: theme.textTheme.bodySmall?.copyWith(

                      color: Colors.white70,

                    ),

                  ),

                ],

              ),



              if (contactChips.isNotEmpty)

                Padding(

                  padding: const EdgeInsets.only(top: 2),

                  child: Wrap(spacing: 2, runSpacing: 2, children: contactChips),

                ),

            ],

          ),

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



  String _statusDescription(ParcelStatus status) {

    switch (status) {

      case ParcelStatus.pending:

        return 'Newly logged parcels awaiting pickup or dispatch confirmation.';

      case ParcelStatus.inTransit:

        return 'Shipments moving between hubs or currently out with couriers.';

      case ParcelStatus.received:

        return 'Arrived at the destination hub and ready for customer collection.';

      case ParcelStatus.collected:

        return 'Parcels handed over to recipients and ready to close out the journey.';

    }

  }



  String? _formatRoute(Parcel parcel) {

    final parts = <String>[];



    final from = parcel.From?.trim();

    if (from != null && from.isNotEmpty) {

      parts.add(from);

    }



    final to = parcel.To?.trim();

    if (to != null && to.isNotEmpty) {

      parts.add(to);

    }



    if (parts.isEmpty) {

      return null;

    }



    if (parts.length == 1) {

      return parts.first;

    }



    return '${parts.first} -> ${parts.last}';

  }

}

