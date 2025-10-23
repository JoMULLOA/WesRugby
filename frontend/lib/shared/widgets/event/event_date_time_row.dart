import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/core/config/colors.dart';

class EventDateTimeRow extends StatelessWidget {
  final DateTime? startAt;

  EventDateTimeRow(this.startAt, {super.key});

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    if (startAt == null) return const SizedBox.shrink();

    final local = startAt!.toLocal();
    final dateText = _dateFormat.format(local);
    final timeText = _timeFormat.format(local);

    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final textStyle = (baseStyle ?? const TextStyle()).copyWith(
      fontSize: baseStyle?.fontSize ?? 14,
      fontWeight: FontWeight.w600,
      color: WessexColors.midnightNavy,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today,
          size: 16,
          color: WessexColors.midnightNavy,
        ),
        const SizedBox(width: 8),
        Text(dateText, style: textStyle),
        const SizedBox(width: 6),
        Text('•', style: textStyle.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        const Icon(
          Icons.access_time,
          size: 16,
          color: WessexColors.midnightNavy,
        ),
        const SizedBox(width: 8),
        Text(timeText, style: textStyle),
      ],
    );
  }
}
