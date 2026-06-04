import 'package:flutter/widgets.dart';

import 'app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is not found in widget tree.');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    assert(element != null, 'AppScope is not found in widget tree.');
    return (element!.widget as AppScope).notifier!;
  }
}

class AppStateSelector<T> extends StatefulWidget {
  const AppStateSelector({super.key, required this.selector, required this.builder});
  final T Function(AppState) selector;
  final Widget Function(BuildContext, T, Widget?) builder;

  @override
  State<AppStateSelector<T>> createState() => _AppStateSelectorState<T>();
}

class _AppStateSelectorState<T> extends State<AppStateSelector<T>> {
  late AppState _state;
  late T _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppScope.read(context);
    _state.removeListener(_onStateChanged);
    _state.addListener(_onStateChanged);
    _value = widget.selector(_state);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    final newValue = widget.selector(_state);
    if (newValue != _value) {
      setState(() {
        _value = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value, null);
}
