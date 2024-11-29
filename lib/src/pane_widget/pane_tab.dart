import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../model/pane_tree.dart';
import '../pane_system.dart';

class PaneTabBar<T extends PaneTabData<T>> extends StatefulWidget {
  const PaneTabBar({
    super.key,
    required this.tabs,
    required this.onDroppedSomewhere,
    required this.onStartedDragging,
    required this.onDragEnded,
    required this.onReceivedTab,
    required this.onTabClicked,
    required this.selectedTab,
    required this.onCloseTab,
    required this.onNewTabClicked,
    required this.paneId,
  });

  final String paneId;
  final List<PaneTab<T>> tabs;
  final PaneTab<T> selectedTab;

  final void Function(PaneTab<T> data) onDroppedSomewhere;
  final void Function(PaneTab<T> data) onStartedDragging;
  final void Function(PaneTab<T> data, int index) onDragEnded;
  final void Function(PaneTab<T> data, int index) onReceivedTab;
  final void Function(PaneTab<T> data) onTabClicked;
  final void Function(PaneTab<T> data) onCloseTab;
  final VoidCallback onNewTabClicked;

  @override
  State<PaneTabBar<T>> createState() => _PaneTabBarState<T>();
}

class _PaneTabBarState<T extends PaneTabData<T>> extends State<PaneTabBar<T>> {
  int draggingIndex = 0;
  int? hoveringOverIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.all((tab) => !tab.visible)) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor,
            width: .5,
          ),
        ),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 8,
            color: Colors.black.withOpacity(.1),
          ),
        ],
      ),
      child: FractionallySizedBox(
        widthFactor: 1,
        child: Wrap(
          alignment: WrapAlignment.start,
          children: [
            for (final (index, tab) in widget.tabs.indexed)
              SizedBox(
                height: 50,
                child: Visibility(
                  visible: tab.visible,
                  maintainState: true,
                  maintainSize: false,
                  maintainInteractivity: false,
                  maintainAnimation: false,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index == hoveringOverIndex)
                            Container(
                              width: 150,
                              height: 50,
                              color: Colors.grey.withOpacity(.3),
                            ),
                          InkWell(
                            onTap: () => widget.onTabClicked(tab),
                            child: switch (tab) {
                              final EmptyTab<T> tab => EmptyPaneTabWidget(
                                  paneId: widget.paneId,
                                  data: tab,
                                  selected: tab == widget.selectedTab,
                                  onDroppedSomewhere: () =>
                                      widget.onDroppedSomewhere(tab),
                                  onStartedDragging: (tab) {
                                    draggingIndex = index;
                                    widget.onStartedDragging(tab);
                                  },
                                  onDragEnded: (data) =>
                                      widget.onDragEnded(data, draggingIndex),
                                  onCloseTab: widget.onCloseTab,
                                ),
                              final T tab => PaneTabWidget(
                                  paneId: widget.paneId,
                                  data: tab,
                                  selected: tab == widget.selectedTab,
                                  onDroppedSomewhere: () =>
                                      widget.onDroppedSomewhere(tab),
                                  onStartedDragging: (tab) {
                                    draggingIndex = index;
                                    widget.onStartedDragging(tab);
                                  },
                                  onDragEnded: (data) =>
                                      widget.onDragEnded(data, draggingIndex),
                                  onCloseTab: widget.onCloseTab,
                                ),
                              // Cannot happen
                              _ => const SizedBox.shrink()
                            },
                          ),
                          if (index == widget.tabs.length - 1 &&
                              hoveringOverIndex == widget.tabs.length)
                            Container(
                              width: 150,
                              height: 50,
                              color: Colors.grey.withOpacity(.3),
                            ),
                        ],
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: .5,
                            heightFactor: 1,
                            child: _PaneTabDragTarget<T>(
                              onLeave: () {
                                setState(() {
                                  hoveringOverIndex = null;
                                });
                              },
                              onHover: () {
                                setState(() {
                                  hoveringOverIndex = index;
                                });
                              },
                              onReceivedTab: (data) =>
                                  widget.onReceivedTab(data, index),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: .5,
                            heightFactor: 1,
                            child: _PaneTabDragTarget<T>(
                              onLeave: () {
                                setState(() {
                                  hoveringOverIndex = null;
                                });
                              },
                              onHover: () {
                                setState(() {
                                  hoveringOverIndex = index + 1;
                                });
                              },
                              onReceivedTab: (data) =>
                                  widget.onReceivedTab(data, index + 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              onPressed: widget.onNewTabClicked,
              icon: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaneTabDragTarget<T extends PaneTabData<T>> extends StatelessWidget {
  const _PaneTabDragTarget({
    super.key,
    required this.onReceivedTab,
    required this.onHover,
    required this.onLeave,
  });

  final void Function(PaneTab<T> data) onReceivedTab;
  final void Function() onHover;
  final void Function() onLeave;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PaneTab<T>>(
      builder: (context, candidate, rejected) {
        return const SizedBox.shrink();
      },
      onAcceptWithDetails: (details) {
        onReceivedTab(details.data);
        onLeave();
      },
      onWillAcceptWithDetails: (_) {
        onHover();
        return true;
      },
      onLeave: (_) => onLeave(),
    );
  }
}

class PaneTabWidget<T extends PaneTabData<T>> extends StatelessWidget {
  const PaneTabWidget({
    super.key,
    required this.data,
    required this.onStartedDragging,
    required this.onDragEnded,
    required this.onDroppedSomewhere,
    required this.selected,
    required this.onCloseTab,
    required this.paneId,
  });

  final T data;

  final bool selected;
  final String paneId;
  final VoidCallback onDroppedSomewhere;
  final void Function(T data) onStartedDragging;
  final void Function(T data) onDragEnded;
  final void Function(T data) onCloseTab;

  @override
  Widget build(BuildContext context) {
    final selectedPaneNotifier =
        PaneSystem.of<T>(context).controller.selectedPaneNotifier;
    final tab = DefaultTextStyle(
      style: Theme.of(context).textTheme.labelSmall ?? TextStyle(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 50,
          maxHeight: 50,
          maxWidth: 150,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaneSystem.of<T>(context).tabBuilder(context, data),
            Gap(4),
            IconButton(
              onPressed: () {
                onCloseTab(data);
              },
              icon: Icon(
                Icons.close,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
    return ValueListenableBuilder(
      valueListenable: selectedPaneNotifier,
      builder: (context, value, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: selected
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(value == paneId ? 1 : .3),
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: child,
        );
      },
      child: Draggable<T>(
        feedback: tab,
        childWhenDragging: const SizedBox(),
        data: data,
        child: tab,
        onDraggableCanceled: (_, __) {
          onDragEnded(data);
        },
        onDragStarted: () {
          onStartedDragging(data);
        },
        onDragCompleted: () {
          onDroppedSomewhere();
        },
      ),
    );
  }
}

class EmptyPaneTabWidget<T extends PaneTabData<T>> extends StatelessWidget {
  const EmptyPaneTabWidget({
    super.key,
    required this.onStartedDragging,
    required this.onDragEnded,
    required this.onDroppedSomewhere,
    required this.selected,
    required this.onCloseTab,
    required this.data,
    required this.paneId,
  });

  final String paneId;
  final EmptyTab<T> data;
  final bool selected;
  final VoidCallback onDroppedSomewhere;
  final void Function(EmptyTab<T> data) onStartedDragging;
  final void Function(EmptyTab<T> data) onDragEnded;
  final void Function(EmptyTab<T> data) onCloseTab;

  @override
  Widget build(BuildContext context) {
    final tab = DefaultTextStyle(
      style: Theme.of(context).textTheme.labelSmall ?? TextStyle(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 50,
          maxHeight: 50,
          maxWidth: 150,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaneSystem.of<T>(context).emptyTabBuilder(context),
            Gap(4),
            IconButton(
              onPressed: () {
                onCloseTab(data);
              },
              icon: Icon(
                Icons.close,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
    final selectedPaneNotifier =
        PaneSystem.of<T>(context).controller.selectedPaneNotifier;
    return ValueListenableBuilder(
      valueListenable: selectedPaneNotifier,
      builder: (context, value, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: selected
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(
                            value == paneId ? 1 : .3,
                          ),
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: child,
        );
      },
      child: Draggable<PaneTab<T>>(
        feedback: tab,
        childWhenDragging: const SizedBox(),
        data: data,
        child: tab,
        onDraggableCanceled: (_, __) {
          onDragEnded(data);
        },
        onDragStarted: () {
          onStartedDragging(data);
        },
        onDragCompleted: () {
          onDroppedSomewhere();
        },
      ),
    );
  }
}

extension IterableExt<T> on Iterable<T> {
  bool all(bool Function(T) condition) {
    final it = iterator;
    while (it.moveNext()) {
      if (!condition(it.current)) {
        return false;
      }
    }
    return true;
  }
}
