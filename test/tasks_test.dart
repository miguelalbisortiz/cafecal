import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/tasks.dart';

/// La tecla `cosechar` es la que enciende el campo de kilos del jornal
/// (Tanda 2). Vive en una constante para que la pantalla y la derivación no
/// repitan el literal y se separen sin que nadie lo note.
void main() {
  group('La tecla de «Cosechar»', () {
    test('kTaskCosechar vale cosechar y aparece una sola vez en el catálogo', () {
      expect(kTaskCosechar, 'cosechar');
      expect(farmTasks.where((t) => t.key == kTaskCosechar), hasLength(1));
    });

    test('taskByKey(kTaskCosechar) devuelve la labor Cosechar', () {
      final t = taskByKey(kTaskCosechar);
      expect(t, isNotNull);
      expect(t!.name, 'Cosechar');
    });
  });
}
