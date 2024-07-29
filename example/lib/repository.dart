import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:interactive_chart/interactive_chart.dart';

class BinanceRepository {
  Future<List<CandleData>> fetchCandleDatas(
      {required String symbol, required String interval, int? endTime}) async {
    final uri = Uri.parse(
        "https://api.moogarden.io/api/market/v2/history?symbol=BTC%2FUSDT&resolution=15&size=2000&from=1720662017000&to=1721958017000");
    print("url===${uri}");
    final res = await http.get(uri);
    print("res===${(jsonDecode(res.body) as List<dynamic>).length}");

     var list = <CandleData>[];
    // res.body.forEach((item) {
    //   list.add(KLineEntity.fromCustom(
    //       open: double.parse(item[1].toString()),
    //       close: double.parse(item[4].toString()),
    //       time: item[0],
    //       high: double.parse(item[2].toString()),
    //       low: double.parse(item[3].toString()),
    //       vol: double.parse(item[5].toString())));
    // });
    (jsonDecode(res.body) as List<dynamic>)
        .forEach((item){
          //print("e===${}");
          try{

            list.add(CandleData(
              timestamp: item[0],
              open: double.parse(item[1].toString()),
              high: double.parse(item[2].toString()),
              low:double.parse(item[3].toString()),
              close: double.parse(item[4].toString()),
              volume: double.parse(item[5].toString())));

          }catch(err){
            print("error===${err}");

          }
    });
    // List<CandleData> list=(jsonDecode(res.body) as List<dynamic>)
    //     .map((e) => CandleData.fromJson(e))
    //     .toList();
     print("list===${list.length}");

    return list.reversed.toList();
  }

  Future<List<String>> fetchSymbols() async {
    final uri = Uri.parse("https://api.binance.com/api/v3/ticker/price");
    final res = await http.get(uri);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => e["symbol"] as String)
        .toList();
  }


}
