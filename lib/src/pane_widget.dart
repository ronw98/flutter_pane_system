import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gap/gap.dart';

import 'model/pane_tree.dart';
import 'pane_system.dart';

/// Has multiple tabs but displays a single view corresponding to the selected tab.
class PaneWidget<T extends PaneTabData<T>> extends StatefulWidget {
  const PaneWidget({
    super.key,
    required this.pane,
  });

  final Pane<T> pane;

  @override
  State<PaneWidget<T>> createState() => _PaneWidgetState<T>();
}

enum HalfPart { start, end }

enum DropResponsePlacement {
  top,
  bottom,
  left,
  right,
  center,
}

class _PaneWidgetState<T extends PaneTabData<T>> extends State<PaneWidget<T>> {
  late PaneTab<T> selectedTab = widget.pane.tabsData.firstOrNull ??
      EmptyTab<T>(
        id: PaneTree.autoIncrement,
        visible: true,
      );
  late final ValueNotifier<DropResponsePlacement?> _responsePlacement;

  Widget get _dropResponseIndicator {
    return ColoredBox(
      color: Colors.grey.withOpacity(.3),
    );
  }

  void _setTabVisibility(PaneTab<T> data, bool visible) {
    final tabIndex = widget.pane.tabsData.indexOf(data);

    final hiddenTab = data.copyWithVisibility(visible);
    final newTabs = widget.pane.tabsData
        .where(
          (tab) => tab != data,
        )
        .toList()
      ..insert(tabIndex, hiddenTab);

    PaneSystem.of<T>(context).controller.replaceElement(
          widget.pane,
          widget.pane.copyWithTabs(newTabs),
        );
  }

  void _addTab(PaneTab<T> data, int index) {
    final newTabs = [...widget.pane.tabsData]..insert(
        index,
        data.copyWithVisibility(true),
      );
    PaneSystem.of<T>(context).controller.replaceElement(
          widget.pane,
          widget.pane.copyWithTabs(newTabs),
        );
    setState(() {
      selectedTab = data;
    });
  }

