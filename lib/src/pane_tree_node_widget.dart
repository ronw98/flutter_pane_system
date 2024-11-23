// import 'package:flutter/material.dart';
// import 'package:panels_system/model/pane_tree.dart';
// import 'package:flutter_resizable_container/flutter_resizable_container.dart';
//
// class PaneTreeElementWidget<T extends PaneTabData<T>> extends StatelessWidget {
//   const PaneTreeElementWidget({super.key, required this.element});
//
//   final PaneTreeElement element;
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     throw UnimplementedError();
//   }
// }
//
// class PaneTreeNodeWidget<T extends PaneTabData<T>> extends StatefulWidget {
//   const PaneTreeNodeWidget({
//     super.key,
//     required this.node,
//   });
//
//   final PaneTreeNode node;
//
//   @override
//   State<PaneTreeNodeWidget<T>> createState() => _PaneTreeNodeWidgetState<T>();
// }
//
// class _PaneTreeNodeWidgetState<T extends PaneTabData<T>>
//     extends State<PaneTreeNodeWidget<T>> {
//   void replaceChild(PaneTreeElement oldChild, PaneTreeElement newChild) {
//     if (widget.node.child1 == oldChild) {
//       setState(() {
//         widget.node.child1 == newChild;
//       });
//     }
//     if (widget.node.child2 == oldChild) {
//       setState(() {
//         widget.node.child2 == newChild;
//       });
//     }
//   }
//
//   void removeChild(PaneTreeElement child) {
//     final childToKeep =
//         child == widget.node.child1 ? widget.node.child2 : widget.node.child1;
//
//     PaneControllerProvider.of(context).replaceElement(widget.node, childToKeep);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PaneControllerProvider(
//       removeElement: removeChild,
//       replaceElement: replaceChild,
//       child: ResizableContainer(
//         direction: widget.node is HorizontalPaneTreeNode
//             ? Axis.horizontal
//             : Axis.vertical,
//         children: [
//           ResizableChild(
//             child: PaneTreeElementWidget(element: widget.node.child1),
//           ),
//           ResizableChild(
//             child: PaneTreeElementWidget(element: widget.node.child2),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class PaneControllerProvider<T extends PaneTabData> extends InheritedWidget {
//   const PaneControllerProvider({
//     super.key,
//     required super.child,
//     required this.replaceElement,
//     required this.removeElement,
//   });
//
//   final void Function(
//     PaneTreeElement oldElement,
//     PaneTreeElement newElement,
//   ) replaceElement;
//   final void Function(PaneTreeElement element) removeElement;
//
//   static PaneControllerProvider<T> of<T extends PaneTabData>(
//     BuildContext context,
//   ) {
//     final result =
//         context.dependOnInheritedWidgetOfExactType<PaneControllerProvider<T>>();
//     assert(
//         result != null, '_PaneControllerProvider not fond in the widget tree');
//     return result!;
//   }
//
//   @override
//   bool updateShouldNotify(PaneControllerProvider<T> oldWidget) {
//     return oldWidget.replaceElement != replaceElement ||
//         oldWidget.removeElement != removeElement;
//   }
// }
