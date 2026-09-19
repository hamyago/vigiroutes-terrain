class TerrainBookingModel {
  final String id;
  final String reference;
  final String clientName;
  final String clientPhone;
  final String registrationNumber;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final String slotTime;
  final String status;
  final String transportMode;
  final String centerName;
  final DateTime? arrivedAt;
  final DateTime? inspectionStartedAt;
  final DateTime? completedAt;

  const TerrainBookingModel({
    required this.id,
    required this.reference,
    required this.clientName,
    required this.clientPhone,
    required this.registrationNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.slotTime,
    required this.status,
    required this.transportMode,
    required this.centerName,
    this.arrivedAt,
    this.inspectionStartedAt,
    this.completedAt,
  });

  factory TerrainBookingModel.fromJson(Map<String, dynamic> json) {
    return TerrainBookingModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? '',
      registrationNumber: json['registration_number']?.toString() ?? '',
      vehicleBrand: json['vehicle_brand']?.toString() ?? '',
      vehicleModel: json['vehicle_model']?.toString() ?? '',
      vehicleColor: json['vehicle_color']?.toString() ?? '',
      slotTime: json['slot_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending_arrival',
      transportMode: json['transport_mode']?.toString() ?? 'self',
      centerName: json['center_name']?.toString() ?? '',
      arrivedAt: json['arrived_at'] != null
          ? DateTime.tryParse(json['arrived_at'].toString())
          : null,
      inspectionStartedAt: json['inspection_started_at'] != null
          ? DateTime.tryParse(json['inspection_started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  TerrainBookingModel copyWith({
    String? id,
    String? reference,
    String? clientName,
    String? clientPhone,
    String? registrationNumber,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    String? slotTime,
    String? status,
    String? transportMode,
    String? centerName,
    DateTime? arrivedAt,
    DateTime? inspectionStartedAt,
    DateTime? completedAt,
  }) {
    return TerrainBookingModel(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      slotTime: slotTime ?? this.slotTime,
      status: status ?? this.status,
      transportMode: transportMode ?? this.transportMode,
      centerName: centerName ?? this.centerName,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      inspectionStartedAt: inspectionStartedAt ?? this.inspectionStartedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class TerrainReportModel {
  final String result;
  final String? nonConformityPoints;
  final String? recommendations;
  final String? nextVtDate;
  final String pvNumber;
  final String? photoUrl;

  const TerrainReportModel({
    required this.result,
    this.nonConformityPoints,
    this.recommendations,
    this.nextVtDate,
    required this.pvNumber,
    this.photoUrl,
  });

  factory TerrainReportModel.fromJson(Map<String, dynamic> json) {
    return TerrainReportModel(
      result: json['result']?.toString() ?? '',
      nonConformityPoints: json['non_conformity_points']?.toString(),
      recommendations: json['recommendations']?.toString(),
      nextVtDate: json['next_vt_date']?.toString(),
      pvNumber: json['pv_number']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
    );
  }
}

class TerrainStatsModel {
  final int todayTotal;
  final int todayCompleted;
  final int todayPending;
  final int weekTotal;
  final int monthTotal;
  final double favorableRate;
  final double defavorableRate;
  final double contreVisiteRate;
  final int pendingNow;

  const TerrainStatsModel({
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayPending,
    required this.weekTotal,
    required this.monthTotal,
    required this.favorableRate,
    required this.defavorableRate,
    required this.contreVisiteRate,
    required this.pendingNow,
  });

  factory TerrainStatsModel.fromJson(Map<String, dynamic> json) {
    return TerrainStatsModel(
      todayTotal: (json['today_total'] as num?)?.toInt() ?? 0,
      todayCompleted: (json['today_completed'] as num?)?.toInt() ?? 0,
      todayPending: (json['today_pending'] as num?)?.toInt() ?? 0,
      weekTotal: (json['week_total'] as num?)?.toInt() ?? 0,
      monthTotal: (json['month_total'] as num?)?.toInt() ?? 0,
      favorableRate: (json['favorable_rate'] as num?)?.toDouble() ?? 0.0,
      defavorableRate: (json['defavorable_rate'] as num?)?.toDouble() ?? 0.0,
      contreVisiteRate: (json['contre_visite_rate'] as num?)?.toDouble() ?? 0.0,
      pendingNow: (json['pending_now'] as num?)?.toInt() ?? 0,
    );
  }
}
