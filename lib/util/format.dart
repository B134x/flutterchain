import 'package:wallet/wallet.dart';

String shortAddress(EthereumAddress address) {
  final s = address.eip55With0x;
  return '${s.substring(0, 6)}…${s.substring(s.length - 4)}';
}

String shortHash(String hash) =>
    hash.length <= 20 ? hash : '${hash.substring(0, 10)}…${hash.substring(hash.length - 8)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Local time as dd/MM/yyyy HH:mm.
String formatTime(DateTime t) =>
    '${_two(t.day)}/${_two(t.month)}/${t.year} ${_two(t.hour)}:${_two(t.minute)}';

String formatDuration(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} hari ${d.inHours % 24} jam';
  if (d.inHours >= 1) return '${d.inHours} jam ${d.inMinutes % 60} menit';
  return '${d.inMinutes} menit';
}

/// ETH with [digits] decimals. Amounts too small for that, like Sepolia gas fees, switch to gwei or wei
/// instead of rounding to zero.
String formatEth(EtherAmount amount, {int digits = 5}) {
  final wei = amount.getInWei;
  if (wei == BigInt.zero || wei >= BigInt.from(10).pow(18 - digits)) {
    return '${amount.getValueInUnit(EtherUnit.ether).toStringAsFixed(digits)} ETH';
  }
  if (wei >= BigInt.from(10).pow(9)) {
    return '${amount.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} gwei';
  }
  return '$wei wei';
}
