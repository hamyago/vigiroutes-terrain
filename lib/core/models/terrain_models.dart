// ignore_for_file: always_specify_types

class TerrainBookingModel {
  final String id;
  final String reference;
  final DateTime? slotStartsAt;
  final String status;
  final String? transportMode;
  final String registrationNumber;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final String? vehicleCategory;
  final String clientName;
  final String clientPhone;
  final String? centerName;

  const TerrainBookingModel({
    required this.id,
    required this.reference,
    this.slotStartsAt,
    required this.status,
    this.transportMode,
    required this.registrationNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    this.vehicleCategory,
    required this.clientName,
    required this.clientPhone,
    this.centerName,
  });

  factory TerrainBookingModel.fromJson(Map<String, dynamic> json) {
    return TerrainBookingModel(
      id: json['id'] as String,
      reference: json['reference'] as String,
      slotStartsAt: json['slot_starts_at'] != null
          ? DateTime.tryParse(json['slot_starts_at'] as String)
          : null,
      status: json['status'] as String,
      transportMode: json['transport_mode'] as String?,
      registrationNumber: json['registration_number'] as String,
      vehicleBrand: json['vehicle_brand'] as String,
      vehicleModel: json['vehicle_model'] as String,
      vehicleColor: json['vehicle_color'] as String,
      vehicleCategory: json['vehicle_category'] as String?,
      clientName: json['client_name'] as String,
      clientPhone: json['client_phone'] as String,
      centerName: json['center_name'] as String?,
    );
  }

  /// Heure du créneau formatée (ex: "08:30")
  String get slotTime {
    if (slotStartsAt == null) return '--:--';
    final h = slotStartsAt!.hour.toString().padLeft(2, '0');
    final m = slotStartsAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'arrived':
        return 'Arrivé';
      case 'in_progress':
        return 'En cours';
      case 'favorable':
        return 'Favorable';
      case 'defavorable':
        return 'Défavorable';
      case 'contre_visite':
        return 'Contre-visite';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  TerrainBookingModel copyWith({
    String? id,
    String? reference,
    DateTime? slotStartsAt,
    String? status,
    String? transportMode,
    String? registrationNumber,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleCategory,
    String? clientName,
    String? clientPhone,
    String? centerName,
  }) {
    return TerrainBookingModel(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      slotStartsAt: slotStartsAt ?? this.slotStartsAt,
      status: status ?? this.status,
      transportMode: transportMode ?? this.transportMode,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      centerName: centerName ?? this.centerName,
    );
  }
}

class TerrainDashboardModel {
  final String date;
  final int totalExpectedToday;
  final int arrived;
  final int favorable;
  final int defavorable;
  final int myScansToday;
  final int myReportsToday;

  const TerrainDashboardModel({
    required this.date,
    required this.totalExpectedToday,
    required this.arrived,
    required this.favorable,
    required this.defavorable,
    required this.myScansToday,
    required this.myReportsToday,
  });

  factory TerrainDashboardModel.fromJson(Map<String, dynamic> json) {
    return TerrainDashboardModel(
      date: json['date'] as String,
      totalExpectedToday: json['total_expected_today'] as int? ?? 0,
      arrived: json['arrived'] as int? ?? 0,
      favorable: json['favorable'] as int? ?? 0,
      defavorable: json['defavorable'] as int? ?? 0,
      myScansToday: json['my_scans_today'] as int? ?? 0,
      myReportsToday: json['my_reports_today'] as int? ?? 0,
    );
  }

  TerrainDashboardModel copyWith({
    String? date,
    int? totalExpectedToday,
    int? arrived,
    int? favorable,
    int? defavorable,
    int? myScansToday,
    int? myReportsToday,
  }) {
    return TerrainDashboardModel(
      date: date ?? this.date,
      totalExpectedToday: totalExpectedToday ?? this.totalExpectedToday,
      arrived: arrived ?? this.arrived,
      favorable: favorable ?? this.favorable,
      defavorable: defavorable ?? this.defavorable,
      myScansToday: myScansToday ?? this.myScansToday,
      myReportsToday: myReportsToday ?? this.myReportsToday,
    );
  }
}

class TerrainStatsModel {
  final int todayTotal;
  final int todayCompleted;
  final int todayPending;
  final int weekTotal;
  final int monthTotal;
  final int pendingNow;
  final double favorableRate;
  final double defavorableRate;
  final double contreVisiteRate;

  const TerrainStatsModel({
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayPending,
    required this.weekTotal,
    required this.monthTotal,
    required this.pendingNow,
    required this.favorableRate,
    required this.defavorableRate,
    required this.contreVisiteRate,
  });

  factory TerrainStatsModel.fromJson(Map<String, dynamic> json) {
    return TerrainStatsModel(
      todayTotal: json['today_total'] as int? ?? 0,
      todayCompleted: json['today_completed'] as int? ?? 0,
      todayPending: json['today_pending'] as int? ?? 0,
      weekTotal: json['week_total'] as int? ?? 0,
      monthTotal: json['month_total'] as int? ?? 0,
      pendingNow: json['pending_now'] as int? ?? 0,
      favorableRate: (json['favorable_rate'] as num? ?? 0).toDouble(),
      defavorableRate: (json['defavorable_rate'] as num? ?? 0).toDouble(),
      contreVisiteRate: (json['contre_visite_rate'] as num? ?? 0).toDouble(),
    );
  }
}
