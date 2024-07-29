import 'package:interactive_chart/interactive_chart.dart';

class MockDataTesla {
  static const List<dynamic> _rawData = [
    // (Price data for Tesla Inc, taken from Yahoo Finance)
    // timestamp, open, high, low, close, volume
    [1555939800, 53.80, 53.94, 52.50, 52.55, 60735500],
    [1556026200, 52.03, 53.12, 51.15, 52.78, 54719500],
    [1556112600, 52.77, 53.06, 51.60, 51.73, 53637500],

  ];

  static List<CandleData> get candles => _rawData
      .map((row) => CandleData(
            timestamp: row[0] * 1000,
            open: row[1]?.toDouble(),
            high: row[2]?.toDouble(),
            low: row[3]?.toDouble(),
            close: row[4]?.toDouble(),
            volume: row[5]?.toDouble(),
          ))
      .toList();
}
