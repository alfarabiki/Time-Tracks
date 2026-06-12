import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeproof/widgets/luxe/stat_tile.dart';
import 'package:timeproof/widgets/luxe/primary_button.dart';

void main() {
  testWidgets('StatTile shows number + label', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body:
      StatTile(value: '12', label: 'Kunjungan hari ini', icon: Icons.place))));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Kunjungan hari ini'), findsOneWidget);
  });

  testWidgets('PrimaryButton fires onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body:
      PrimaryGradientButton(title: 'Mulai', subtitle: 'x', icon: Icons.camera_alt,
        onTap: () => tapped = true))));
    await t.tap(find.text('Mulai'));
    expect(tapped, isTrue);
  });
}
