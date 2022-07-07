import 'dart:math';

import 'package:berd/src/berd.dart';
import 'package:flutter/material.dart';

void main() {
  /*
  final number = Creator((ref, self) => 1);
  final double = Creator((ref, self) => ref.watch(number, self) * 2);
  final ref = Ref();
  print(ref.watch(double, null)); // 2

  ref.set(number, 10);
  print(ref.watch(double, null)); // 20

  ref.update<int>(number, (n) => n + 1);
  print(ref.watch(double, null)); // 22
  */
  runApp(BerdCreatorGraph(child: const BerdApp()));
}

// ignore: public_member_api_docs
final counter = BerdCreator((ref, self) => 0);

/// {@template berd_app}
/// My Berd State Management App - roach.
/// {@endtemplate}
class BerdApp extends StatelessWidget {
  /// {@macro berd_app}
  const BerdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berd',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Berd State'),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: BerdWatcher(
                  (context, ref, self) {
                    final count = ref.watch(counter, self);
                    return Column(
                      children: [
                        Text('$count Berds'),
                        Wrap(
                          children: List.generate(count, (index) {
                            final rand = Random().nextInt(Berds.values.length);
                            final berd = Berds.values.elementAt(rand);

                            return Image(
                              image: AssetImage(berd.asset),
                              height: 50,
                            );
                          }),
                        )
                      ],
                    );
                  },
                ),
              ),
              const Positioned(
                right: 70,
                bottom: 50,
                child: Text('Click here!'), // TODO(carlos): Comic Sans!
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Image(image: AssetImage(Berds.buyThatOne.asset)),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.ref.update<int>(counter, (n) => n + 1);
          },
          child: Image(image: AssetImage(Berds.white.asset)),
        ),
      ),
    );
  }
}

/// {@template berds}
/// Enum with the list of all available berds
/// {@endtemplate}
enum Berds {
  /// Blue berd
  blue('${_path}blue.png'),

  /// Cyan berd
  cyan('${_path}cyan.png'),

  /// Green berd
  green('${_path}green.png'),

  /// Orange berd
  orange('${_path}orange.png'),

  /// Purple berd
  purple('${_path}purple.png'),

  /// Red berd
  red('${_path}red.png'),

  /// White berd
  white('${_path}white.png'),

  /// Yellow berd
  yellow('${_path}yellow.png'),

  /// tiny blue berd as gif
  tinyBlue('${_path}tinyblue.gif'),

  /// tiny green berd as gif
  tinyGreen('${_path}tinygreen.gif'),

  /// tiny red berd as gif
  tinyRed('${_path}tinyred.gif'),

  /// tiny yellow berd as gif
  tinyYellow('${_path}tinyyellow.gif'),

  /// pointing berd as gif
  buyThatOne('${_path}buy_that_one.gif'),

  /// falling berd as gif
  greeting('${_path}greeting.gif');

  /// {@macro berds}
  const Berds(this.asset);

  static const _path = 'assets/images/';

  /// Berd asset file
  final String asset;

  //String getPath(Berds berd) => '$_path${berd.asset}';
}
