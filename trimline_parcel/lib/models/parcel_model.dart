import 'package:trimline_parcel/models/Parcel_Details.dart';

enum WhoToPay {
  Sender,
  Receiver,
}

typedef Who_to_Pay = WhoToPay;

enum ParcelStatus {
  pending,
  inTransit,
  received,
  collected,
}

class Parcel {
  String? Document_No;
  DateTime? Date_sent;
  String? Sender_Name;
  String? Sender_ID;
  String? Sender_Phone;
  String? From;
  String? To;
  String? Receiver_Name;
  String? Receiver_ID;
  String? Receiver_Phone;
  ParcelStatus? Status;
  String? Driver;
  String? Vehicle;
  WhoToPay? Who_to_Pay;
  double? Amount_Paid;
  bool? Paid;
  DateTime? Date_Collected;
  DateTime? Date_Delivered;
  DateTime? Out_For_Delivery_Time;
  DateTime? Date_Returned;
  String? Notes;
  List<Parcel_Details> parcelDetails;

  Parcel({
    this.Document_No,
    this.Date_sent,
    this.Sender_Name,
    this.Sender_ID,
    this.Sender_Phone,
    this.From,
    this.To,
    this.Receiver_Name,
    this.Receiver_ID,
    this.Receiver_Phone,
    this.Status,
    this.Driver,
    this.Vehicle,
    this.Who_to_Pay = WhoToPay.Sender,
    this.Amount_Paid = 0,
    this.Paid = false,
    this.Date_Collected,
    this.Date_Delivered,
    this.Out_For_Delivery_Time,
    this.Date_Returned,
    this.Notes,
    List<Parcel_Details>? parcelDetails,
  }) : parcelDetails = parcelDetails ?? <Parcel_Details>[];

