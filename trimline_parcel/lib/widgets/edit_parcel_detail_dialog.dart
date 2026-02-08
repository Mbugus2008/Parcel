import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/Parcel_Details.dart';

/// Dialog widget for editing a Parcel_Details entry.
/// Owns its controllers and properly disposes them.
class EditParcelDetailDialog extends StatefulWidget {
  final Parcel_Details parcelDetail;
  final int index;
  final ParcelController parcelController;

  const EditParcelDetailDialog({
    super.key,
    required this.parcelDetail,
    required this.index,
    required this.parcelController,
  });

  @override
  State<EditParcelDetailDialog> createState() => _EditParcelDetailDialogState();
}

class _EditParcelDetailDialogState extends State<EditParcelDetailDialog> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _remarksCtrl;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'en_US', symbol: 'KES ');

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.parcelDetail.Description);
    _amountCtrl = TextEditingController(
        text: widget.parcelDetail.Amount?.toString() ?? '');
    _remarksCtrl = TextEditingController(text: widget.parcelDetail.Remarks);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(child: _buildForm(context)),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.lightBlueAccent.shade100],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.18),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Item',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.parcelDetail.Description?.isNotEmpty == true
                      ? widget.parcelDetail.Description!
                      : 'Item ${widget.index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: null,
                minLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the item',
                  prefixIcon: const Icon(Icons.subject),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.monetization_on),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                ],
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (val > 1000000) {
                    return 'Amount seems too large. Please verify.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Remarks
              TextFormField(
                controller: _remarksCtrl,
                decoration: InputDecoration(
                  labelText: 'Remarks (optional)',
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Live preview
              _buildPreviewCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _descCtrl.text.isNotEmpty
                        ? _descCtrl.text
                        : 'No description',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _remarksCtrl.text.isNotEmpty ? _remarksCtrl.text : '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _currencyFmt.format(double.tryParse(_amountCtrl.text) ?? 0.0),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final desc = _descCtrl.text.trim();
                final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                final remarks = _remarksCtrl.text.trim();
                widget.parcelController.updateParcelDetail(
                  widget.index,
                  desc,
                  amount,
                  remarks,
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Shows the edit parcel detail dialog
Future<void> showEditParcelDetailDialog(
  BuildContext context,
  Parcel_Details detail,
  int index,
  ParcelController controller,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => EditParcelDetailDialog(
      parcelDetail: detail,
      index: index,
      parcelController: controller,
    ),
  );
}
