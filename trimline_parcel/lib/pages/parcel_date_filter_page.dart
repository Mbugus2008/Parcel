import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../widgets/parcel_card.dart';

class ParcelDateFilterPage extends StatefulWidget {
  const ParcelDateFilterPage({super.key});

  @override
  State<ParcelDateFilterPage> createState() => _ParcelDateFilterPageState();
}

class _ParcelDateFilterPageState extends State<ParcelDateFilterPage> {
  final ParcelController _parcelController = Get.find<ParcelController>();
  DateTime? _selectedDate = DateTime.now();
  final DateFormat _formatter = DateFormat('EEE, dd MMM yyyy');

  Future<void> _pickDate() async {
    final initialDate = _selectedDate ?? DateTime.now();
    final firstDate = DateTime(initialDate.year - 5);
    final lastDate = DateTime(initialDate.year + 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (!mounted || picked == null) return;
    setState(() => _selectedDate = picked);
  }

  void _clearFilter() {
    if (_selectedDate == null) return;
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcels by Date'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by date',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate == null
                                ? 'Showing all parcels'
                                : _formatter.format(_selectedDate!),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _pickDate,
                    ),
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: _clearFilter,
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_parcelController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<Parcel> filtered = (_selectedDate == null)
                  ? _parcelController.parcels.toList()
                  : _parcelController.parcels
                      .where((parcel) {
                        final sentDate = parcel.Date_sent;
                        return sentDate != null && DateUtils.isSameDay(sentDate, _selectedDate);
                      })
                      .toList();

              filtered.sort(
                (a, b) => (b.Date_sent ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(a.Date_sent ?? DateTime.fromMillisecondsSinceEpoch(0)),
              );

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _selectedDate == null
                        ? 'No parcels available'
                        : 'No parcels found for ${_formatter.format(_selectedDate!)}',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ParcelCard(parcel: filtered[index]),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
