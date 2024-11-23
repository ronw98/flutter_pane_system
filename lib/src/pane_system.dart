import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:logger/logger.dart';

import 'model/pane_tree.dart';
import 'pane_system_controller.dart';
import 'pane_widget.dart';

final logger = Logger(
  printer: PrettyPrinter(),
  level: Level.trace,
);

typedef TabDataBuilder<T extends PaneTabData<T>> = Widget Function(
  BuildContext context,
  T tabData,
);

typedef EmptyTabViewBuilder<T extends PaneTabData<T>> = Widget Function(
  BuildContext context,
  Pane<T> pane,
);

class PaneSystem<T extends PaneTabData<T>> extends StatefulWidget {
  const PaneSystem({
    super.key,
    required this.tabViewBuilder,
    required this.tabBuilder,
    required this.emptyTabViewBuilder,
    required this.emptyTabBuilder,
  });

  final TabDataBuilder<T> tabViewBuilder;
  final TabDataBuilder<T> tabBuilder;
  final EmptyTabViewBuilder<T> emptyTabViewBuilder;
  final WidgetBuilder emptyTabBuilder;

  static PaneSystemControllerProvider<T> of<T extends PaneTabData<T>>(
      BuildContext context) {
    final PaneSystemControllerProvider<T>? result = context
        .dependOnInheritedWidgetOfExactType<PaneSystemControllerProvider<T>>();
    assert(result != null, 'No _PaneSystemControllerProvider found in context');
    return result!;
  }

  @override
  State<PaneSystem<T>> createState() => _PaneSystemState<T>();
}

class _PaneSystemState<T extends PaneTabData<T>> extends State<PaneSystem<T>> {
  late PaneSystemController<T> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaneSystemController<T>(
      PaneTree<T>(
        root: Pane(
          size: Size(0, 0),
          tabsData: [
            EmptyTab(
              id: PaneTree.autoIncrement,
              visible: true,
            ),
          ],
          id: PaneTree.autoIncrement,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaneSystemControllerProvider<T>(
      controller: _controller,
      emptyTabViewBuilder: widget.emptyTabViewBuilder,
      emptyTabBuilder: widget.emptyTabBuilder,
      tabBuilder: widget.tabBuilder,
      tabViewBuilder: widget.tabViewBuilder,
      child: _PaneTreeRootWidget<T>(),
    );
  }
}

class _PaneTreeRootWidget<T extends PaneTabData<T>> extends StatefulWidget {
  const _PaneTreeRootWidget({super.key});

  @override
  State<_PaneTreeRootWidget<T>> createState() => _PaneTreeRootWidgetState();
}

class _PaneTreeRootWidgetState<T extends PaneTabData<T>>
    extends State<_PaneTreeRootWidget<T>> {
  late PaneTreeElement<T> currentRoot;
  late PaneSystemController<T> _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PaneSystem.of<T>(context).controller;
    currentRoot = PaneSystem.of<T>(context).controller.tree.root;
    PaneSystem.of<T>(context).controller.registerAsTreeRoot(
      (newRoot) {
        logger.d('Updated root to $newRoot.\nFrom $currentRoot');
        setState(() {
          currentRoot = newRoot;
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.unregisterAsTreeRoot();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PaneTreeElementWidget(element: currentRoot);
  }
}

class _PaneTreeElementWidget<T extends PaneTabData<T>> extends StatefulWidget {
  const _PaneTreeElementWidget({super.key, required this.element});

  final PaneTreeElement<T> element;

  @override
  _PaneTreeElementWidgetState<T> createState() =>
      _PaneTreeElementWidgetState<T>();
}

class _PaneTreeElementWidgetState<T extends PaneTabData<T>>
    extends State<_PaneTreeElementWidget<T>> {
  late PaneTreeElement<T> currentElement;
  late PaneSystemController<T> _controller;

  @override
  void initState() {
    super.initState();
    currentElement = widget.element;
    logger.d('Init widget with element: $currentElement');
  }

  @override
  void didUpdateWidget(covariant _PaneTreeElementWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.element != oldWidget.element) {
      PaneSystem.of<T>(context)
          .controller
          .onWidgetDispose(oldWidget.element.id, _elementChangedNotifier);
      currentElement = widget.element;
      registerAsWidgetForElement();
    }
  }

  void registerAsWidgetForElement() {
    PaneSystem.of<T>(context)
        .controller
        .registerAsWidgetForElement(currentElement.id, _elementChangedNotifier);
  }

  void _elementChangedNotifier(PaneTreeElement<T> element) {
    logger.d(
      'Update widget with element: $element.\nOld element: $currentElement',
    );
    setState(() {
      currentElement = element;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PaneSystem.of<T>(context).controller;
    registerAsWidgetForElement();
  }

  @override
  void dispose() {
    _controller.onWidgetDispose(
      currentElement.id,
      _elementChangedNotifier,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (currentElement) {
      case final Pane<T> pane:
        return PaneWidget(pane: pane);
      case HorizontalPaneTreeNode<T>(
          child1: final child1,
          child2: final child2,
        ):
        return ResizableContainer(
          children: [
            ResizableChild(
              child: _PaneTreeElementWidget(
                element: child1,
              ),
            ),
            ResizableChild(
              child: _PaneTreeElementWidget(
                element: child2,
              ),
            ),
          ],
          direction: Axis.horizontal,
        );
      case VerticalPaneTreeNode<T>(
          child1: final child1,
          child2: final child2,
        ):
        return ResizableContainer(
          children: [
            ResizableChild(
              child: _PaneTreeElementWidget(
                element: child1,
              ),
            ),
            ResizableChild(
              child: _PaneTreeElementWidget(element: child2),
            ),
          ],
          direction: Axis.vertical,
        );
    }
  }
}

class PaneSystemControllerProvider<T extends PaneTabData<T>>
    extends InheritedWidget {
  const PaneSystemControllerProvider({
    super.key,
    required this.controller,
    required super.child,
    required TabDataBuilder<T> tabViewBuilder,
    required TabDataBuilder<T> tabBuilder,
    required EmptyTabViewBuilder<T> emptyTabViewBuilder,
    required WidgetBuilder emptyTabBuilder,
  })  : _tabBuilder = tabBuilder,
        _tabViewBuilder = tabViewBuilder,
        _emptyTabViewBuilder = emptyTabViewBuilder,
        _emptyTabBuilder = emptyTabBuilder;

  final PaneSystemController<T> controller;
  final EmptyTabViewBuilder<T> _emptyTabViewBuilder;
  final WidgetBuilder _emptyTabBuilder;

  Widget tabViewBuilder(BuildContext context, T data) {
    return _tabViewBuilder(context, data);
  }

  Widget tabBuilder(BuildContext context, T data) {
    return _tabBuilder(context, data);
  }

  Widget emptyTabViewBuilder(BuildContext context, Pane<T> pane) {
    return _emptyTabViewBuilder(context, pane);
  }

  Widget emptyTabBuilder(BuildContext context) {
    return _emptyTabBuilder(context);
  }

  final TabDataBuilder<T> _tabViewBuilder;
  final TabDataBuilder<T> _tabBuilder;

  @override
  bool updateShouldNotify(PaneSystemControllerProvider old) {
    return old.controller != controller;
  }
}
