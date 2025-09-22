import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/parcel_controller.dart';
import '../widgets/parcel_card.dart';

class Send extends StatelessWidget {
   Send({Key? key}) : super(key: key);
final ParcelController _parcelController = Get.find<ParcelController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => ListView.builder(
          itemCount: _parcelController.parcelsRx.length,
          itemBuilder: (context, index) {
            return ParcelCard(
              parcel: _parcelController.parcelsRx[index],
            );
          },
        )),
      ),
    );
  }
} 
class ReceiveParcelListPage extends StatelessWidget {
   ReceiveParcelListPage({Key? key}) : super(key: key);
final ParcelController _parcelController = Get.find<ParcelController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => ListView.builder(
          itemCount: _parcelController.parcelsRx.length,
          itemBuilder: (context, index) {
            return ParcelCard(
              parcel: _parcelController.parcelsRx[index],
            );
          },
        )),
      ),
    );
  }
}
