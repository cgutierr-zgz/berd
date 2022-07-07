// ignore_for_file: inference_failure_on_function_invocation

import 'package:flutter/material.dart';

/// {@template berd}
/// Berd holds the state for creator
/// {@endtemplate}
class Berd<T> {
  /// {@macro berd}
  Berd(this.ref, this.creator) : state = creator.create(ref, creator);

  /// Berd's reference
  final Berdference ref;

  /// Berd's creator
  final BerdCreator<T> creator;

  /// Berd's state
  T state;

  /// Recreates the current berd
  void recreate() {
    final newState = creator.create(ref, creator);
    if (newState != state) {
      state = newState;
      ref._onStateChange(creator);
    }
  }
}

/// {@template berd_creator}
/// BerdCreator creates a stream of T.
/// {@endtemplate}
class BerdCreator<T> {
  /// {@macro berd_creator}
  const BerdCreator(this.create);

  /// Creates a Berd from a BerdReference
  final T Function(Berdference ref, BerdCreator<T> self) create;
  Berd<T> _createElement(Berdference ref) => Berd<T>(ref, this);
}

/// {@template berd_ref}
/// Berdference holds the creator states and dependencies.
/// {@endtemplate}
class Berdference {
  /// {@macro berd_ref}
  Berdference();

  /// Creator which holds state.
  final Map<BerdCreator<dynamic>, Berd<dynamic>> _elements = {};

  /// Dependency graph. Think this as a directional graph.
  /// A -> [B, C] means if A changes, B and C need change too.
  final Map<BerdCreator<dynamic>, Set<BerdCreator<dynamic>>> _graph = {};

  /// Get or create an element for the given creator.
  Berd<dynamic> _element<T>(BerdCreator<dynamic> creator) {
    return _elements.putIfAbsent(creator, () => creator._createElement(this));
  }

  /// Add an edge creator -> watcher to the graph, then return creator's state.
  T watch<T>(BerdCreator<T> creator, BerdCreator<dynamic>? watcher) {
    if (watcher != null) {
      (_graph[creator] ??= {}).add(watcher);
    }
    return _element<T>(creator).state as T;
  }

  /// Set state of the creator.
  void set<T>(BerdCreator<T> creator, T state) {
    final element = _element<T>(creator);
    if (state != element.state) {
      element.state = state;
      _onStateChange(creator);
    }
  }

  /// Set state of creator using an update function. See [set]
  void update<T>(BerdCreator<T> creator, T Function(T) update) {
    set<T>(creator, update(_element(creator).state as T));
  }

  /// Propagate state changes.
  void _onStateChange(BerdCreator<dynamic> creator) {
    for (final c in _graph[creator] ?? {}) {
      _element(c as BerdCreator).recreate();
    }
  }

  /// Delete the creator if it has no watcher. Also delete other creators who
  /// loses all their watchers.
  void dispose(BerdCreator<dynamic> creator) {
    if ((_graph[creator] ?? {}).isNotEmpty) {
      return; // The creator is being watched by someone, cannot dispose it.
    }
    _elements.remove(creator);
    _graph.remove(creator);
    for (final c in _elements.keys.toSet()) {
      if ((_graph[c] ?? {}).contains(creator)) {
        _graph[c]!.remove(creator);
        dispose(c); // Dispose c if creator is the only watcher of c.
      }
    }
  }

  /// Recreate the state of a creator. It is typically used when things outside
  /// the graph changes. For example, click to retry after a network error.
  /// If you use this method in a creative way, let us know.
  void recreate<T>(BerdCreator<T> creator) {
    _element<T>(creator).recreate();
  }
}

/// {@template berd_watcher}
/// Watch creators to build a widget.
/// {@endtemplate}
class BerdWatcher extends StatefulWidget {
  /// {@macro berd_watcher}
  const BerdWatcher(this.builder, {super.key});

  /// Allows watching creators to populate a widget.
  final Widget Function(
    BuildContext context,
    Berdference ref,
    BerdCreator<dynamic> self,
  )? builder;

  @override
  State<BerdWatcher> createState() => _BerdWatcherState();
}

class _BerdWatcherState extends State<BerdWatcher> {
  late BerdCreator<Widget> builder;
  late Berdference ref;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref = BerdCreatorGraph.of(context).ref; // Save ref to use in dispose.
    builder = BerdCreator((ref, self) {
      setState(() {});
      return widget.builder!(context, ref, self);
    });
  }

  @override
  void dispose() {
    ref.dispose(builder);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.recreate(builder);
    return ref.watch(builder, null);
  }
}

/// {@template berd_extension}
/// Allows access to a BerdReference from current context.
/// {@endtemplate}
extension ContextRef on BuildContext {
  /// {@macro berd_extension}
  Berdference get ref => BerdCreatorGraph.of(this).ref;
}

/// {@template berd_c_graph}
/// Simply expose Red trough context.
/// {@endtemplate}
class BerdCreatorGraph extends InheritedWidget {
  /// {@macro berd_c_graph}
  BerdCreatorGraph({super.key, required super.child}) : ref = Berdference();

  /// Current BerdReference.
  final Berdference ref;

  /// {@macro berd_c_graph}
  static BerdCreatorGraph of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BerdCreatorGraph>()!;
  }

  @override
  bool updateShouldNotify(BerdCreatorGraph oldWidget) => ref != oldWidget.ref;
}
