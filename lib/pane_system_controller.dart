import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:panels_system/model/pane_tree.dart';
import 'package:panels_system/pane_system.dart';

class PaneSystemController<T extends PaneTabData<T>> {
  PaneSystemController(this.tree);

  PaneTree<T> tree;

  ValueChanged<PaneTreeElement<T>>? _onRootChanged;
  final _treeElementNotifiers =
      <String, List<ValueChanged<PaneTreeElement<T>>>>{};

  void dispose() {
    _onRootChanged = null;
    _treeElementNotifiers.clear();
  }

  void unregisterAsTreeRoot() {
    _onRootChanged = null;
  }

  void registerAsTreeRoot(
    ValueChanged<PaneTreeElement<T>> onRootChanged,
  ) {
    _onRootChanged = onRootChanged;
  }

  void registerAsWidgetForElement(
    String elementId,
    ValueChanged<PaneTreeElement<T>> onElementChanged,
  ) {
    logger.d('Registered $elementId');
    _treeElementNotifiers.update(
      elementId,
      (v) => v..add(onElementChanged),
      ifAbsent: () => [onElementChanged],
    );
  }

  void onWidgetDispose(
    String elementId,
    ValueChanged<PaneTreeElement<T>> onElementChanged,
  ) {
    logger.d('Unregistered $elementId');
    _treeElementNotifiers.update(
      elementId,
      (v) => v..remove(onElementChanged),
    );
    if(_treeElementNotifiers[elementId]?.isEmpty ?? false) {
      _treeElementNotifiers.remove(elementId);
    }
  }

  void removePane(Pane<T> element) {

    if(element == tree.root) {
      // TODO: Replace with empty root to have empty pane layout.
      return;
    }

    final elementParent = _findElementParent(
      element.id,
      tree.root,
      null,
    );

    // Should not happen
    if (elementParent == null) {
      return;
    }

    final elementToKeep = elementParent.child1 == element
        ? elementParent.child2
        : elementParent.child1;

    replaceElement(elementParent, elementToKeep);
  }

  void replaceElement(
    PaneTreeElement<T> element,
    PaneTreeElement<T> newElement,
  ) {
    final replaceResult = _replaceElement(element, newElement, []);
    final shouldReplaceRoot = replaceResult.treeFromElementParent != tree.root;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        if (shouldReplaceRoot) {
          _onRootChanged?.call(replaceResult.treeFromElementParent);
        }
        tree = PaneTree(root: replaceResult.treeFromElementParent);
        for (final notifier in replaceResult.notifiersToCall) {
          notifier();
        }
      },
    );
  }

  /// Replaces element by newElement in the tree and returns new element's
  /// updated parent or the new element if element is root
  ({
    PaneTreeElement<T> treeFromElementParent,
    List<VoidCallback> notifiersToCall
  }) _replaceElement(
    PaneTreeElement<T> element,
    PaneTreeElement<T> newElement,
    List<VoidCallback> notifiersToCall,
  ) {
    if (element.id == tree.root.id) {
      return (
        treeFromElementParent: newElement,
        notifiersToCall: notifiersToCall
      );
    }
    final elementParent = _findElementParent(
      element.id,
      tree.root,
      null,
    );
    // Element does not have parent and is not root, should not happen,
    // return element;
    if (elementParent == null) {
      return (
        treeFromElementParent: element,
        notifiersToCall: notifiersToCall,
      );
    }
    final PaneTreeNode<T> newParent;
    switch (elementParent) {
      case HorizontalPaneTreeNode<T>(
          child1: final child1,
          child2: final child2,
          size: final size,
          id: final id,
        ):
        if (child1 == element) {
          newParent = HorizontalPaneTreeNode<T>(
            size: size,
            child1: newElement,
            child2: child2,
            id: id,
          );
        } else {
          newParent = HorizontalPaneTreeNode<T>(
            size: size,
            child1: child1,
            child2: newElement,
            id: id,
          );
        }

      case VerticalPaneTreeNode<T>(
          child1: final child1,
          child2: final child2,
          size: final size,
          id: final id,
        ):
        if (child1 == element) {
          newParent = VerticalPaneTreeNode<T>(
            size: size,
            child1: newElement,
            child2: child2,
            id: id,
          );
        } else {
          newParent = VerticalPaneTreeNode<T>(
            size: size,
            child1: child1,
            child2: newElement,
            id: id,
          );
        }
    }
    final updatedNotifierList = [...notifiersToCall];
    // If parent changed, notify parent
    if (elementParent != newParent) {
      updatedNotifierList.insert(
        0,
        () {
          _treeElementNotifiers[newParent.id]
              ?.forEach((listener) => listener(newParent));
        },
      );
    } else if (newElement != element) {
      // If only element changed, notify element
      updatedNotifierList.insert(
        0,
        () {
          _treeElementNotifiers[element.id]
              ?.forEach((listener) => listener(newElement));
        },
      );
    }
    return _replaceElement(
      elementParent,
      newParent,
      updatedNotifierList,
    );
  }

  PaneTreeNode<T>? _findElementParent(
    String elementId,
    PaneTreeElement<T> currentElement,
    PaneTreeNode<T>? parentElement,
  ) {
    // Found element, return its parent
    if (currentElement.id == elementId) return parentElement;
    switch (currentElement) {
      case Pane<T>():
        return null;
      case PaneTreeNode<T>():
        return _findElementParent(
              elementId,
              currentElement.child1,
              currentElement,
            ) ??
            _findElementParent(
              elementId,
              currentElement.child2,
              currentElement,
            );
    }
  }
}
