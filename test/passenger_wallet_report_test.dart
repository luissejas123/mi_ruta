import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_wallet_report.dart';

void main() {
  group('PassengerWalletReport.fromLedger', () {
    test('aggregates completed movements by type and route and reconciles', () {
      final report = PassengerWalletReport.fromLedger(
        currentBalance: 22,
        transactions: [
          {'transaction_type': 'top_up', 'amount': 20, 'status': 'completed'},
          {'transaction_type': 'recharge', 'amount': 10, 'status': 'approved'},
          {
            'transaction_type': 'trip_payment',
            'amount': -5,
            'trip_id': 'trip-1',
            'status': 'completed',
          },
          {
            'transaction_type': 'trip_payment',
            'amount': 5,
            'trip_id': 'trip-2',
            'status': 'completed',
          },
          {'transaction_type': 'refund', 'amount': 2, 'status': 'completed'},
          {'transaction_type': 'top_up', 'amount': 100, 'status': 'pending'},
        ],
        trips: [
          {
            'id': 'trip-1',
            'route_ref': '108',
            'route_name': 'MiniBus 108',
            'status': 'completed',
            'payment_status': 'paid',
          },
          {
            'id': 'trip-2',
            'route_ref': '108',
            'route_name': 'MiniBus 108',
            'status': 'cancelled',
            'payment_status': 'refunded',
          },
        ],
      );

      expect(report.income, 30);
      expect(report.payments, 10);
      expect(report.refunds, 2);
      expect(report.paymentCount, 2);
      expect(report.cancellationCount, 1);
      expect(report.routeCharges, [
        const RouteChargeSummary(
          route: 'MiniBus 108',
          amount: 10,
          paymentCount: 2,
        ),
      ]);
      expect(report.calculatedBalance, 22);
      expect(report.isReconciled, isTrue);
    });

    test(
      'reports an unreconciled balance instead of hiding the difference',
      () {
        final report = PassengerWalletReport.fromLedger(
          currentBalance: 15,
          transactions: [
            {'transaction_type': 'top_up', 'amount': 10},
          ],
          trips: const [],
        );

        expect(report.calculatedBalance, 10);
        expect(report.reconciliationDifference, 5);
        expect(report.isReconciled, isFalse);
      },
    );
  });
}
