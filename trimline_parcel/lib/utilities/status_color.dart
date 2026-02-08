import 'package:flutter/material.dart';

import '../models/parcel_model.dart';

Color getStatusColor(ParcelStatus status) {
  switch (status) {
    case ParcelStatus.pending:
      return Colors.grey;
    case ParcelStatus.inTransit:
      return Colors.blue;
    case ParcelStatus.received:
      return Colors.orange;
    case ParcelStatus.collected:
      return Colors.green;
  }
}
