// @dart=2.12

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:math';

class GaugeChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  GaugeChart(this.seriesList, {required this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(seriesList,
        animate: animate,
        behaviors: [
          new charts.DatumLegend(
              position: charts.BehaviorPosition.top,
              horizontalFirst: false,
              cellPadding: new EdgeInsets.only(right: 4.0, top: 10.0),
              showMeasures: true,
              legendDefaultMeasure: charts.LegendDefaultMeasure.firstValue,
              measureFormatter: (num? value) {
                return "${(value! * 100.0).toStringAsFixed(2)}%";
              })
        ],
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 30, startAngle: 4 / 5 * pi, arcLength: 7 / 5 * pi));
  }
}

class GaugeSegment {
  final String segment;
  final double size;

  GaugeSegment(this.segment, this.size);
}
