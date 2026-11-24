import 'package:bse/screens/buy_sell/absa_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbsaCard.isValidNumber', () {
    test('accepts the Visa test card from the API docs', () {
      expect(AbsaCard.isValidNumber('4111111111111111'), isTrue);
    });

    test('rejects a single-digit typo', () {
      expect(AbsaCard.isValidNumber('4111111111111112'), isFalse);
    });

    test('rejects numbers that are too short or too long', () {
      expect(AbsaCard.isValidNumber('411111111111'), isFalse);
      expect(AbsaCard.isValidNumber('41111111111111111111'), isFalse);
    });
  });

  group('AbsaCard.brand', () {
    test('identifies the major schemes', () {
      expect(AbsaCard.brand('4111111111111111'), 'VISA');
      expect(AbsaCard.brand('5555555555554444'), 'MASTERCARD');
      expect(AbsaCard.brand('2223003122003222'), 'MASTERCARD');
      expect(AbsaCard.brand('378282246310005'), 'AMEX');
      expect(AbsaCard.brand('6011111111111117'), '');
    });

    test('Amex takes a 4-digit code, everything else 3', () {
      expect(AbsaCard.cvvLength('378282246310005'), 4);
      expect(AbsaCard.cvvLength('4111111111111111'), 3);
    });
  });

  group('AbsaCard.isValidExpiry', () {
    final now = DateTime.now();

    test('accepts a date in the future', () {
      expect(AbsaCard.isValidExpiry('12', '${now.year + 5}'), isTrue);
    });

    test('accepts the current month (cards last to month end)', () {
      expect(
        AbsaCard.isValidExpiry(
            now.month.toString().padLeft(2, '0'), '${now.year}'),
        isTrue,
      );
    });

    test('rejects a date in the past', () {
      expect(AbsaCard.isValidExpiry('01', '${now.year - 1}'), isFalse);
    });

    test('rejects an impossible month and a 2-digit year', () {
      expect(AbsaCard.isValidExpiry('13', '${now.year + 1}'), isFalse);
      expect(AbsaCard.isValidExpiry('00', '${now.year + 1}'), isFalse);
      expect(AbsaCard.isValidExpiry('12', '31'), isFalse);
    });
  });

  group('AbsaResult.title', () {
    test('maps the documented response codes', () {
      expect(
          const AbsaResult(success: true, message: '', responseCode: 0).title,
          'Deposit Successful');
      expect(
          const AbsaResult(success: false, message: '', responseCode: 402)
              .title,
          'Card Declined');
      expect(
          const AbsaResult(success: false, message: '', responseCode: 300)
              .title,
          'Invalid Request');
      expect(
          const AbsaResult(success: false, message: '', responseCode: 403)
              .title,
          'Broker Not Linked');
      expect(
          const AbsaResult(success: false, message: '', responseCode: 5).title,
          'Deposit Failed');
    });
  });
}
