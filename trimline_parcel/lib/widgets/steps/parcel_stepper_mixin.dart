import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/parcel_controller.dart';
import '../../models/Parcel_Details.dart';
import 'items_info_step.dart';
import 'parcel_info_step.dart';
import 'receiver_info_step.dart';
import 'sender_info_step.dart';

/// Focus nodes required for the parcel form
class ParcelFormFocusNodes {
  final FocusNode amountPaid = FocusNode();
  final FocusNode from = FocusNode();
  final FocusNode to = FocusNode();
  final FocusNode senderName = FocusNode();
  final FocusNode senderPhone = FocusNode();
  final FocusNode senderId = FocusNode();
  final FocusNode receiverName = FocusNode();
  final FocusNode receiverPhone = FocusNode();
  final FocusNode receiverId = FocusNode();

  /// Dispose all focus nodes
  void dispose() {
    amountPaid.dispose();
    from.dispose();
    to.dispose();
    senderName.dispose();
    senderPhone.dispose();
    senderId.dispose();
    receiverName.dispose();
    receiverPhone.dispose();
    receiverId.dispose();
  }
}

/// Mixin that provides stepper building functionality for parcel forms
mixin ParcelStepperMixin<T extends StatefulWidget> on State<T> {
  /// The parcel controller - must be provided by the implementing class
  ParcelController get stepperController;

  /// Focus nodes - must be provided by the implementing class
  ParcelFormFocusNodes get focusNodes;

  /// Whether the form is view-only
  bool get isViewOnly;

  /// Current step index
  int get currentStep;

  /// Called when step should change
  void onStepChanged(int step);

  /// Called when an item should be edited
  Future<void> onEditItem(
      BuildContext context, Parcel_Details detail, int index);

  /// Called when items list changes
  void onItemsChanged();

  /// Called when add item button is pressed
  Future<void> onAddItem();

  /// Build the step content wrapper with styling
  Widget wrapStepContent(Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  /// Build all stepper steps
  List<Step> buildSteps(BuildContext context) {
    final controller = stepperController;
    final fn = focusNodes;

    // Step content widgets
    final contents = [
      wrapStepContent(ParcelInfoStep(
        controller: controller,
        isViewOnly: isViewOnly,
        amountPaidFocusNode: fn.amountPaid,
        fromFocusNode: fn.from,
        toFocusNode: fn.to,
        senderNameFocusNode: fn.senderName,
        currentStep: currentStep,
        onStepChanged: onStepChanged,
      )),
      wrapStepContent(SenderInfoStep(
        controller: controller,
        isViewOnly: isViewOnly,
        senderNameFocusNode: fn.senderName,
        senderPhoneFocusNode: fn.senderPhone,
        senderIdFocusNode: fn.senderId,
        receiverNameFocusNode: fn.receiverName,
        currentStep: currentStep,
        parentContext: context,
      )),
      wrapStepContent(ReceiverInfoStep(
        controller: controller,
        isViewOnly: isViewOnly,
        receiverNameFocusNode: fn.receiverName,
        receiverPhoneFocusNode: fn.receiverPhone,
        receiverIdFocusNode: fn.receiverId,
        currentStep: currentStep,
        onStepChanged: onStepChanged,
      )),
      wrapStepContent(ItemsInfoStep(
        controller: controller,
        isViewOnly: isViewOnly,
        onEditItem: onEditItem,
        onItemsChanged: onItemsChanged,
      )),
    ];

    // Step metadata
    final titles = ['Parcel', 'Sender', 'Receiver', 'Items'];
    final subtitles = [
      _getParcelSubtitle(),
      _getSenderSubtitle(),
      _getReceiverSubtitle(),
      _getItemsSubtitle(),
    ];
    final errors = [
      controller.parcelinformationError,
      controller.senderinformationError,
      controller.receiverinformationError,
      controller.itemsError,
    ];

    return List.generate(titles.length, (index) {
      final isItemsStep = index == 3;

      Widget subtitleWidget;
      if (isItemsStep) {
        subtitleWidget = Row(
          children: [
            Expanded(
                child: _buildSubtitleText(errors[index], subtitles[index])),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              tooltip: 'Add item',
              onPressed: isViewOnly ? null : onAddItem,
            ),
          ],
        );
      } else {
        subtitleWidget = _buildSubtitleText(errors[index], subtitles[index]);
      }

      return Step(
        title: Text(
          titles[index],
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
        subtitle: subtitleWidget,
        state: _getStepState(index),
        isActive: currentStep >= index,
        content: contents[index],
      );
    });
  }

  Widget _buildSubtitleText(RxString error, String subtitle) {
    return Obx(() {
      final hasError = error.value.isNotEmpty;
      return Text(
        hasError ? error.value : subtitle,
        style: TextStyle(
          color: hasError ? Colors.redAccent : Colors.black54,
          fontSize: 14,
        ),
      );
    });
  }

  StepState _getStepState(int index) {
    if (currentStep > index) return StepState.complete;
    if (currentStep == index) return StepState.editing;
    return StepState.indexed;
  }

  String _getParcelSubtitle() {
    final docNo = stepperController.documentNoController.text.trim();
    return docNo.isNotEmpty ? docNo : 'Parcel Details';
  }

  String _getSenderSubtitle() {
    final name = stepperController.senderNameController.text.trim();
    return name.isNotEmpty ? name : 'Who is sending';
  }

  String _getReceiverSubtitle() {
    final name = stepperController.receiverNameController.text.trim();
    return name.isNotEmpty ? name : 'Receiver';
  }

  String _getItemsSubtitle() {
    final details =
        stepperController.parcel?.parcelDetails ?? <Parcel_Details>[];
    if (details.isEmpty) return 'No items';
    final total =
        details.fold<double>(0, (sum, item) => sum + (item.Amount ?? 0.0));
    return '${details.length} items • KES ${total.toStringAsFixed(2)}';
  }
}
