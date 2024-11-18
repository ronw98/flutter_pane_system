// import 'package:flutter/material.dart';
// import 'package:panels_system/model/pane_tree.dart';
// import 'package:panels_system/pane_tree_node_widget.dart';
//
// class PaneManager<T extends PaneTabData<T>> extends StatelessWidget {
//   const PaneManager({
//     super.key,
//     required this.tabViewBuilder,
//     required this.tabBuilder,
//     required this.paneTree,
//   });
//
//   final Widget Function(BuildContext context, T tabData) tabViewBuilder;
//   final Widget Function(BuildContext context, T tabData) tabBuilder;
//   final PaneTree<T> paneTree;
//
//   @override
//   Widget build(BuildContext context) {
//     return PaneTreeElementWidget(element: paneTree.root);
//   }
// }
//
// typedef TabDataBuilder<T extends PaneTabData<T>> = Widget Function(
//     BuildContext context, T tabData);
//
// class PaneManagerProvider<T extends PaneTabData<T>> extends InheritedWidget {
//   const PaneManagerProvider({
//     super.key,
//     required super.child,
//     required TabDataBuilder<T> tabViewBuilder,
//     required TabDataBuilder<T> tabBuilder,
//   })  : _tabBuilder = tabBuilder,
//         _tabViewBuilder = tabViewBuilder;
//
//   static PaneManagerProvider of<T extends PaneTabData<T>>(BuildContext context) {
//     final PaneManagerProvider? result =
//         context.dependOnInheritedWidgetOfExactType<PaneManagerProvider<T>>();
//     assert(result != null, 'No PaneManagerProvider found in context');
//     return result!;
//   }
//
//   Widget tabViewBuilder(BuildContext context, T data) {
//     return _tabViewBuilder(context, data);
//   }
//
//   Widget tabBuilder(BuildContext context, T data) {
//     return _tabBuilder(context, data);
//   }
//   final TabDataBuilder<T> _tabViewBuilder;
//   final TabDataBuilder<T> _tabBuilder;
//
//   @override
//   bool updateShouldNotify(PaneManagerProvider<T> oldWidget) {
//     return oldWidget._tabBuilder != _tabBuilder ||
//         oldWidget._tabViewBuilder != _tabViewBuilder;
//   }
// }
