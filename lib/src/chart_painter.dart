import 'dart:math';

import 'package:flutter/material.dart';

import 'candle_data.dart';
import 'constant/view_constants.dart';
import 'painter_params.dart';

typedef TimeLabelGetter = String Function(int timestamp, int visibleDataCount);
typedef PriceLabelGetter = String Function(double price);
typedef OverlayInfoGetter = Map<String, String> Function(CandleData candle);

class ChartPainter extends CustomPainter {
  final PainterParams params;
  final TimeLabelGetter getTimeLabel;
  final PriceLabelGetter getPriceLabel;
  final OverlayInfoGetter getOverlayInfo;
  final bool line;
  final List<SecondaryState> secondaryState;

  ChartPainter({
    required this.params,
    required this.getTimeLabel,
    required this.getPriceLabel,
    required this.getOverlayInfo,
    required this.line,
    required this.secondaryState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw time labels (dates) & price labels
    _drawTimeLabels(canvas, params);
    _drawPriceGridAndLabels(canvas, params);

    // Draw prices, volumes & trend line
    canvas.save();
    canvas.clipRect(Offset.zero & Size(params.chartWidth, params.chartHeight));
    // canvas.drawRect(
    //   // apply yellow tint to clipped area (for debugging)
    //   Offset.zero & Size(params.chartWidth, params.chartHeight),
    //   Paint()..color = Colors.yellow[100]!,
    // );
    canvas.translate(params.xShift, 0);
    for (int i = 0; i < params.candles.length; i++) {
      _drawSingleDay(canvas, params, i);
    }

    canvas.restore();

    // Draw tap highlight & overlay
    if (params.tapPosition != null) {
      if (params.tapPosition!.dx < params.chartWidth) {
        _drawTapHighlightAndOverlay(canvas, params);
      }
    }
  }

  void _drawTimeLabels(canvas, PainterParams params) {
    // We draw one time label per 90 pixels of screen width
    final lineCount = params.chartWidth ~/ 90;
    final gap = 1 / (lineCount + 1);
    for (int i = 1; i <= lineCount; i++) {
      double x = i * gap * params.chartWidth;
      final index = params.getCandleIndexFromOffset(x);
      if (index < params.candles.length) {
        final candle = params.candles[index];
        final visibleDataCount = params.candles.length;
        final timeTp = TextPainter(
          text: TextSpan(
            text: getTimeLabel(candle.timestamp, visibleDataCount),
            style: params.style.timeLabelStyle,
          ),
        )
          ..textDirection = TextDirection.ltr
          ..layout();

        // Align texts towards vertical bottom
        final topPadding = params.style.timeLabelHeight - timeTp.height;
        timeTp.paint(
          canvas,
          Offset(x - timeTp.width / 2, params.chartHeight + topPadding),
        );
      }
    }
  }

  void _drawPriceGridAndLabels(canvas, PainterParams params) {
    [0.0, 0.25, 0.5, 0.75, 1.0]
        .map((v) => ((params.maxPrice - params.minPrice) * v) + params.minPrice)
        .forEach((y) {
      canvas.drawLine(
        Offset(0, params.fitPrice(y)),
        Offset(params.chartWidth, params.fitPrice(y)),
        Paint()
          ..strokeWidth = 0.5
          ..color = params.style.priceGridLineColor,
      );
      final priceTp = TextPainter(
        text: TextSpan(
          text: getPriceLabel(y),
          style: params.style.priceLabelStyle,
        ),
      )
        ..textDirection = TextDirection.ltr
        ..layout();
      priceTp.paint(
          canvas,
          Offset(
            params.chartWidth + 4,
            params.fitPrice(y) - priceTp.height / 2,
          ));
    });
  }

  void _drawSingleDay(canvas, PainterParams params, int i) {
    final candle = params.candles[i];
    final x = i * params.candleWidth;
    final thickWidth = max(params.candleWidth * 0.8, 0.8);
    final thinWidth = max(params.candleWidth * 0.2, 0.2);
    // Draw price bar
    final open = candle.open;
    final close = candle.close;
    final high = candle.high;
    final low = candle.low;
    if (open != null && close != null && !line) {
      final color = open > close
          ? params.style.priceLossColor
          : params.style.priceGainColor;
      canvas.drawLine(
        Offset(x, params.fitPrice(open)),
        Offset(x, params.fitPrice(close)),
        Paint()
          ..strokeWidth = thickWidth
          ..color = color,
      );
      if (high != null && low != null) {
        canvas.drawLine(
          Offset(x, params.fitPrice(high)),
          Offset(x, params.fitPrice(low)),
          Paint()
            ..strokeWidth = thinWidth
            ..color = color,
        );
      }
    }

    if (line) {
      // 绘制最新价折线图
      final latestPriceLinePaint = Paint()
        ..strokeWidth = 2.0
        ..color = Colors.blue;
      final previousX = (i - 1) * params.candleWidth;
      final currentX = i * params.candleWidth;
      final previousPrice = params.candles.at(i - 1);
      final currentPrice = params.candles[i];
      if (previousPrice != null && currentPrice != null) {
        canvas.drawLine(
          Offset(previousX, params.fitPrice(previousPrice.close ?? 0)),
          Offset(currentX, params.fitPrice(currentPrice.close ?? 0)),
          latestPriceLinePaint,
        );
      }
    }

    // Draw trend line
    for (int j = 0; j < candle.trends.length; j++) {
      final trendLinePaint = params.style.trendLineStyles.at(j) ??
          (Paint()
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round
            ..color = Colors.blue);

      final pt = candle.trends.at(j); // current data point
      final prevPt = params.candles
          .at(i - 1)
          ?.trends
          .at(j);
      if (pt != null && prevPt != null) {
        canvas.drawLine(
          Offset(x - params.candleWidth, params.fitPrice(prevPt)),
          Offset(x, params.fitPrice(pt)),
          trendLinePaint,
        );
      }
      if (i == 0) {
        // In the front, draw an extra line connecting to out-of-window data
        if (pt != null && params.leadingTrends?.at(j) != null) {
          canvas.drawLine(
            Offset(x - params.candleWidth,
                params.fitPrice(params.leadingTrends!.at(j)!)),
            Offset(x, params.fitPrice(pt)),
            trendLinePaint,
          );
        }
      } else if (i == params.candles.length - 1) {
        // At the end, draw an extra line connecting to out-of-window data
        if (pt != null && params.trailingTrends?.at(j) != null) {
          canvas.drawLine(
            Offset(x, params.fitPrice(pt)),
            Offset(
              x + params.candleWidth,
              params.fitPrice(params.trailingTrends!.at(j)!),
            ),
            trendLinePaint,
          );
        }
      }
    }


    // Draw volume bar
      final volume = candle.volume;
      if (volume != null && open != null && close != null) {
        final color = open > close
            ? params.style.priceLossColor
            : params.style.priceGainColor;
        canvas.drawLine(
          Offset(x, params.chartHeight),
          Offset(x, params.fitVolume(volume)),
          Paint()
            ..strokeWidth = thickWidth
            ..color = color,
        );
      }


        // 绘制指标
        _drawIndicators(canvas,params,secondaryState);


  }

  void _drawTapHighlightAndOverlay(canvas, PainterParams params) {
    final pos = params.tapPosition!;
    final i = params.getCandleIndexFromOffset(pos.dx);
    final candle = params.candles[i];
    canvas.save();
    canvas.translate(params.xShift, 0.0);
    // Draw highlight bar (selection box)
    canvas.drawLine(
        Offset(i * params.candleWidth, 0.0),
        Offset(i * params.candleWidth, params.chartHeight),
        Paint()
          ..strokeWidth = max(params.candleWidth * 0.88, 1.0)
          ..color = params.style.selectionHighlightColor);
    canvas.restore();
    // Draw info pane
    _drawTapInfoOverlay(canvas, params, candle);

  }

  void _drawTapInfoOverlay(canvas, PainterParams params, CandleData candle) {
    final xGap = 8.0;
    final yGap = 4.0;

    TextPainter makeTP(String text) => TextPainter(
          text: TextSpan(
            text: text,
            style: params.style.overlayTextStyle,
          ),
        )
          ..textDirection = TextDirection.ltr
          ..layout();

    final info = getOverlayInfo(candle);
    if (info.isEmpty) return;
    final labels = info.keys.map((text) => makeTP(text)).toList();
    final values = info.values.map((text) => makeTP(text)).toList();

    final labelsMaxWidth = labels.map((tp) => tp.width).reduce(max);
    final valuesMaxWidth = values.map((tp) => tp.width).reduce(max);
    final panelWidth = labelsMaxWidth + valuesMaxWidth + xGap * 3;
    final panelHeight = max(
          labels.map((tp) => tp.height).reduce((a, b) => a + b),
          values.map((tp) => tp.height).reduce((a, b) => a + b),
        ) +
        yGap * (values.length + 1);

    // Shift the canvas, so the overlay panel can appear near touch position.
    canvas.save();
    final pos = params.tapPosition!;
    final fingerSize = 32.0; // leave some margin around user's finger
    double dx, dy;
    assert(params.size.width >= panelWidth, "Overlay panel is too wide.");
    if (pos.dx <= params.size.width / 2) {
      // If user touches the left-half of the screen,
      // we show the overlay panel near finger touch position, on the right.
      dx = pos.dx + fingerSize;
    } else {
      // Otherwise we show panel on the left of the finger touch position.
      dx = pos.dx - panelWidth - fingerSize;
    }
    dx = dx.clamp(0, params.size.width - panelWidth);
    dy = pos.dy - panelHeight - fingerSize;
    if (dy < 0) dy = 0.0;
    canvas.translate(dx, dy);

    // Draw the background for overlay panel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(panelWidth, panelHeight),
          Radius.circular(8),
        ),
        Paint()..color = params.style.overlayBackgroundColor);

