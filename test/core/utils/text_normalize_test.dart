import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/core/utils/text_normalize.dart';

void main() {
  test('strips Spanish accents and lowercases', () {
    expect(normalizeForSearch('Jalón'), 'jalon');
    expect(normalizeForSearch('jalon'), 'jalon');
    expect(normalizeForSearch('Peso Muerto Rumano'), 'peso muerto rumano');
    expect(normalizeForSearch('Bíceps'), 'biceps');
    expect(normalizeForSearch('Piñón'), 'pinon');
  });

  test('leaves already-plain text unchanged besides case', () {
    expect(normalizeForSearch('Curl con Barra'), 'curl con barra');
  });
}
