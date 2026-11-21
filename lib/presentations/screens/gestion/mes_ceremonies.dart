import 'package:akarina/data/data_providers/indisponibilite_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/bien.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Préfixe du motif des périodes créées automatiquement par le backend quand
/// une réservation est confirmée (transactions/signals.py).
const _kPrefixeReservation = 'Loue via transaction';

DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

String _titreBien(BuildContext context, Bien b) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  return ar && b.titreAr.trim().isNotEmpty ? b.titreAr : b.titre;
}

/// Liste des maisons de cérémonie dont l'utilisateur connecté est
/// gestionnaire (affectées depuis l'admin), pour gérer leurs dates.
class MesCeremoniesScreen extends StatefulWidget {
  final String token;

  const MesCeremoniesScreen({super.key, required this.token});

  @override
  State<MesCeremoniesScreen> createState() => _MesCeremoniesScreenState();
}

class _MesCeremoniesScreenState extends State<MesCeremoniesScreen> {
  final IndisponibiliteService _service = IndisponibiliteService();
  List<Bien>? _biens;
  String? _erreur;

  String _t(String key) => getTranslated(context, key) ?? key;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final biens = await _service.fetchMesBiens(widget.token, typeBien: 'ceremonie');
      if (!mounted) return;
      setState(() => _biens = biens);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t("Mes maisons de cérémonie"), style: const TextStyle(color: kBlackColor)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackColor),
      ),
      body: RefreshIndicator(onRefresh: _charger, color: pcolor, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.error_outline, size: 44, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(_erreur!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: _charger, child: Text(_t("Réessayer"))),
          ),
        ],
      );
    }
    if (_biens == null) {
      return Center(child: CircularProgressIndicator(color: pcolor));
    }
    if (_biens!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.celebration_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            _t("Aucune maison de cérémonie ne vous est affectée."),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _biens!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildBienCard(_biens![i]),
    );
  }

  Widget _buildBienCard(Bien b) {
    final lieu = [b.quartierNom, b.villeNom].where((s) => s.trim().isNotEmpty).join(', ');
    final photo = b.photoPrincipale;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GestionCalendrierScreen(token: widget.token, bien: b)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: photo != null && photo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _photoVide(),
                        )
                      : _photoVide(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titreBien(context, b),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (lieu.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(lieu, style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 15, color: pcolor),
                        const SizedBox(width: 4),
                        Text(
                          _t("Gérer les dates"),
                          style: TextStyle(fontSize: 12.5, color: pcolor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoVide() => Container(
        color: pcolor.withOpacity(0.08),
        child: Icon(Icons.celebration_rounded, color: pcolor),
      );
}

/// Calendrier d'un bien, éditable par son gestionnaire : sélectionner un
/// jour ou une plage pour la bloquer, toucher un jour bloqué pour modifier
/// ou débloquer la période.
class GestionCalendrierScreen extends StatefulWidget {
  final String token;
  final Bien bien;

  const GestionCalendrierScreen({super.key, required this.token, required this.bien});

  @override
  State<GestionCalendrierScreen> createState() => _GestionCalendrierScreenState();
}

class _GestionCalendrierScreenState extends State<GestionCalendrierScreen> {
  final IndisponibiliteService _service = IndisponibiliteService();
  final DateFormat _format = DateFormat('dd/MM/yyyy');

  List<PeriodeIndisponibilite> _periodes = [];
  bool _loading = true;
  bool _envoi = false;
  bool _afficherPassees = false;
  String? _erreur;

  DateTime _focusedDay = _jour(DateTime.now());
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  String _t(String key) => getTranslated(context, key) ?? key;

  DateTime get _aujourdhui => _jour(DateTime.now());

  bool get _mensuel => widget.bien.uniteprix == 'mois';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final periodes = await _service.fetchPourBien(widget.bien.id);
      if (!mounted) return;
      setState(() {
        _periodes = periodes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = '$e';
        _loading = false;
      });
    }
  }

  PeriodeIndisponibilite? _periodeDu(DateTime day) {
    for (final p in _periodes) {
      if (p.contient(day)) return p;
    }
    return null;
  }

  void _snack(String message, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: erreur ? Colors.red.shade700 : null,
      ),
    );
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focused) {
    _focusedDay = focused;
    if (start != null && end == null) {
      final periode = _periodeDu(start);
      if (periode != null) {
        setState(() {
          _rangeStart = null;
          _rangeEnd = null;
        });
        _ouvrirPeriode(periode);
        return;
      }
    }
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
    });
  }

  /// Bloque la sélection courante (un jour, ou une plage).
  Future<void> _bloquerSelection() async {
    final debut = _rangeStart;
    if (debut == null) return;
    final fin = _rangeEnd ?? debut;

    final chevauche = _periodes.where((p) => !p.fin.isBefore(debut) && !p.debut.isAfter(fin));
    if (chevauche.isNotEmpty) {
      _snack(_t("Cette période chevauche une période déjà bloquée."), erreur: true);
      return;
    }

    final motif = await _demanderMotif(debut, fin);
    if (motif == null || !mounted) return;

    setState(() => _envoi = true);
    try {
      await _service.creer(widget.token, bienId: widget.bien.id, debut: debut, fin: fin, motif: motif);
      if (!mounted) return;
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });
      _snack(_t("Période bloquée"));
      await _charger();
    } catch (e) {
      if (mounted) _snack('$e', erreur: true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Renvoie le motif saisi, ou null si l'utilisateur annule.
  Future<String?> _demanderMotif(DateTime debut, DateTime fin) {
    final controller = TextEditingController();
    final libelle = debut == fin
        ? _format.format(debut)
        : '${_format.format(debut)} → ${_format.format(fin)}';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t("Bloquer ces dates")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: _t("Motif (optionnel)"),
                hintText: _t("Ex : mariage, travaux..."),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t("Annuler"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pcolor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(_t("Bloquer")),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirPeriode(PeriodeIndisponibilite p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _PeriodeSheet(
        periode: p,
        format: _format,
        t: _t,
        onSave: (debut, fin, motif) async {
          final autres = _periodes.where((o) => o.id != p.id && !o.fin.isBefore(debut) && !o.debut.isAfter(fin));
          if (autres.isNotEmpty) {
            _snack(_t("Cette période chevauche une période déjà bloquée."), erreur: true);
            return false;
          }
          try {
            await _service.modifier(widget.token, p.id!, debut: debut, fin: fin, motif: motif);
            if (mounted) _snack(_t("Période modifiée"));
            await _charger();
            return true;
          } catch (e) {
            if (mounted) _snack('$e', erreur: true);
            return false;
          }
        },
        onDelete: () async {
          final ok = await _confirmerSuppression(p);
          if (!ok) return false;
          try {
            await _service.supprimer(widget.token, p.id!);
            if (mounted) _snack(_t("Dates débloquées"));
            await _charger();
            return true;
          } catch (e) {
            if (mounted) _snack('$e', erreur: true);
            return false;
          }
        },
      ),
    );
  }

  Future<bool> _confirmerSuppression(PeriodeIndisponibilite p) async {
    final reservation = p.motif.startsWith(_kPrefixeReservation);
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t("Débloquer ces dates ?")),
        content: Text(
          reservation
              ? _t("Cette période correspond à une réservation confirmée. La débloquer rendra ces dates de nouveau réservables.")
              : '${_format.format(p.debut)} → ${_format.format(p.fin)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t("Annuler"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t("Débloquer")),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titreBien(context, widget.bien),
          style: const TextStyle(color: kBlackColor, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackColor),
      ),
      body: _mensuel ? _buildMensuel() : _buildCalendrier(),
      bottomNavigationBar: _rangeStart == null ? null : _buildBarreSelection(),
    );
  }

  Widget _buildMensuel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          _t("Ce bien est loué au mois : il n'a pas de calendrier jour par jour."),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildCalendrier() {
    final today = _aujourdhui;
    final firstDay = DateTime(today.year, today.month - 12, 1);
    final lastDay = DateTime(today.year + 2, today.month + 1, 0);

    final aVenir = _periodes.where((p) => !p.fin.isBefore(today)).toList();
    final passees = _periodes.where((p) => p.fin.isBefore(today)).toList().reversed.toList();

    return RefreshIndicator(
      onRefresh: _charger,
      color: pcolor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: pcolor.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded, color: pcolor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t("Touchez un jour (ou un premier puis un dernier jour) pour bloquer des dates. Touchez un jour en rouge pour le modifier ou le débloquer."),
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(minHeight: 2, color: pcolor, backgroundColor: pcolor.withOpacity(0.1)),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 10),
            Text(_erreur!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TableCalendar(
              locale: Localizations.localeOf(context).languageCode,
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: _focusedDay.isBefore(firstDay)
                  ? firstDay
                  : (_focusedDay.isAfter(lastDay) ? lastDay : _focusedDay),
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: ''},
              availableGestures: AvailableGestures.horizontalSwipe,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              onRangeSelected: _onRangeSelected,
              onPageChanged: (day) => _focusedDay = day,
              // Les jours passés ne se bloquent pas, sauf s'ils font partie
              // d'une période existante (pour pouvoir la consulter/corriger).
              enabledDayPredicate: (day) => !_jour(day).isBefore(today) || _periodeDu(day) != null,
              rowHeight: 46,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                rangeHighlightColor: pcolor.withOpacity(0.18),
                rangeStartDecoration: BoxDecoration(color: pcolor, shape: BoxShape.circle),
                rangeEndDecoration: BoxDecoration(color: pcolor, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: pcolor, width: 1.5),
                ),
                todayTextStyle: TextStyle(color: pcolor, fontWeight: FontWeight.w700),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) => _celluleBloquee(day, today),
                todayBuilder: (context, day, _) => _celluleBloquee(day, today),
                disabledBuilder: (context, day, _) => _celluleBloquee(day, today),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legende(Colors.red.shade400, _t("Bloqué")),
              const SizedBox(width: 16),
              _legende(pcolor, _t("Sélection")),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _t("Périodes bloquées à venir"),
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (aVenir.isEmpty && !_loading)
            Text(_t("Aucune date bloquée : la maison est disponible."), style: TextStyle(color: Colors.grey[600]))
          else
            ...aVenir.map(_carteperiode),
          if (passees.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _afficherPassees = !_afficherPassees),
              icon: Icon(_afficherPassees ? Icons.expand_less : Icons.expand_more),
              label: Text('${_t("Périodes passées")} (${passees.length})'),
            ),
            if (_afficherPassees) ...passees.map(_carteperiode),
          ],
        ],
      ),
    );
  }

  /// Rendu d'un jour bloqué (fond rouge) ; null = rendu par défaut.
  Widget? _celluleBloquee(DateTime day, DateTime today) {
    if (_periodeDu(day) == null) return null;
    final passe = _jour(day).isBefore(today);
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: passe ? Colors.red.shade50 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: passe ? Colors.red.shade200 : Colors.red.shade700,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.lineThrough,
        ),
      ),
    );
  }

  Widget _legende(Color color, String label) => Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      );

  Widget _carteperiode(PeriodeIndisponibilite p) {
    final reservation = p.motif.startsWith(_kPrefixeReservation);
    final dates = p.debut == p.fin ? _format.format(p.debut) : '${_format.format(p.debut)} → ${_format.format(p.fin)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _ouvrirPeriode(p),
        leading: CircleAvatar(
          backgroundColor: reservation ? Colors.orange.shade50 : Colors.red.shade50,
          child: Icon(
            reservation ? Icons.event_available_rounded : Icons.block_rounded,
            color: reservation ? Colors.orange.shade700 : Colors.red.shade400,
            size: 20,
          ),
        ),
        title: Text(dates, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          [
            '${p.nbJours} ${_t(p.nbJours > 1 ? "jours" : "jour")}',
            if (reservation) _t("Réservation") else if (p.motif.isNotEmpty) p.motif,
          ].join(' · '),
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildBarreSelection() {
    final debut = _rangeStart!;
    final fin = _rangeEnd ?? debut;
    final nb = fin.difference(debut).inDays + 1;
    final libelle = debut == fin
        ? _format.format(debut)
        : '${_format.format(debut)} → ${_format.format(fin)}';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('$nb ${_t(nb > 1 ? "jours" : "jour")}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            TextButton(
              onPressed: _envoi
                  ? null
                  : () => setState(() {
                        _rangeStart = null;
                        _rangeEnd = null;
                      }),
              child: Text(_t("Annuler")),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              onPressed: _envoi ? null : _bloquerSelection,
              icon: _envoi
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.block_rounded, size: 18),
              label: Text(_t("Bloquer")),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de détail d'une période : modifier dates/motif ou la débloquer.
/// onSave/onDelete renvoient true si l'opération a réussi (ferme la feuille).
class _PeriodeSheet extends StatefulWidget {
  final PeriodeIndisponibilite periode;
  final DateFormat format;
  final String Function(String) t;
  final Future<bool> Function(DateTime debut, DateTime fin, String motif) onSave;
  final Future<bool> Function() onDelete;

  const _PeriodeSheet({
    required this.periode,
    required this.format,
    required this.t,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_PeriodeSheet> createState() => _PeriodeSheetState();
}

class _PeriodeSheetState extends State<_PeriodeSheet> {
  late DateTime _debut = widget.periode.debut;
  late DateTime _fin = widget.periode.fin;
  late final TextEditingController _motif = TextEditingController(text: widget.periode.motif);
  bool _busy = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _choisirDates() async {
    final today = _jour(DateTime.now());
    final first = _debut.isBefore(today) ? _debut : today;
    final range = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: DateTime(today.year + 2, 12, 31),
      initialDateRange: DateTimeRange(start: _debut, end: _fin),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: pcolor)),
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() {
      _debut = _jour(range.start);
      _fin = _jour(range.end);
    });
  }

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(t("Période bloquée"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _choisirDates,
            icon: Icon(Icons.date_range_rounded, color: pcolor),
            label: Text(
              _debut == _fin
                  ? widget.format.format(_debut)
                  : '${widget.format.format(_debut)} → ${widget.format.format(_fin)}',
              style: const TextStyle(color: kBlackColor, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motif,
            maxLength: 150,
            decoration: InputDecoration(labelText: t("Motif (optionnel)")),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(widget.onDelete),
                  icon: const Icon(Icons.lock_open_rounded, color: Colors.red, size: 18),
                  label: Text(t("Débloquer"), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _run(() => widget.onSave(_debut, _fin, _motif.text.trim())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pcolor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t("Enregistrer")),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
