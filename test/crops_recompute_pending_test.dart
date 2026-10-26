import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cafetal/models/crop.dart';
import 'package:mi_cafetal/models/sowing.dart';
import 'package:mi_cafetal/providers/transaction_provider.dart';
import 'package:mi_cafetal/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cropId = 'c1';
const _sowingId = '22222222-2222-4222-8222-222222222222';

Future<TransactionProvider> _provider(Crop crop) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  await store.saveCrops([crop]);
  return TransactionProvider(store);
}

Crop _crop({required int livePlants, required double areaHa}) => Crop(
      id: _cropId,
      name: 'Café',
      livePlants: livePlants,
      areaHa: areaHa,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('un pull que no cambia los números no marca el cultivo para subir',
      () async {
    final p = await _provider(_crop(livePlants: 300, areaHa: 1.0));
    p.mergeRemoteSowings([
      Sowing(
        id: _sowingId,
        cropId: _cropId,
        date: DateTime(2026, 3, 1),
        plants: 300,
        areaHa: 1.0,
      ),
    ]);

    expect(p.crops.single.livePlants, 300);
    expect(p.crops.single.pendingSync, isFalse,
        reason: 'no cambió nada: no hay nada que subir');
  });

  test('un pull que cambia los números sí marca el cultivo para subir',
      () async {
    final p = await _provider(_crop(livePlants: 300, areaHa: 1.0));
    p.mergeRemoteSowings([
      Sowing(
        id: _sowingId,
        cropId: _cropId,
        date: DateTime(2026, 3, 1),
        plants: 500,
        areaHa: 2.0,
      ),
    ]);

    expect(p.crops.single.livePlants, 500);
    expect(p.crops.single.areaHa, 2.0);
    expect(p.crops.single.pendingSync, isTrue);
  });
}
