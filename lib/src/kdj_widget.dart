import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';


class KDJWidget extends LeafRenderObjectWidget {
  final List<CandleData> candles;
  final int index;
  final double barWidth;
  final double high;
  final Color kColor;
  final Color dColor;
  final Color jColor;

  KDJWidget({
    required this.candles,
    required this.index,
    required this.barWidth,
    required this.high,
    required this.kColor,
    required this.dColor,
    required this.jColor,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {

    return KDJRenderObject(
      candles,
      index,
      barWidth,
      high,
      kColor,
      dColor,
      jColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {

    KDJRenderObject kdjRenderObject = renderObject as KDJRenderObject;
    kdjRenderObject._candles = candles;
    kdjRenderObject._index = index;
    kdjRenderObject._barWidth = barWidth;
    kdjRenderObject._high = high;
    kdjRenderObject._kColor = kColor;
    kdjRenderObject._dColor = dColor;
    kdjRenderObject._jColor = jColor;
    kdjRenderObject.markNeedsPaint();
    super.updateRenderObject(context, renderObject);
  }
}

class KDJRenderObject extends RenderBox {
  late List<CandleData> _candles;
  late int _index;
  late double _barWidth;
  late double _high;
  late Color _kColor;
  late Color _dColor;
  late Color _jColor;

  KDJRenderObject(
      List<CandleData> candles,
      int index,
      double barWidth,
      double high,
      Color kColor,
      Color dColor,
      Color jColor,
      ) {
    _candles = candles;
    _index = index;
    _barWidth = barWidth;
    _high = high;
    _kColor = kColor;
    _dColor = dColor;
    _jColor = jColor;
  }

  /// 设置尺寸尽可能大
  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  /// 绘制KDJ指标线
  void paintLine(PaintingContext context, Offset offset, int index,
      double lastValue, double curValue, Color color, double range) {
    double x1 = size.width + offset.dx - (index + 0.5) * _barWidth;
    double y1 = offset.dy + (_high - lastValue) / range;
    double x2 = size.width + offset.dx - (index + 1.5) * _barWidth;
    double y2 = offset.dy + (_high - curValue) / range;

    context.canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = color
        ..strokeWidth = 1.0,
    );
  }

  /// 绘制左上角的 KDJ 数值
  void paintText(PaintingContext context, Offset offset,CandleData candle) {
    final CandleData lastCandle = candle;

    final TextPainter textPainterK = TextPainter(
      text: TextSpan(
        text: 'K: ${lastCandle.k?.toStringAsFixed(2) ?? 'N/A'}',
        style: TextStyle(color: _kColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final TextPainter textPainterD = TextPainter(
      text: TextSpan(
        text: 'D: ${lastCandle.d?.toStringAsFixed(2) ?? 'N/A'}',
        style: TextStyle(color: _dColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final TextPainter textPainterJ = TextPainter(
      text: TextSpan(
        text: 'J: ${lastCandle.j?.toStringAsFixed(2) ?? 'N/A'}',
        style: TextStyle(color: _jColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double textX = offset.dx + 10; // Adjust X position
    double textY = offset.dy + 10; // Adjust Y position

    textPainterK.paint(context.canvas, Offset(textX, textY));
    textPainterD.paint(context.canvas, Offset(textX+70, textY));
    textPainterJ.paint(context.canvas, Offset(textX+140, textY));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double range = _high / size.height;
    CandleData? lastVisibleCandle;

    for (int i = 0; (i + 1) * _barWidth < size.width; i++) {
      if (i + _index >= _candles.length || i + _index < 1) continue;
      var lastCandle = _candles[i + _index - 1];
      var curCandle = _candles[i + _index];

      paintLine(context, offset, i, lastCandle.k??0, curCandle.k??0, _kColor, range);
      paintLine(context, offset, i, lastCandle.d??0, curCandle.d??0, _dColor, range);
      paintLine(context, offset, i, lastCandle.j??0, curCandle.j??0, _jColor, range);
      lastVisibleCandle = curCandle;
    }

    if (lastVisibleCandle != null) {
      paintText(context, offset, lastVisibleCandle); // 调用绘制文本方法
    }

    context.canvas.save();
    context.canvas.restore();
  }

}
