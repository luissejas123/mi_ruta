import 'package:mi_ruta/features/driver/data/datasources/driver_income_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_income_entry.dart';

class DriverIncomeService {
  final DriverIncomeDatasource _datasource;

  DriverIncomeService({required DriverIncomeDatasource datasource})
    : _datasource = datasource;

  Future<List<DriverIncomeEntry>> getIncomeHistory(String driverId) =>
      _datasource.getIncomeHistory(driverId);

  double getTotalIncome(List<DriverIncomeEntry> entries) =>
      entries.fold(0.0, (total, entry) => total + entry.amount);
}
