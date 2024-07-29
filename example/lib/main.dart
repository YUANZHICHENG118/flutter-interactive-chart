import 'dart:async';

import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import './repository.dart';
import 'mock_data.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late  List<CandleData> _data=MockDataTesla.candles;
  bool loading=false;
  bool _darkMode = false;
  bool _showAverage = false;
  bool _line = false;
  BinanceRepository repository = BinanceRepository();
  late StreamSubscription subscription;
  late bool subInit=false;
  late Timer _timer;
  @override
  void initState() {
    // fetchSymbols().then((value) {
    //   symbols = value;
    //   if (symbols.isNotEmpty) fetchCandles(symbols[0], currentInterval);
    // });
    fetchCandles("","");
    // _timer = Timer.periodic(Duration(seconds: 5), (timer) {
    //   fetchCandles("","");
    //
    // });

    super.initState();
  }

  Future<void> fetchCandles(String symbol, String interval) async {
    // close current channel if exists

    // clear last candle list
    setState(() {
      _data = [];
      loading=true;
    });

    try {
      // load candles info
      final data =
      await repository.fetchCandleDatas(symbol: symbol, interval: interval);
      // connect to binance stream
      setState(() {
        _data = data;
        loading=false;

      });
    } catch (e) {
      // handle error
      return;
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Interactive Chart Demo"),
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
            IconButton(
              icon: Icon(
                _showAverage ? Icons.show_chart : Icons.bar_chart_outlined,
              ),
              onPressed: () {
                setState(() => _showAverage = !_showAverage);
                if (_showAverage) {
                  _computeTrendLines();
                  _line=true;
                } else {
                  _removeTrendLines();
                  _line=false;
                }
              },
            ),


          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(24.0),
          child: Column(children: [
            if(loading) const Expanded(
              child:  Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            )
            else  SizedBox(height:300,child: InteractiveChart(
              line: _line,
              /** Only [candles] is required */
              candles: _data,
              /** Uncomment the following for examples on optional parameters */
              /** Example styling */
              style: ChartStyle(
                priceGainColor:const Color(0xFF00D889) ,
                priceLossColor:const Color(0xFFFA2256) ,
                volumeColor: const Color(0xFF00D889),
                trendLineStyles: [
                  Paint()
                    ..strokeWidth = 1.0
                    ..strokeCap = StrokeCap.round
                    ..color = Color(0xFF30E0A1),
                  Paint()
                    ..strokeWidth =1.0
                    ..strokeCap = StrokeCap.round
                    ..color =  Color(0xFFF7931A),
                  Paint()
                    ..strokeWidth =1.0
                    ..strokeCap = StrokeCap.round
                    ..color = Color(0xFFBD47FB),
                ],
                priceGridLineColor: Color(0xFFF5F5F5),
                // priceLabelStyle: TextStyle(color: Colors.blue[200]),
                 timeLabelStyle: TextStyle(color: Colors.black38,fontSize: 12),
                selectionHighlightColor: Colors.red.withOpacity(0.2),
                // overlayBackgroundColor: Colors.red[900]!.withOpacity(0.6),
                // overlayTextStyle: TextStyle(color: Colors.red[100]),
                // timeLabelHeight: 32,
                volumeHeightFactor: 0.2, // volume area is 20% of total height
              ),
              /** Customize axis labels */
              // timeLabel: (timestamp, visibleDataCount) => "📅",
              // priceLabel: (price) => "${price.round()} 💎",
              /** Customize overlay (tap and hold to see it)
               ** Or return an empty object to disable overlay info. */
              // overlayInfo: (candle) => {
              //   "💎": "🤚    ",
              //   "Hi": "${candle.high?.toStringAsFixed(2)}",
              //   "Lo": "${candle.low?.toStringAsFixed(2)}",
              // },
              /** Callbacks */
              onTap: (candle) => print("user tapped on $candle"),
              onCandleResize: (width) => print("each candle is $width wide"),
            ),)
          ],),
        ),
      ),
    );
  }

  _computeTrendLines() {
    final ma5 = CandleData.computeMA(_data, 7);
    final ma10 = CandleData.computeMA(_data, 10);
    final ma20 = CandleData.computeMA(_data, 20);
    for (int i = 0; i < _data.length; i++) {
      _data[i].trends = [ma5[i], ma10[i], ma20[i]];
    }
  }





  _removeTrendLines() {
    for (final data in _data) {
      data.trends = [];
    }
  }
}
