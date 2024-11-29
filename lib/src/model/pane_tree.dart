import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Abstract class that defines data for a pane tab.
///
/// Recommendation is to set [id] to [PaneTabData.autoIncrement].
///
/// Implement this class to provide your own data for building a tab.
abstract class PaneTabData<T extends PaneTabData<T>> extends Equatable
    implements PaneTab<T> {
  const PaneTabData({required this.id, this.visible = true});

  static int _idIncrement = 0;

  /// Id generator to ensure tab id uniqueness.
  static String get autoIncrement => '${_idIncrement++}';

  /// Id of the tab.
  ///
  /// Consider setting this to [PaneTabData.autoIncrement].
  @override
  final String id;

  /// Whether the tab holding this data should be visible or not.
  ///
  /// This does not need to be set by clients of this package in methods other
  /// than [copyWithVisibility].
  @override
  final bool visible;

  /// Method used by the library internally to manage tab visibility.
  ///
  /// Implementations should return the exact same object's value with [visible]
  /// set to [visibility].
  @override
  T copyWithVisibility(bool visibility);

  @override
  List<Object?> get props => [id, visible];
}

class PaneTree<T extends PaneTabData<T>> {
  PaneTree({required this.root});

  final PaneTreeElement<T> root;
}

sealed class PaneTreeElement<T extends PaneTabData<T>> extends Equatable {
  const PaneTreeElement({required this.size, required this.id});

  final String id;
  final Size size;

  @override
  List<Object?> get props => [id, size];
}

sealed class PaneTreeNode<T extends PaneTabData<T>> extends PaneTreeElement<T> {
  const PaneTreeNode({
    required super.size,
    required this.child1,
    required this.child2,
    required super.id,
  });

  final PaneTreeElement<T> child1;
  final PaneTreeElement<T> child2;

  @override
  List<Object?> get props => [...super.props, child1.id, child2.id];
}

class HorizontalPaneTreeNode<T extends PaneTabData<T>> extends PaneTreeNode<T> {
  const HorizontalPaneTreeNode({
    required super.size,
    required super.child1,
    required super.child2,
    required super.id,
  });
}

class VerticalPaneTreeNode<T extends PaneTabData<T>> extends PaneTreeNode<T> {
  const VerticalPaneTreeNode({
    required super.size,
    required super.child1,
    required super.child2,
    required super.id,
  });
}

class Pane<T extends PaneTabData<T>> extends PaneTreeElement<T> {
  const Pane({
    required super.size,
    required this.tabsData,
    required super.id,
  });

  final List<PaneTab<T>> tabsData;

  @override
  List<Object?> get props => [...super.props, tabsData];

  Pane<T> copyWithTabs(List<PaneTab<T>> tabs) => Pane<T>(
        id: id,
        size: size,
        tabsData: tabs,
      );
}

sealed class PaneTab<T> {
  String get id;

  bool get visible;

  PaneTab<T> copyWithVisibility(bool visibility);
}

class EmptyTab<T> extends Equatable implements PaneTab<T> {
  const EmptyTab({required this.id, required this.visible});

  @override
  final String id;

  @override
  final bool visible;

  @override
  EmptyTab<T> copyWithVisibility(bool visibility) => EmptyTab(
        id: id,
        visible: visibility,
      );

  @override
  List<Object?> get props => [id, visible];
}