    // Draw texts
    var y = 0.0;
    for (int i = 0; i < labels.length; i++) {
      y += yGap;
      final rowHeight = max(labels[i].height, values[i].height);
      // Draw labels (left align, vertical center)
      final labelY = y + (rowHeight - labels[i].height) / 2; // vertical center
      labels[i].paint(canvas, Offset(xGap, labelY));

      // Draw values (right align, vertical center)
      final leading = valuesMaxWidth - values[i].width; // right align
      final valueY = y + (rowHeight - values[i].height) / 2; // vertical center
      values[i].paint(
        canvas,
        Offset(labelsMaxWidth + xGap * 2 + leading, valueY),
      );
      y += rowHeight;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) =>
      params.shouldRepaint(oldDelegate.params);
}

extension ElementAtOrNull<E> on List<E> {
  E? at(int index) {
    if (index < 0 || index >= length) return null;
    return elementAt(index);
  }
}

void _drawIndicators(Canvas canvas, PainterParams params, List<SecondaryState> indicators) {
  final double totalHeight = params.chartHeight;
  final double margin = 30.0; // 各个指标之间的间隔
  final int numberOfIndicators = indicators.length;
  final double indicatorHeight = 50;

  double previousBottom = totalHeight+10;


  for (var indicator in indicators) {
    switch (indicator) {
      // case SecondaryState.VOL:
      // // 绘制成交量指标
      //   _drawVolumeIndicator(canvas, params, previousBottom, indicatorHeight);
      //   break;
      case SecondaryState.KDJ:
      // 绘制KDJ指标
        _drawKDJIndicator(canvas, params, previousBottom, indicatorHeight);
        break;
      case SecondaryState.MACD:
      // 绘制MACD指标
        _drawMACDIndicator(canvas, params, previousBottom, indicatorHeight);
        break;
      case SecondaryState.RSI:
      // 绘制RSI指标
        _drawRSIIndicator(canvas, params, previousBottom, indicatorHeight);
        break;
    }
    previousBottom += indicatorHeight + margin;
  }
}

