import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';

class DaySelector extends StatelessWidget {
  final List<ScheduleDay> scheduleDays;

  /// Дата, которую мы сейчас выбрали
  final DateTime? selectedDate;

  /// Колбэк, вызывается при нажатии
  final ValueChanged<DateTime> onDateSelected;

  const DaySelector({
    Key? key,
    required this.scheduleDays,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Можно дополнительно отсортировать здесь, если не сделали в HomePage
    final sortedDays = [...scheduleDays];
    sortedDays.sort((a, b) => a.date.compareTo(b.date));

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedDays.length,
        itemBuilder: (context, index) {
          final day = sortedDays[index];
          final date = day.date;
          // Форматируем дату. Пример: "Пн, 05 Янв"
          final formatted = DateFormat('EEE, dd MMM', 'ru').format(date);

          // Проверяем, выбрана ли эта дата
          final bool isSelected = selectedDate != null &&
              date.year == selectedDate!.year &&
              date.month == selectedDate!.month &&
              date.day == selectedDate!.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  formatted,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    decoration:
                    isSelected ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: Theme.of(context).colorScheme.primary,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
