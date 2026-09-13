import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class DriverEvent extends Equatable {
  const DriverEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyVehicleApplication extends DriverEvent {
  final String userId;
  const LoadMyVehicleApplication(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SubmitVehicleApplication extends DriverEvent {
  final String userId;
  final String plate;
  final String vehicleType;
  final String lineNumber;
  final String internalNumber;
  final String brand;
  final String model;
  final String color;
  final int passengerCapacity;
  final File soatFile;
  final File vehicleInspectionFile;
  final File driverLicenseFile;
  final File municipalOperationCardFile;
  final File ruatFile;

  const SubmitVehicleApplication({
    required this.userId,
    required this.plate,
    required this.vehicleType,
    required this.lineNumber,
    required this.internalNumber,
    required this.brand,
    required this.model,
    required this.color,
    required this.passengerCapacity,
    required this.soatFile,
    required this.vehicleInspectionFile,
    required this.driverLicenseFile,
    required this.municipalOperationCardFile,
    required this.ruatFile,
  });

  @override
  List<Object?> get props => [
        userId,
        plate,
        vehicleType,
        lineNumber,
        internalNumber,
        brand,
        model,
        color,
        passengerCapacity,
        soatFile,
        vehicleInspectionFile,
        driverLicenseFile,
        municipalOperationCardFile,
        ruatFile,
      ];
}

class ActivateDriverMode extends DriverEvent {
  final String userId;
  const ActivateDriverMode(this.userId);
  @override
  List<Object?> get props => [userId];
}

class DeactivateDriverMode extends DriverEvent {
  final String userId;
  const DeactivateDriverMode(this.userId);
  @override
  List<Object?> get props => [userId];
}
