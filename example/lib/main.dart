import 'package:flutter/material.dart';
import 'package:panels_system/model/pane_tree.dart';
import 'package:panels_system/pane_system.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: PaneSystem<TabData>(
        tabViewBuilder: (_, __) => const SizedBox.shrink(),
        tabBuilder: (_, __) => const SizedBox.shrink(),
        emptyTabBuilder: (context) {
          return const Text('Nouvel onglet');
        },
        emptyTabViewBuilder: (context, pane) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  PaneSystem.of<TabData>(context).controller.replaceElement(
                        pane,
                        HorizontalPaneTreeNode(
                          size: Size.zero,
                          child1: pane,
                          child2: Pane<TabData>(
                            size: Size.zero,
                            id: PaneTree.autoIncrement,
                            tabsData: [
                              EmptyTab(
                                id: PaneTree.autoIncrement,
                                visible: true,
                              ),
                            ],
                          ),
                          id: PaneTree.autoIncrement,
                        ),
                      );
                },
                child: const Text('Split horizontally'),
              ),
              ElevatedButton(
                onPressed: () {
                  PaneSystem.of<TabData>(context).controller.replaceElement(
                        pane,
                        VerticalPaneTreeNode(
                          size: Size.zero,
                          child1: pane,
                          child2: Pane<TabData>(
                            size: Size.zero,
                            id: PaneTree.autoIncrement,
                            tabsData: [
                              EmptyTab(
                                id: PaneTree.autoIncrement,
                                visible: true,
                              ),
                            ],
                          ),
                          id: PaneTree.autoIncrement,
                        ),
                      );
                },
                child: const Text('Split vertically'),
              ),
            ],
          );
        },
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
