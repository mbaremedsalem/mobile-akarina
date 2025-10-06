
import 'package:akarina/data/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class ReservationCalendar extends StatefulWidget {
  final List<dynamic> reservations;
  final Function(DateTime, DateTime)? onDateSelect;

  const ReservationCalendar({
    super.key,
    required this.reservations,
    this.onDateSelect,
  });

  @override
  State<ReservationCalendar> createState() => _ReservationCalendarState();
}

class _ReservationCalendarState extends State<ReservationCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _rangeStart = null;
              _rangeEnd = null;
            });
          },
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _rangeStart = start;
              _rangeEnd = end;
              _focusedDay = focusedDay;
              _selectedDay = null;
            });
            
            if (widget.onDateSelect != null && start != null && end != null) {
              widget.onDateSelect!(start, end);
            }
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            // Style pour les jours réservés
            disabledTextStyle: const TextStyle(color: Colors.red),
            // Style pour les jours disponibles
            defaultTextStyle: const TextStyle(color: Colors.green),
            weekendTextStyle: const TextStyle(color: Colors.blue),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDay(day,getTranslated(context, "Disponible")!, Colors.green);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDay(day, getTranslated(context, "Aujourd'hui")!, Colors.blue);
            },
            selectedBuilder: (context, day, focusedDay) {
              return _buildDay(day, getTranslated(context, "Sélectionné")!, Colors.orange);
            },
            disabledBuilder: (context, day, focusedDay) {
              return _buildDay(day, getTranslated(context, "Réservé")!, Colors.red);
            },
          ),
          enabledDayPredicate: (day) {
            // Jours disponibles (non réservés)
            return !_isDateReserved(day);
          },
        ),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        if (_rangeStart != null && _rangeEnd != null)
          Text(
            '${getTranslated(context, "Période sélectionnée")}: ${DateFormat('dd/MM/yyyy').format(_rangeStart!)} - ${DateFormat('dd/MM/yyyy').format(_rangeEnd!)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildDay(DateTime day, String status, Color color) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.day.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(getTranslated(context, "Disponible")!, Colors.green),
        _buildLegendItem(getTranslated(context, "Réservé")!, Colors.red),
        _buildLegendItem(getTranslated(context, "Aujourd'hui")!, Colors.blue),
        _buildLegendItem(getTranslated(context, "Sélectionné")!, Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color.withOpacity(0.3),
          margin: const EdgeInsets.only(right: 4),
        ),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }

  bool _isDateReserved(DateTime date) {
    for (var reservation in widget.reservations) {
      final startDate = DateTime.parse(reservation['date_debut']);
      final endDate = DateTime.parse(reservation['date_fin']);
      
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }
}

 