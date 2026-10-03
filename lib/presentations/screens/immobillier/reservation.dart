import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Calendrier de sélection d'une période de location.
///
/// Les jours déjà réservés sont barrés et non sélectionnables ; une période
/// qui chevauche une réservation existante est refusée.
class ReservationCalendar extends StatefulWidget {
  final List<dynamic> reservations;

  /// Appelé quand une période complète (début + fin) est choisie.
  final Function(DateTime, DateTime)? onDateSelect;

  /// Appelé à chaque changement de sélection, y compris quand elle est
  /// incomplète (seulement le début) ou effacée.
  final void Function(DateTime? start, DateTime? end)? onRangeChanged;

  const ReservationCalendar({
    super.key,
    required this.reservations,
    this.onDateSelect,
    this.onRangeChanged,
  });

  @override
  State<ReservationCalendar> createState() => _ReservationCalendarState();
}

class _ReservationCalendarState extends State<ReservationCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  String _t(String key) => getTranslated(context, key) ?? key;

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    if (start != null && end != null && _rangeContainsReserved(start, end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Cette période contient des jours déjà réservés')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _rangeStart = start;
        _rangeEnd = null;
        _focusedDay = focusedDay;
      });
      widget.onRangeChanged?.call(start, null);
      return;
    }

    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      _focusedDay = focusedDay;
    });
    widget.onRangeChanged?.call(start, end);
    if (start != null && end != null) widget.onDateSelect?.call(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        TableCalendar(
          locale: Localizations.localeOf(context).languageCode,
          firstDay: firstDay,
          lastDay: firstDay.add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: ''},
          startingDayOfWeek: StartingDayOfWeek.monday,
          // Sans ce mode, table_calendar n'émet jamais onRangeSelected au
          // simple tap : la sélection début + fin ne fonctionnerait pas.
          rangeSelectionMode: RangeSelectionMode.toggledOn,
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          onRangeSelected: _onRangeSelected,
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          enabledDayPredicate: (day) => !_isDateReserved(day),
          rowHeight: 46,
          daysOfWeekHeight: 28,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kBlackColor),
            headerPadding: const EdgeInsets.only(bottom: 12),
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            leftChevronIcon: _chevron(Icons.chevron_left_rounded),
            rightChevronIcon: _chevron(Icons.chevron_right_rounded),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
            weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.symmetric(vertical: 3),
            rangeHighlightColor: pcolor.withOpacity(0.12),
            rangeHighlightScale: 0.82,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) => _dayCell(day),
            todayBuilder: (context, day, _) => _dayCell(day, isToday: true),
            withinRangeBuilder: (context, day, _) => _dayCell(day, inRange: true),
            rangeStartBuilder: (context, day, _) => _dayCell(day, isEdge: true),
            rangeEndBuilder: (context, day, _) => _dayCell(day, isEdge: true),
            disabledBuilder: (context, day, _) => _dayCell(day, reserved: _isDateReserved(day), past: true),
          ),
        ),
        const SizedBox(height: 14),
        _buildLegend(),
      ],
    );
  }

  Widget _chevron(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: kBlackColor),
    );
  }

  Widget _dayCell(
    DateTime day, {
    bool isToday = false,
    bool inRange = false,
    bool isEdge = false,
    bool reserved = false,
    bool past = false,
  }) {
    Color textColor = kBlackColor;
    Color? background;
    BoxBorder? border;
    TextDecoration? decoration;

    if (isEdge) {
      background = pcolor;
      textColor = Colors.white;
    } else if (reserved) {
      background = Colors.red.withOpacity(0.07);
      textColor = Colors.red[300]!;
      decoration = TextDecoration.lineThrough;
    } else if (past) {
      textColor = Colors.grey[300]!;
    } else if (inRange) {
      textColor = pcolor;
    } else if (isToday) {
      border = Border.all(color: pcolor, width: 1.5);
      textColor = pcolor;
    }

    return Center(
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: border,
          boxShadow: isEdge
              ? [BoxShadow(color: pcolor.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isEdge || isToday || inRange ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
            decoration: decoration,
            decorationColor: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem(_t('Disponible'), dot: Colors.white, border: Colors.grey[400]),
        _legendItem(_t('Réservé'), dot: Colors.red[200]!),
        _legendItem(_t('Sélectionné'), dot: pcolor),
        _legendItem(_t("Aujourd'hui"), dot: Colors.white, border: pcolor),
      ],
    );
  }

  Widget _legendItem(String text, {required Color dot, Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dot,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11.5, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  bool _rangeContainsReserved(DateTime start, DateTime end) {
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (_isDateReserved(d)) return true;
    }
    return false;
  }

  bool _isDateReserved(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    for (var reservation in widget.reservations) {
      final startDate = DateTime.tryParse('${reservation['date_debut']}');
      final endDate = DateTime.tryParse('${reservation['date_fin']}');
      if (startDate == null || endDate == null) continue;
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      if (!day.isBefore(start) && !day.isAfter(end)) return true;
    }
    return false;
  }
}
