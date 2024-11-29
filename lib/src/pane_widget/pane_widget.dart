import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_pane_system/src/pane_widget/pane_tab.dart';

import '../model/pane_tree.dart';
import '../pane_system.dart';

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
  PaneTab<T>? _lastlyAddedTab;
  late PaneTab<T> selectedTab = widget.pane.tabsData.firstOrNull ??
      EmptyTab<T>(
        id: PaneTabData.autoIncrement,
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
    // Check if tabs contain data and if so simply set existing tab visibility
    // to true
    final existingData = widget.pane.tabsData.firstWhereOrNull(
      (t) => t.id == data.id,
    );
    if (existingData != null) {
      final existingDataIndex = widget.pane.tabsData.indexOf(existingData);
      if (existingDataIndex == index) {
        _setTabVisibility(existingData, true);
      } else {
        final newTabs = [...widget.pane.tabsData]
          ..removeAt(existingDataIndex)
          ..insert(
            index < existingDataIndex ? index : index - 1,
            data.copyWithVisibility(
              true,
            ),
          );
        PaneSystem.of<T>(context).controller.replaceElement(
              widget.pane,
              widget.pane.copyWithTabs(newTabs),
            );
      }
      setState(() {
        selectedTab = data;
      });
      return;
    }
    // Otherwise insert new tab.
    final newTabs = [...widget.pane.tabsData]..insert(
        index,
        data.copyWithVisibility(true),
      );
    PaneSystem.of<T>(context).controller
      ..replaceElement(
        widget.pane,
        widget.pane.copyWithTabs(newTabs),
      )
      ..selectedPaneNotifier.value = widget.pane.id;
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
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        final newTabs = widget.pane.tabsData
            .where(
              (tab) => tab.visible || tab.id == _lastlyAddedTab?.id,
            )
            .toList();
        _lastlyAddedTab = null;
        if (newTabs.length == widget.pane.tabsData.length) {
          return;
        }
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
            id: PaneTabData.autoIncrement,
            size: availableSpace,
            tabsData: [data],
          ),
          widget.pane,
        ),
      HalfPart.end => (
          widget.pane,
          Pane<T>(
            id: PaneTabData.autoIncrement,
            size: availableSpace,
            tabsData: [data],
          ),
        ),
    };

    final newNode = axis == Axis.horizontal
        ? HorizontalPaneTreeNode(
            id: PaneTabData.autoIncrement,
            size: availableSpace,
            child1: child1,
            child2: child2,
          )
        : VerticalPaneTreeNode(
            id: PaneTabData.autoIncrement,
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
              id: PaneTabData.autoIncrement,
              visible: true,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        PaneSystem.of<T>(context).controller.selectedPaneNotifier.value =
            widget.pane.id;
      },
      child: Stack(
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: PaneTabBar<T>(
                  paneId: widget.pane.id,
                  tabs: widget.pane.tabsData,
                  onCloseTab: _removeTab,
                  onNewTabClicked: () {
                    _addTab(
                      EmptyTab(id: PaneTabData.autoIncrement, visible: true),
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
                  onDroppedSomewhere: (_) {
                    _removeHiddenTabs();
                  },
                  onStartedDragging: (tab) {
                    _setTabVisibility(tab, false);
                  },
                  onReceivedTab: (tab, index) {
                    _addTab(tab, index);
                    _lastlyAddedTab = tab;
                  },
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
                            _responsePlacement.value =
                                DropResponsePlacement.center;
                          },
                          targetColor: Colors.black,
                          onDrop: (tab) {
                            _addTab(
                              tab,
                              widget.pane.tabsData.length,
                            );
                            _lastlyAddedTab = tab;

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
                            _responsePlacement.value =
                                DropResponsePlacement.top;
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
                            _responsePlacement.value =
                                DropResponsePlacement.bottom;
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
                            _responsePlacement.value =
                                DropResponsePlacement.left;
                          },
                          targetColor: Colors.yellow,
                          onDrop: (PaneTab<T> data) {
                            _onDropQuarter(
                                data, Axis.horizontal, HalfPart.start);
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
                            _responsePlacement.value =
                                DropResponsePlacement.right;
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
          ),
        ],
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
