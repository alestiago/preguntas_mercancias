import 'package:flutter_test/flutter_test.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../matchers/matchers.dart';

void main() {
  test('parses an example txt question', () async {
    const source = '''
COD: 1A01001
PREGUNTA: Si a una empresa de transportes, propietaria de unas naves industriales, el arrendatario le adeuda varias mensualidades de renta, ¿cómo debe proceder para cobrarlas?
A: Formulando la oportuna reclamación ante la correspondiente Junta Arbitral de Transportes.
B: Formulando la oportuna reclamación ante los Tribunales de Justicia.
C: Formulando la oportuna reclamación en la Asociación de Propietarios e Inquilinos.
D: Cerrando las naves y solicitando la subasta judicial de los bienes contenidos en ellas.
SOLUCION: B
NORMA: RD 1211/1990, art. 6
''';

    final questions = await const QuestionTxtParser().parse(source);

    expect(questions, [
      isAQuestion(
        code: '1A01001',
        section: '1A',
        correctOption: QuestionOption.b,
        answers: hasLength(4),
        correctAnswer: isAQuestionAnswer(
          text:
              'Formulando la oportuna reclamación ante los Tribunales de Justicia.',
        ),
        norma: 'RD 1211/1990, art. 6',
      ),
    ]);
  });
}
