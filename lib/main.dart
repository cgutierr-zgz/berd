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
  runApp(BerdCreatorGraph(child: const MyApp()));
}

final counter = BerdCreator((ref, self) => 0);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berd',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Berd State'),
        ),
        body: Center(
          child: BerdWatcher((context, ref, self) {
            return Text('${ref.watch(counter, self)}');
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.ref.update<int>(counter, (n) => n + 1);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
