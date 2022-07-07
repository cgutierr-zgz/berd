import 'package:flutter/material.dart';

/// Berd holds the state for creator
class Berd<T> {
  Berd(this.ref, this.creator) : state = creator.create(ref, creator);
  final Berdference ref;
  final BerdCreator<T> creator;
  T state;

  void recreate() {
    final newState = creator.create(ref, creator);
    if (newState != state) {
      state = newState;
      ref._onStateChange(creator);
    }
  }
}

/// Creator creates a stream of T.
class BerdCreator<T> {
  const BerdCreator(this.create);
  final T Function(Berdference ref, BerdCreator<T> self) create;
  Berd<T> _createElement(Berdference ref) => Berd<T>(ref, this);
}

/// Ref holds the creator states and dependencies
class Berdference {
  Berdference();

  /// Creator which holds state.
  final Map<BerdCreator, Berd> _elements = {};

  /// Dependency graph. Think this as a directional graph.
  /// A -> [B, C] means if A changes, B and C need change too.
  final Map<BerdCreator, Set<BerdCreator>> _graph = {};

  /// Get or create an element for the given creator.
  Berd _element<T>(BerdCreator creator) {
    return _elements.putIfAbsent(creator, () => creator._createElement(this));
  }

  /// Add an edge creator -> watcher to the graph, then return creator's state.
  T watch<T>(BerdCreator<T> creator, BerdCreator? watcher) {
    if (watcher != null) {
      (_graph[creator] ??= {}).add(watcher);
    }
    return _element<T>(creator).state;
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
    set<T>(creator, update(_element(creator).state));
  }

  /// Propagate state changes.
  void _onStateChange(BerdCreator creator) {
    for (final c in _graph[creator] ?? {}) {
      _element(c).recreate();
    }
  }

  /// Delete the creator if it has no watcher. Also delete other creators who
  /// loses all their watchers.
  void dispose(BerdCreator creator) {
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

/// Watcher is a widget which watches a creator and displays the creator's state.

/// Watch creators to build a widget.
class BerdWatcher extends StatefulWidget {
  const BerdWatcher(this.builder, {Key? key}) : super(key: key);

  /// Allows watching creators to populate a widget.
  final Widget Function(
      BuildContext context, Berdference ref, BerdCreator self)? builder;

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

extension ContextRef on BuildContext {
  Berdference get ref => BerdCreatorGraph.of(this).ref;
}

class BerdCreatorGraph extends InheritedWidget {
  BerdCreatorGraph({Key? key, required Widget child})
      : ref = Berdference(),
        super(key: key, child: child);

  final Berdference ref;

  static BerdCreatorGraph of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BerdCreatorGraph>()!;
  }

  @override
  bool updateShouldNotify(BerdCreatorGraph oldWidget) => ref != oldWidget.ref;
}