  Map<String, dynamic> toJson() {
    return {
      'Document_No': Document_No,
      'Date_sent': Date_sent?.toIso8601String(),
      'Sender_Name': Sender_Name,
      'Sender_ID': Sender_ID,
      'Sender_Phone': Sender_Phone,
      'From': From,
      'To': To,
      'Receiver_Name': Receiver_Name,
      'Receiver_ID': Receiver_ID,
      'Receiver_Phone': Receiver_Phone,
      'Status': Status?.name,
      'Driver': Driver,
      'Vehicle': Vehicle,
      'Who_to_Pay': Who_to_Pay?.name,
      'Amount_Paid': Amount_Paid,
      'Paid': Paid,
      'Date_Collected': Date_Collected?.toIso8601String(),
      'Date_Delivered': Date_Delivered?.toIso8601String(),
      'Out_For_Delivery_Time': Out_For_Delivery_Time?.toIso8601String(),
      'Date_Returned': Date_Returned?.toIso8601String(),
      'Notes': Notes,
      'Details': parcelDetails.map((d) => d.toJson()).toList(),
    };
  }

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      Document_No: json['Document_No'] as String?,
      Date_sent: _parseDate(json['Date_sent']),
      Sender_Name: json['Sender_Name'] as String?,
      Sender_ID: json['Sender_ID'] as String?,
      Sender_Phone: json['Sender_Phone'] as String?,
      From: json['From'] as String?,
      To: json['To'] as String?,
      Receiver_Name: json['Receiver_Name'] as String?,
      Receiver_ID: json['Receiver_ID'] as String?,
      Receiver_Phone: json['Receiver_Phone'] as String?,
      Status: _parseStatus(json['Status']),
      Driver: json['Driver'] as String?,
      Vehicle: json['Vehicle'] as String?,
      Who_to_Pay: _parseWhoToPay(json['Who_to_Pay']),
      Amount_Paid: (json['Amount_Paid'] as num?)?.toDouble(),
      Paid: json['Paid'] as bool? ?? false,
      Date_Collected: _parseDate(json['Date_Collected']),
      Date_Delivered: _parseDate(json['Date_Delivered']),
      Out_For_Delivery_Time: _parseDate(json['Out_For_Delivery_Time']),
      Date_Returned: _parseDate(json['Date_Returned']),
      Notes: json['Notes'] as String?,
      parcelDetails: (json['Details'] as List?)
              ?.map((item) => Parcel_Details.fromJson(item as Map<String, dynamic>))
              .toList() ??
          <Parcel_Details>[],
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'Document_No': Document_No,
      'Date_sent': Date_sent?.toIso8601String(),
      'Sender_Name': Sender_Name,
      'Sender_ID': Sender_ID,
      'Sender_Phone': Sender_Phone,
      'From_Location': From,
      'To_Location': To,
      'Receiver_Name': Receiver_Name,
      'Receiver_ID': Receiver_ID,
      'Receiver_Phone': Receiver_Phone,
      'Status': Status?.name,
      'Driver': Driver,
      'Vehicle': Vehicle,
      'WhoToPay': Who_to_Pay?.name,
      'Amount_Paid': Amount_Paid,
      'Paid': (Paid ?? false) ? 1 : 0,
      'Date_Collected': Date_Collected?.toIso8601String(),
      'Date_Delivered': Date_Delivered?.toIso8601String(),
      'Out_For_Delivery_Time': Out_For_Delivery_Time?.toIso8601String(),
      'Date_Returned': Date_Returned?.toIso8601String(),
      'Description': Notes,
    };
  }

  factory Parcel.fromDbMap(Map<String, dynamic> map) {
    return Parcel(
      Document_No: map['Document_No'] as String?,
      Date_sent: _parseDate(map['Date_sent']),
      Sender_Name: map['Sender_Name'] as String?,
      Sender_ID: map['Sender_ID'] as String?,
      Sender_Phone: map['Sender_Phone'] as String?,
      From: map['From_Location'] as String?,
      To: map['To_Location'] as String?,
      Receiver_Name: map['Receiver_Name'] as String?,
      Receiver_ID: map['Receiver_ID'] as String?,
      Receiver_Phone: map['Receiver_Phone'] as String?,
      Status: _parseStatus(map['Status']),
      Driver: map['Driver'] as String?,
      Vehicle: map['Vehicle'] as String?,
      Who_to_Pay: _parseWhoToPay(map['WhoToPay']),
      Amount_Paid: (map['Amount_Paid'] as num?)?.toDouble(),
      Paid: (map['Paid'] as int? ?? 0) == 1,
      Date_Collected: _parseDate(map['Date_Collected']),
      Date_Delivered: _parseDate(map['Date_Delivered']),
      Out_For_Delivery_Time: _parseDate(map['Out_For_Delivery_Time']),
      Date_Returned: _parseDate(map['Date_Returned']),
      Notes: map['Description'] as String?,
    );
  }

  Parcel copyWith({
    String? Document_No,
    DateTime? Date_sent,
    String? Sender_Name,
    String? Sender_ID,
    String? Sender_Phone,
    String? From,
    String? To,
    String? Receiver_Name,
    String? Receiver_ID,
    String? Receiver_Phone,
    ParcelStatus? Status,
    String? Driver,
    String? Vehicle,
    WhoToPay? Who_to_Pay,
    double? Amount_Paid,
    bool? Paid,
    DateTime? Date_Collected,
    DateTime? Date_Delivered,
    DateTime? Out_For_Delivery_Time,
    DateTime? Date_Returned,
    String? Notes,
    List<Parcel_Details>? parcelDetails,
  }) {
    return Parcel(
      Document_No: Document_No ?? this.Document_No,
      Date_sent: Date_sent ?? this.Date_sent,
      Sender_Name: Sender_Name ?? this.Sender_Name,
      Sender_ID: Sender_ID ?? this.Sender_ID,
      Sender_Phone: Sender_Phone ?? this.Sender_Phone,
      From: From ?? this.From,
      To: To ?? this.To,
      Receiver_Name: Receiver_Name ?? this.Receiver_Name,
      Receiver_ID: Receiver_ID ?? this.Receiver_ID,
      Receiver_Phone: Receiver_Phone ?? this.Receiver_Phone,
      Status: Status ?? this.Status,
      Driver: Driver ?? this.Driver,
      Vehicle: Vehicle ?? this.Vehicle,
      Who_to_Pay: Who_to_Pay ?? this.Who_to_Pay,
      Amount_Paid: Amount_Paid ?? this.Amount_Paid,
      Paid: Paid ?? this.Paid,
      Date_Collected: Date_Collected ?? this.Date_Collected,
      Date_Delivered: Date_Delivered ?? this.Date_Delivered,
      Out_For_Delivery_Time:
          Out_For_Delivery_Time ?? this.Out_For_Delivery_Time,
      Date_Returned: Date_Returned ?? this.Date_Returned,
      Notes: Notes ?? this.Notes,
      parcelDetails: parcelDetails ?? this.parcelDetails,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static ParcelStatus _parseStatus(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? '';
    switch (raw) {
      case 'pending':
        return ParcelStatus.pending;
      case 'intransit':
      case 'outfordelivery':
        return ParcelStatus.inTransit;
      case 'received':
      case 'delivered':
        return ParcelStatus.received;
      case 'collected':
      case 'returned':
        return ParcelStatus.collected;
      default:
        return ParcelStatus.pending;
    }
  }

  static WhoToPay _parseWhoToPay(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'receiver':
        return WhoToPay.Receiver;
      default:
        return WhoToPay.Sender;
    }
  }
}

