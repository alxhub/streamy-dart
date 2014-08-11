library streamy.generated.proto.test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:streamy/streamy.dart';
import 'proto_client.dart';
import 'import_test_client.dart' as itc;

main() {
  group('ProtoTest', () {
    var f = new Foo()
      ..name = 'Foo Test Object'
      ..other = [
        new Bar()..name = 'Bar #1',
        new Bar()..name = 'Bar #2'
      ];
    var m = new Marshaller();
    test('Serializes with tag numbers', () {
      var fm = m.marshalFoo(f);
      expect(fm, containsPair('2', 'Foo Test Object'));
      expect(fm, contains('3'));
      var others = fm['3'];
      expect(others, isList);
      expect(others, hasLength(2));
      expect(others[0], containsPair('2', 'Bar #1'));
      expect(others[1], containsPair('2', 'Bar #2'));
    });
    test('Serializer pass-through works as intended', () {
      var m = new Marshaller();
      var f2 = m.unmarshalFoo(m.marshalFoo(f));
      expect(f2.name, 'Foo Test Object');
      expect(f2.other, isList);
      expect(f2.other, hasLength(2));
      expect(f2.other[0].name, 'Bar #1');
      expect(f2.other[1].name, 'Bar #2');
    });
    test('Typed fields are generated correctly.', () {
      
    });
    test('Serializes dependency', () {
      f.other[0].other = new itc.Imported()
        ..from = 'Original test';
      var fm = m.marshalFoo(f);
      expect(fm, contains('3'));
      var other = fm['3'];
      expect(other, isList);
      expect(other, hasLength(2));
      var first = other.first;
      expect(first, contains('3'));
      var imported = first['3'];
      expect(imported, containsPair('1', 'Original test'));
    });
  });
}