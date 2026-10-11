/// E3 · labores de la obra del día.
///
/// Lista cerrada a propósito. Texto libre no se puede agrupar: "Descolgar
/// café", "descolgar" y "Descolgar el café" serían tres renglones distintos
/// en la planilla y ésta dejaría de servir para leer.
///
/// "Otra…" es la válvula de escape: cuando se elige, lo que escriba el
/// usuario se guarda **tal cual en `task`**, así que `task` termina siendo
/// o una tecla conocida o texto libre. Agrupar sigue funcionando igual: lo
/// que está en la lista agrupa por tecla, lo que no agrupa con lo idéntico.
const String kTaskOther = 'otra';

class FarmTask {
  final String key;
  final String name;
  final String icon;

  const FarmTask({required this.key, required this.name, required this.icon});
}

/// Ordenado como se trabaja: primero lo del cafetal, luego la cerca.
const List<FarmTask> farmTasks = [
  FarmTask(key: 'descolgar', name: 'Descolgar', icon: '🌿'),
  FarmTask(key: 'abonar', name: 'Abonar', icon: '🧪'),
  FarmTask(key: 'cosechar', name: 'Cosechar', icon: '🧺'),
  FarmTask(key: 'deshierbar', name: 'Deshierbar', icon: '🌾'),
  FarmTask(key: 'aplicar', name: 'Aplicar', icon: '💊'),
  FarmTask(key: 'cerca_camino', name: 'Cerca y camino', icon: '🚧'),
  FarmTask(key: kTaskOther, name: 'Otra…', icon: '✏️'),
];

/// La labor con esa tecla, o null si no está en la lista.
///
/// null también para datos viejos (anteriores a E3) o para texto libre que
/// guardó "Otra…": no es un error, es otra cosa.
FarmTask? taskByKey(String? key) {
  if (key == null) return null;
  for (final t in farmTasks) {
    if (t.key == key) return t;
  }
  return null;
}

/// ¿Esta `task` es texto libre en vez de una tecla de la lista?
bool isFreeTask(String? task) => task != null && taskByKey(task) == null;

/// Nombre de la labor para mostrar.
///
/// Lo de la lista usa su nombre (que ya es el del dropdown); lo que no
/// está, el texto que guardó el usuario. Sin labor → ''.
String taskLabel(String? task) {
  if (task == null) return '';
  final known = taskByKey(task);
  return known == null ? task : known.name;
}

/// Icono de la labor. Lo desconocido (texto libre, dato viejo) lleva el de
/// "Otra…", que es lo que es.
String taskIcon(String? task) {
  final known = taskByKey(task);
  if (known != null) return known.icon;
  for (final t in farmTasks) {
    if (t.key == kTaskOther) return t.icon;
  }
  return '';
}
