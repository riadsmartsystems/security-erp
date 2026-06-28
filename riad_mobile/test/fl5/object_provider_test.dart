import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/object/providers/object_provider.dart';

void main() {
  group('objectListProvider', () {
    test('returns list of objects', () async {
      final container = ProviderContainer(overrides: [
        objectListProvider.overrideWith(
          (ref) async => [
            {'id': 'obj-1', 'name': 'Обʼєкт 1', 'address': 'Вул. Тестова, 1', 'customer_name': 'ТОВ Тест'},
            {'id': 'obj-2', 'name': 'Обʼєкт 2', 'address': 'Вул. Тестова, 2', 'customer_name': 'ФОП Іваненко'},
          ],
        ),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(objectListProvider.future);
      expect(result.length, 2);
      expect(result[0]['id'], 'obj-1');
      expect(result[1]['name'], 'Обʼєкт 2');
    });

    test('returns empty list when no objects', () async {
      final container = ProviderContainer(overrides: [
        objectListProvider.overrideWith((ref) async => []),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(objectListProvider.future);
      expect(result, isEmpty);
    });
  });

  group('objectByIdProvider', () {
    test('returns object map when found', () async {
      final container = ProviderContainer(overrides: [
        objectByIdProvider('obj-1').overrideWith(
          (ref) async => {
            'id': 'obj-1',
            'name': 'Склад Петровського',
            'address': 'Вул. Промислова, 5',
            'customer_name': 'ТОВ Склад',
            'map_kind': 'floor',
            'system_type': 'CCTV',
            'technical_notes': 'IP камери',
          },
        ),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(objectByIdProvider('obj-1').future);
      expect(result, isNotNull);
      expect(result!['name'], 'Склад Петровського');
      expect(result['map_kind'], 'floor');
    });

    test('returns null when object not found', () async {
      final container = ProviderContainer(overrides: [
        objectByIdProvider('missing').overrideWith((ref) async => null),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(objectByIdProvider('missing').future);
      expect(result, isNull);
    });

    test('includes financial fields when server sends them (engineer DTO)', () async {
      final container = ProviderContainer(overrides: [
        objectByIdProvider('obj-eng').overrideWith(
          (ref) async => {
            'id': 'obj-eng',
            'name': 'Офіс',
            'address': 'Центр',
            'customer_name': 'ТОВ Офіс',
            'map_kind': 'territory',
            'financial_summary': 'UAH 120,000',
          },
        ),
      ]);
      addTearDown(container.dispose);

      final obj = await container.read(objectByIdProvider('obj-eng').future);
      expect(obj!.containsKey('financial_summary'), isTrue);
    });

    test('no financial fields when server omits them (installer DTO)', () async {
      final container = ProviderContainer(overrides: [
        objectByIdProvider('obj-installer').overrideWith(
          (ref) async => {
            'id': 'obj-installer',
            'name': 'Магазин',
            'address': 'вул. Ринкова',
            'customer_name': 'ФОП Коваль',
            'map_kind': 'floor',
            'system_type': 'Alarm',
          },
        ),
      ]);
      addTearDown(container.dispose);

      final obj = await container.read(objectByIdProvider('obj-installer').future);
      expect(obj!.containsKey('financial_summary'), isFalse);
    });
  });
}
