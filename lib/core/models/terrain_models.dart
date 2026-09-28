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


// ─────────────────────────────────────────────────────────────────────────────
// TransportMissionModel — mission de transport CT (remorqueur ou chauffeur)
// ─────────────────────────────────────────────────────────────────────────────

class TransportMissionModel {
  final String id;
  final String reference;
  final String status;
  final String transportMode;
  final String? providerStatus;
  final DateTime? slotStartsAt;

  final String registrationNumber;
  final String vehicleBrand;
  final String vehicleModel;
  final String? vehicleColor;

  final String? clientName;
  final String? clientPhone;
  final double? clientLat;
  final double? clientLng;
  final String? clientAddress;

  final String? centerName;
  final String? centerAddress;

  final DateTime? providerEnRouteAt;
  final DateTime? providerPickedUpAt;
  final DateTime? providerDeliveredAt;
  final DateTime? providerReturnStartedAt;
  final DateTime? providerReturnedAt;
  final DateTime? providerCompletedAt;

  const TransportMissionModel({
    required this.id,
    required this.reference,
    required this.status,
    required this.transportMode,
    this.providerStatus,
    this.slotStartsAt,
    required this.registrationNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    this.vehicleColor,
    this.clientName,
    this.clientPhone,
    this.clientLat,
    this.clientLng,
    this.clientAddress,
    this.centerName,
    this.centerAddress,
    this.providerEnRouteAt,
    this.providerPickedUpAt,
    this.providerDeliveredAt,
    this.providerReturnStartedAt,
    this.providerReturnedAt,
    this.providerCompletedAt,
  });

  factory TransportMissionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return TransportMissionModel(
      id:              json['id'] as String,
      reference:       json['reference'] as String,
      status:          json['status'] as String? ?? 'pending',
      transportMode:   json['transport_mode'] as String? ?? 'tow',
      providerStatus:  json['provider_status'] as String?,
      slotStartsAt:    parseDate(json['slot_starts_at']),
      registrationNumber: json['registration_number'] as String? ?? '',
      vehicleBrand:    json['vehicle_brand'] as String? ?? '',
      vehicleModel:    json['vehicle_model'] as String? ?? '',
      vehicleColor:    json['vehicle_color'] as String?,
      clientName:      json['client_name'] as String?,
      clientPhone:     json['client_phone'] as String?,
      clientLat:       parseDouble(json['client_lat']),
      clientLng:       parseDouble(json['client_lng']),
      clientAddress:   json['client_address'] as String?,
      centerName:      json['center_name'] as String?,
      centerAddress:   json['center_address'] as String?,
      providerEnRouteAt:       parseDate(json['provider_en_route_at']),
      providerPickedUpAt:      parseDate(json['provider_picked_up_at']),
      providerDeliveredAt:     parseDate(json['provider_delivered_at']),
      providerReturnStartedAt: parseDate(json['provider_return_started_at']),
      providerReturnedAt:      parseDate(json['provider_returned_at']),
      providerCompletedAt:     parseDate(json['provider_completed_at']),
    );
  }

  String get slotTime {
    if (slotStartsAt == null) return '--:--';
    final h = slotStartsAt!.hour.toString().padLeft(2, '0');
    final m = slotStartsAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get stepLabel {
    switch (providerStatus) {
      case 'pending':
        return 'À démarrer';
      case 'en_route_to_client':
        return 'En route vers client';
      case 'picked_up':
        return 'Véhicule récupéré';
      case 'delivered_to_center':
        return 'Livré au centre';
      case 'return_en_route':
        return 'Retour en cours';
      case 'delivered_to_client':
        return 'Livré au client';
      default:
        return 'En attente';
    }
  }

  String get nextActionLabel {
    switch (providerStatus) {
      case 'pending':
        return 'Démarrer la mission';
      case 'en_route_to_client':
        return 'Scanner QR chez client';
      case 'picked_up':
        return 'Scanner QR au centre';
      case 'delivered_to_center':
        return 'Démarrer le retour';
      case 'return_en_route':
        return 'Scanner QR chez client (retour)';
      case 'delivered_to_client':
        return 'Terminé';
      default:
        return 'Continuer';
    }
  }
}
