import 'package:flutter/material.dart';
import 'package:flutter_pane_system/flutter_pane_system.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter pane system demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Flutter pane system demo'),
        ),
        body: PaneSystem<TabData>(
          tabViewBuilder: (_, __) => const SizedBox.shrink(),
          tabBuilder: (_, __) => const SizedBox.shrink(),
          emptyTabBuilder: (context) {
            return const Text('New tab');
          },
          emptyTabViewBuilder: (context, pane) {
            return const Center(
              child: Text('Empty tab'),
            );
          },
        ),
      ),
    );
  }
}

class TabData extends PaneTabData<TabData> {
  final String title;
  final IconData icon;
  final Widget content;

  const TabData({
    required this.title,
    required this.icon,
    required this.content,
    required super.id,
    required super.visible,
  });

  @override
  TabData copyWithVisibility(bool visibility) {
    return TabData(
        id: id,
        title: title,
        icon: icon,
        content: content,
        visible: visibility);
  }

  @override
  String toString() {
    return 'TabData{title: $title, icon: $icon, content: $content}';
  }
}