void _drawRSIIndicator(Canvas canvas, PainterParams params,double previousBottom, double height) {
  final double rsiMaxHeight = height; // 最大高度限制为50px
  final double rsiTop = previousBottom + 20;
  final double rsiBottom = rsiTop + rsiMaxHeight+50;

  final Paint rsiPaint = Paint()
    ..color = Colors.purple
    ..strokeWidth = 1.0;

  double? latestRSI;

  for (int i = 1; i < params.candles.length; i++) {
    final candle = params.candles[i];
    final previousCandle = params.candles[i - 1];

    if (candle.rsi1 != null) {
      final double x1 = (i - 1) * params.candleWidth;
      final double x2 = i * params.candleWidth;

      if (previousCandle.rsi1 != null) {
        final double rsiY1 = rsiBottom - (previousCandle.rsi1! / 100) * rsiMaxHeight;
        final double rsiY2 = rsiBottom - (candle.rsi1! / 100) * rsiMaxHeight;

        canvas.drawLine(Offset(x1, rsiY1), Offset(x2, rsiY2), rsiPaint);
      }

      latestRSI = candle.rsi1;
    }
  }

  if (latestRSI != null) {
    final textPainterRSI = TextPainter(
      text: TextSpan(
        text: 'RSI: ${latestRSI.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.purple, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainterRSI.paint(canvas, Offset(5, rsiTop + 5));
  }
}

void _drawKDJIndicator(Canvas canvas, PainterParams params,double previousBottom, double height) {
  final double kdjMaxHeight = height; // 最大高度限制为100px
  final double kdjTop =previousBottom + 20;
  final double kdjBottom = kdjTop + kdjMaxHeight+20;

  final Paint kPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 1.0;

  final Paint dPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 1.0;

  final Paint jPaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 1.0;

  double maxAbsoluteValue = 0.0;
  for (final candle in params.candles) {
    if (candle.k != null && candle.d != null && candle.j != null) {
      maxAbsoluteValue = max(maxAbsoluteValue, candle.k!.abs());
      maxAbsoluteValue = max(maxAbsoluteValue, candle.d!.abs());
      maxAbsoluteValue = max(maxAbsoluteValue, candle.j!.abs());
    }
  }

  double? latestK;
  double? latestD;
  double? latestJ;

  for (int i = 1; i < params.candles.length; i++) {
    final candle = params.candles[i];
    final previousCandle = params.candles[i - 1];

    if (candle.k != null && candle.d != null && candle.j != null) {
      final double x1 = (i - 1) * params.candleWidth;
      final double x2 = i * params.candleWidth;

      if (previousCandle.k != null && previousCandle.d != null && previousCandle.j != null) {
        final double kY1 = kdjBottom - (previousCandle.k! / maxAbsoluteValue) * kdjMaxHeight;
        final double kY2 = kdjBottom - (candle.k! / maxAbsoluteValue) * kdjMaxHeight;

        final double dY1 = kdjBottom - (previousCandle.d! / maxAbsoluteValue) * kdjMaxHeight;
        final double dY2 = kdjBottom - (candle.d! / maxAbsoluteValue) * kdjMaxHeight;

        final double jY1 = kdjBottom - (previousCandle.j! / maxAbsoluteValue) * kdjMaxHeight;
        final double jY2 = kdjBottom - (candle.j! / maxAbsoluteValue) * kdjMaxHeight;

        canvas.drawLine(Offset(x1, kY1), Offset(x2, kY2), kPaint);
        canvas.drawLine(Offset(x1, dY1), Offset(x2, dY2), dPaint);
        canvas.drawLine(Offset(x1, jY1), Offset(x2, jY2), jPaint);
      }

      latestK = candle.k;
      latestD = candle.d;
      latestJ = candle.j;
    }
  }

  if (latestK != null && latestD != null && latestJ != null) {
    final textPainterK = TextPainter(
      text: TextSpan(
        text: 'K: ${latestK.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainterD = TextPainter(
      text: TextSpan(
        text: 'D: ${latestD.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainterJ = TextPainter(
      text: TextSpan(
        text: 'J: ${latestJ.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.green, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainterK.paint(canvas, Offset(5, kdjTop));
    textPainterD.paint(canvas, Offset(80, kdjTop));
    textPainterJ.paint(canvas, Offset(150, kdjTop));
  }
}

void _drawMACDIndicator(Canvas canvas, PainterParams params,double previousBottom, double height) {
  final double macdMaxHeight = height; // 最大高度限制为100px
  final double macdTop =previousBottom + 20;
  final double macdBottom = macdTop + macdMaxHeight+20;

  // 计算所有DIF和DEA的最大绝对值
  double maxAbsoluteValue = 0.0;
  for (final candle in params.candles) {
    if (candle.dif != null && candle.dea != null) {
      maxAbsoluteValue = max(maxAbsoluteValue, candle.dif!.abs());
      maxAbsoluteValue = max(maxAbsoluteValue, candle.dea!.abs());
    }
  }

  final Paint difPaint = Paint()
    ..color = Colors.orange
    ..strokeWidth = 1.0;

  final Paint deaPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 1.0;

  final Paint histogramPositivePaint = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.fill;

  final Paint histogramNegativePaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  double? latestDIF;
  double? latestDEA;

  for (int i = 1; i < params.candles.length; i++) {
    final candle = params.candles[i];
    final previousCandle = params.candles[i - 1];

    if (candle.dif != null && candle.dea != null) {
      final double x1 = (i - 1) * params.candleWidth;
      final double x2 = i * params.candleWidth;

      if (previousCandle.dif != null && previousCandle.dea != null) {
        final double difY1 = macdBottom - (previousCandle.dif! / maxAbsoluteValue) * macdMaxHeight;
        final double difY2 = macdBottom - (candle.dif! / maxAbsoluteValue) * macdMaxHeight;

        final double deaY1 = macdBottom - (previousCandle.dea! / maxAbsoluteValue) * macdMaxHeight;
        final double deaY2 = macdBottom - (candle.dea! / maxAbsoluteValue) * macdMaxHeight;

        // 绘制DIF线和DEA线
        canvas.drawLine(Offset(x1, difY1), Offset(x2, difY2), difPaint);
        canvas.drawLine(Offset(x1, deaY1), Offset(x2, deaY2), deaPaint);
      }

      // 绘制Histogram（单像素宽度）
      final double histogramHeight = (candle.histogram! / maxAbsoluteValue) * macdMaxHeight;
      final Paint histogramPaint = candle.histogram! >= 0
          ? histogramPositivePaint
          : histogramNegativePaint;

      canvas.drawRect(
        Rect.fromLTWH(x2, macdBottom, 1, -histogramHeight),
        histogramPaint,
      );

      latestDIF = candle.dif;
      latestDEA = candle.dea;
    }
  }

  // 在MACD图表的左上角绘制DIF和DEA的数值
  if (latestDIF != null && latestDEA != null) {
    final textPainterDIF = TextPainter(
      text: TextSpan(
        text: 'DIF: ${latestDIF.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.orange, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainterDEA = TextPainter(
      text: TextSpan(
        text: 'DEA: ${latestDEA.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterDIF.paint(canvas, Offset(5, macdTop));
    textPainterDEA.paint(canvas, Offset(100, macdTop));
    canvas.restore();
  }
}
