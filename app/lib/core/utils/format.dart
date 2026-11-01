/// Formatea una duración como m:ss o h:mm:ss.
String formatDuration(Duration d) {
  final hours = d.inHours;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  return '${d.inMinutes}:$seconds';
}
