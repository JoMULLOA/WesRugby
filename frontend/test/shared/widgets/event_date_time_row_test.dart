import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/shared/widgets/event/event_date_time_row.dart';

void main() {
  group('EventDateTimeRow', () {
    testWidgets('renders formatted date and time using local timezone', (
      tester,
    ) async {
      final startAtUtc = DateTime.utc(2024, 5, 10, 15, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: EventDateTimeRow(startAtUtc))),
        ),
      );

      final local = startAtUtc.toLocal();
      final expectedDate = DateFormat('dd/MM/yyyy').format(local);
      final expectedTime = DateFormat('HH:mm').format(local);

      expect(find.text(expectedDate), findsOneWidget);
      expect(find.text(expectedTime), findsOneWidget);
      expect(find.text('•'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('renders nothing when startAt is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: EventDateTimeRow(null))),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsNothing);
      expect(find.byIcon(Icons.access_time), findsNothing);
      expect(find.textContaining('/'), findsNothing);
    });
  });
}
