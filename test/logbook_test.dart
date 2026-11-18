import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/json_rpc.dart';

import 'package:flutterchain/config.dart';
import 'package:flutterchain/models.dart';
import 'package:flutterchain/util/error_message.dart';
import 'package:flutterchain/util/format.dart';

void main() {
  final someone = EthereumAddress.fromHex('0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed');

  group('revert reasons', () {
    test('read from the RPC message', () {
      expect(revertReason('execution reverted: Alat sedang dipinjam', null), 'Alat sedang dipinjam');
    });

    test('decoded from Error(string) data when the message has no reason', () {
      // Error("Bukan admin")
      const data = '0x08c379a0'
          '0000000000000000000000000000000000000000000000000000000000000020'
          '000000000000000000000000000000000000000000000000000000000000000b'
          '42756b616e2061646d696e000000000000000000000000000000000000000000';
      expect(revertReason('execution reverted', data), 'Bukan admin');
      expect(revertReason('execution reverted', {'data': data}), 'Bukan admin');
    });

    test('not a revert', () {
      expect(revertReason('insufficient funds for gas * price + value', null), isNull);
    });

    test('error messages are readable', () {
      expect(errorMessage(const RPCError(3, 'execution reverted: Sudah dikembalikan', null)),
          'Ditolak kontrak: Sudah dikembalikan');
      expect(errorMessage(const RPCError(-32000, 'insufficient funds for gas * price + value', null)),
          contains('Saldo Sepolia ETH tidak cukup'));
    });
  });

  group('loans', () {
    final borrowed = DateTime(2026, 11, 19, 8);
    final open = Peminjaman(id: 0, alatId: 1, peminjam: someone, waktuPinjam: borrowed);
    final returned = Peminjaman(
        id: 1, alatId: 1, peminjam: someone, waktuPinjam: borrowed, waktuKembali: DateTime(2026, 11, 19, 9));

    test('overdue only when open past the limit', () {
      const limit = Duration(hours: 24);
      expect(open.terlambat(limit, DateTime(2026, 11, 19, 20)), isFalse);
      expect(open.terlambat(limit, DateTime(2026, 11, 20, 9)), isTrue);
      expect(returned.terlambat(limit, DateTime(2026, 12, 1)), isFalse);
    });

    test('ownership compares wallet addresses', () {
      expect(open.milik(someone), isTrue);
      expect(open.milik(null), isFalse);
    });

    test('block.timestamp converts to local time', () {
      expect(dariTimestamp(BigInt.from(0)), DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('connection input', () {
    test('accepts an https URL and an address, trimming spaces', () {
      final c = Connection.parse(' https://ethereum-sepolia-rpc.publicnode.com ', ' ${someone.eip55With0x} ');
      expect(c.rpcUrl, 'https://ethereum-sepolia-rpc.publicnode.com');
      expect(c.contract, someone);
    });

    test('rejects non-https or empty RPC URLs', () {
      for (final url in ['', 'http://localhost:8545', 'https://', 'sepolia']) {
        expect(() => Connection.parse(url, someone.eip55With0x), throwsFormatException, reason: url);
      }
    });

    test('rejects malformed addresses', () {
      for (final address in ['', '0x123', 'bukan alamat']) {
        expect(() => Connection.parse('https://rpc.example', address), throwsFormatException, reason: address);
      }
    });
  });

  group('formatting', () {
    test('short address keeps 0x and the EIP-55 checksum case', () {
      expect(shortAddress(someone), '0x5aAe…eAed');
    });

    test('durations', () {
      expect(formatDuration(const Duration(minutes: 5)), '5 menit');
      expect(formatDuration(const Duration(hours: 3, minutes: 7)), '3 jam 7 menit');
      expect(formatDuration(const Duration(days: 2, hours: 5)), '2 hari 5 jam');
    });

    test('ether amounts', () {
      expect(formatEth(EtherAmount.fromBigInt(EtherUnit.gwei, BigInt.from(1500000)), digits: 4), '0.0015 ETH');
    });
  });
}