  void _removeTab(PaneTab<T> data) {
    if (widget.pane.tabsData.length == 1) {
      PaneSystem.of<T>(context).controller.removePane(widget.pane);
      return;
    }

    final newTabs = widget.pane.tabsData
        .where(
          (tab) => tab.id != data.id,
        )
        .toList();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        PaneSystem.of<T>(context).controller.replaceElement(
              widget.pane,
              widget.pane.copyWithTabs(newTabs),
            );
      },
    );
  }

  void _removeHiddenTabs() {
    final newTabs = widget.pane.tabsData
        .where(
          (tab) => tab.visible,
        )
        .toList();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        if (newTabs.isEmpty) {
          PaneSystem.of<T>(context).controller.removePane(widget.pane);
        } else {
          PaneSystem.of<T>(context).controller.replaceElement(
                widget.pane,
                widget.pane.copyWithTabs(newTabs),
              );
        }
      },
    );
  }

  void _onDropQuarter(PaneTab<T> data, Axis axis, HalfPart part) {
    final availableSpace = widget.pane.size;
    final (child1, child2) = switch (part) {
      // New data is dropped at the start so it is first child and this pane is second
      HalfPart.start => (
          Pane<T>(
            id: PaneTree.autoIncrement,
            size: availableSpace,
            tabsData: [data],
          ),
          widget.pane,
        ),
      HalfPart.end => (
          widget.pane,
          Pane<T>(
            id: PaneTree.autoIncrement,
            size: availableSpace,
            tabsData: [data],
          ),
        ),
    };

    final newNode = axis == Axis.horizontal
        ? HorizontalPaneTreeNode(
            id: PaneTree.autoIncrement,
            size: availableSpace,
            child1: child1,
            child2: child2,
          )
        : VerticalPaneTreeNode(
            id: PaneTree.autoIncrement,
            size: availableSpace,
            child1: child1,
            child2: child2,
          );

    _responsePlacement.value = null;
    PaneSystem.of<T>(context).controller.replaceElement(
          widget.pane,
          newNode,
        );
  }

  @override
  void initState() {
    super.initState();
    _responsePlacement = ValueNotifier(null);
  }

  @override
  void dispose() {
    _responsePlacement.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PaneWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pane != widget.pane) {
      if (!widget.pane.tabsData.contains(selectedTab)) {
        selectedTab = widget.pane.tabsData.firstOrNull ??
            EmptyTab<T>(
              id: PaneTree.autoIncrement,
              visible: true,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: _PaneTabBar<T>(
            tabs: widget.pane.tabsData,
            onCloseTab: _removeTab,
            onNewTabClicked: () {
              _addTab(
                EmptyTab(id: PaneTree.autoIncrement, visible: true),
                widget.pane.tabsData.length,
              );
            },
            onTabClicked: (tab) {
              setState(() {
                selectedTab = tab;
              });
            },
            onDragEnded: (tab, reinsertAt) {
              _setTabVisibility(tab, true);
            },
            onDroppedSomewhere: (_) => _removeHiddenTabs(),
            onStartedDragging: (tab) {
              _setTabVisibility(tab, false);
            },
            onReceivedTab: _addTab,
            selectedTab: selectedTab,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: switch (selectedTab) {
                  EmptyTab<T>() => PaneSystem.of<T>(context)
                      .emptyTabViewBuilder(context, widget.pane),
                  final T tab => PaneSystem.of<T>(context).tabViewBuilder(
                      context,
                      tab,
                    ),
                  // Cannot happen
                  _ => const SizedBox.shrink(),
                },
              ),
              ValueListenableBuilder<DropResponsePlacement?>(
                valueListenable: _responsePlacement,
                builder: (context, value, _) {
                  return switch (value) {
                    null => const SizedBox.shrink(),
                    DropResponsePlacement.top => Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          heightFactor: .5,
                          child: _dropResponseIndicator,
                        ),
                      ),
                    DropResponsePlacement.bottom => Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          heightFactor: .5,
                          child: _dropResponseIndicator,
                        ),
                      ),
                    DropResponsePlacement.left => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: .5,
                          heightFactor: 1,
                          child: _dropResponseIndicator,
                        ),
                      ),
                    DropResponsePlacement.right => Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: .5,
                          heightFactor: 1,
                          child: _dropResponseIndicator,
                        ),
                      ),
                    DropResponsePlacement.center => FractionallySizedBox(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: _dropResponseIndicator,
                      ),
                  };
                },
              ),
              // Add to pane
              Center(
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: _PaneDragTarget<T>(
                    onLeave: () {
                      _responsePlacement.value = null;
                    },
                    onHover: () {
                      _responsePlacement.value = DropResponsePlacement.center;
                    },
                    targetColor: Colors.black,
                    onDrop: (tab) {
                      _addTab(
                        tab,
                        widget.pane.tabsData.length,
                      );
                      _responsePlacement.value = null;
                    },
                  ),
                ),
              ),
              // Add to top
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  heightFactor: .2,
                  widthFactor: 1,
                  child: _PaneDragTarget<T>(
                    onLeave: () {
                      _responsePlacement.value = null;
                    },
                    onHover: () {
                      _responsePlacement.value = DropResponsePlacement.top;
                    },
                    targetColor: Colors.blue,
                    onDrop: (PaneTab<T> data) {
                      _onDropQuarter(data, Axis.vertical, HalfPart.start);
                    },
                  ),
                ),
              ),
              // Add to bottom
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: .2,
                  widthFactor: 1,
                  child: _PaneDragTarget<T>(
                    onLeave: () {
                      _responsePlacement.value = null;
                    },
                    onHover: () {
                      _responsePlacement.value = DropResponsePlacement.bottom;
                    },
                    targetColor: Colors.red,
                    onDrop: (PaneTab<T> data) {
                      _onDropQuarter(data, Axis.vertical, HalfPart.end);
                    },
                  ),
                ),
              ),
              // Add to left
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  heightFactor: .8,
                  widthFactor: .2,
                  child: _PaneDragTarget<T>(
                    onLeave: () {
                      _responsePlacement.value = null;
                    },
                    onHover: () {
                      _responsePlacement.value = DropResponsePlacement.left;
                    },
                    targetColor: Colors.yellow,
                    onDrop: (PaneTab<T> data) {
                      _onDropQuarter(data, Axis.horizontal, HalfPart.start);
                    },
                  ),
                ),
              ),
              // Add to right
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  heightFactor: .8,
                  widthFactor: .2,
                  child: _PaneDragTarget<T>(
                    onLeave: () {
                      _responsePlacement.value = null;
                    },
                    onHover: () {
                      _responsePlacement.value = DropResponsePlacement.right;
                    },
                    targetColor: Colors.green,
                    onDrop: (PaneTab<T> data) {
                      _onDropQuarter(data, Axis.horizontal, HalfPart.end);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaneTabBar<T extends PaneTabData<T>> extends StatefulWidget {
  const _PaneTabBar({
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
  });

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
  State<_PaneTabBar<T>> createState() => _PaneTabBarState<T>();
}

class _PaneTabBarState<T extends PaneTabData<T>> extends State<_PaneTabBar<T>> {
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
  });

  final T data;

  final bool selected;
  final VoidCallback onDroppedSomewhere;
  final void Function(T data) onStartedDragging;
  final void Function(T data) onDragEnded;
  final void Function(T data) onCloseTab;

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
    return DecoratedBox(
      decoration: BoxDecoration(
          border: selected
              ? Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                )
              : null),
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
  });

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
    return DecoratedBox(
      decoration: BoxDecoration(
          border: selected
              ? Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                )
              : null),
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

class _PaneDragTarget<T extends PaneTabData<T>> extends StatelessWidget {
  const _PaneDragTarget({
    super.key,
    required this.onDrop,
    required this.targetColor,
    required this.onHover,
    required this.onLeave,
  });

  final Function(PaneTab<T> data) onDrop;
  final VoidCallback onHover;
  final VoidCallback onLeave;
  final Color targetColor;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PaneTab<T>>(
      hitTestBehavior: HitTestBehavior.translucent,
      builder: (context, accepted, _) {
        // return ColoredBox(color: targetColor);
        return const SizedBox();
      },
      onMove: (details) {
        onHover();
      },
      onLeave: (_) {
        onLeave();
      },
      onAcceptWithDetails: (details) {
        onDrop(details.data);
      },
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
