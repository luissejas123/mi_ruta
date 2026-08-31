import 'package:flutter/material.dart';

import '../domain/services/gtfs_schedule_service.dart';
import 'datasources/gtfs_datasource.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  final service =
      GtfsScheduleService(
        GtfsDatasource(),
      );


  final result =
      await service.getUpcomingDepartures(
        stopId: '13760954848',
        now: DateTime(2026,8,5,6,0),
      );


  print('===== PROXIMAS SALIDAS =====');


  for(final r in result){

    print(r);

  }


}