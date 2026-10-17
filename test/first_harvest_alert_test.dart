import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/l10n/generated/app_localizations.dart';
import 'package:mi_cafetal/l10n/strings.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/farm_alert.dart';
import 'package:mi_cafetal/models/harvest.dart';
import 'package:mi_cafetal/services/alert_service.dart';

/// AppLocalizations en español para las pruebas de mensajes.
AppLocalizations get _es => stringsFor('es');

/// C7 — pasó la fecha de primera cosecha que **él mismo** puso y no llegó
/// ninguna cosecha.
///
/// Dos reglas gobiernan esta alerta:
///
/// 1. **manda lo que puso él** — no se compara contra ninguna tabla;
/// 2. **se apaga sola** — la app no tiene descarte de alertas, así que un
///    aviso que no muere se aprende a ignorar: al primer cosecha o a los
///    12 meses de la fecha.
void main() {
  final now = DateTime(2026, 6, 15);

  Crop lote({String id = 'cafe', DateTime? primera}) => Crop(
        id: id,
        name: 'Café',
        icon: '☕',
        color: '#6D4C41',
        primerCosechaEsperada: primera,
      );

  List<FarmAlert> correr({
    List<Crop>? crops,
    List<Harvest> harvests = const [],
  }) =>
      AlertService(now: now).evaluate(
        const [],
        crops ?? [lote(primera: DateTime(2026, 3, 1))],
        _es,
        harvests: harvests,
      );

  List<FarmAlert> avisos(List<FarmAlert> todos) =>
      todos.where((a) => a.rule == AlertRule.firstHarvestOverdue).toList();

  group('Regla 13 — ya debería estar rindiendo', () {
    test('dispara cuando pasó la fecha y no hay cosecha', () {
      final r = avisos(correr());
      expect(r, hasLength(1));
      expect(r.single.severity, AlertSeverity.warning);
      expect(r.single.title, 'Café ya debería estar rindiendo');
    });

    test('el mensaje cita la fecha que puso él', () {
      expect(
        avisos(correr()).single.message,
        'Estimaste la primera cosecha de Café para el 01/03/2026 '
        'y hasta ahora no registraste ninguna cosecha.',
      );
    });

    test('la salida manda a la venta, que es la puerta que existe', () {
      expect(
        avisos(correr()).single.suggestion,
        'Revisá el cultivo: si cambió algo o la fecha ya no va, editala. '
        'Si ya vendiste, anotá esa venta con los kilos y el dinero que te '
        'pagaron: con esos kilos la app ya sabe que cosechaste y este aviso '
        'desaparece.',
      );
    });

    test('no dispara si nunca puso fecha (null → oculto)', () {
      expect(avisos(correr(crops: [lote()])), isEmpty);
    });

    test('no dispara si la fecha todavía no pasó', () {
      expect(avisos(correr(crops: [lote(primera: DateTime(2027, 1, 1))])),
          isEmpty);
    });

    test('no dispara si ese cultivo ya cosechó', () {
      final r = correr(
        harvests: [
          Harvest(
            id: 'h1',
            cropId: 'cafe',
            date: DateTime(2026, 5, 1),
            amount: 40,
          ),
        ],
      );
      expect(avisos(r), isEmpty,
          reason: 'manda lo que cosechó, no lo que estimó');
    });

    test('una cosecha de OTRO cultivo no apaga la de este', () {
      final r = correr(
        harvests: [
          Harvest(
            id: 'h1',
            cropId: 'otro',
            date: DateTime(2026, 5, 1),
            amount: 40,
          ),
        ],
      );
      expect(avisos(r), hasLength(1));
    });
  });

  group('el tope de 12 meses', () {
    test('a los 11 meses sigue avisando', () {
      final r = correr(crops: [lote(primera: DateTime(2025, 7, 15))]);
      expect(avisos(r), hasLength(1));
    });

    test('al cumplir 12 meses exactos sigue avisando', () {
      final r = correr(crops: [lote(primera: DateTime(2025, 6, 15))]);
      expect(avisos(r), hasLength(1));
    });

    test('a los 13 meses ya no avisa', () {
      final r = correr(crops: [lote(primera: DateTime(2025, 5, 15))]);
      expect(
        avisos(r),
        isEmpty,
        reason: 'a esa altura deja de ser un aviso y se vuelve ruido; '
            'el dato sigue estando en la lista de cultivos',
      );
    });
  });

  group('no afecta a nadie más', () {
    test('solo el cultivo con fecha genera alerta', () {
      final r = correr(crops: [
        lote(id: 'cafe', primera: DateTime(2026, 3, 1)),
        lote(id: 'platano'),
        lote(id: 'mango', primera: DateTime(2027, 2, 1)),
      ]);
      expect(avisos(r), hasLength(1));
    });

    test('cada cultivo atrasado tiene la suya', () {
      final r = correr(crops: [
        lote(id: 'cafe', primera: DateTime(2026, 3, 1)),
        lote(id: 'platano', primera: DateTime(2026, 1, 1)),
      ]);
      expect(avisos(r), hasLength(2));
      expect(avisos(r).map((a) => a.id), {
        'first_harvest_overdue_cafe',
        'first_harvest_overdue_platano',
      });
    });

    test('sin cultivos no hay nada que avisar', () {
      expect(avisos(correr(crops: const [])), isEmpty);
    });
  });
}
