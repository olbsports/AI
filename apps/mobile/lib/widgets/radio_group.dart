import 'package:flutter/material.dart';

/// RadioGroup widget for Flutter 3.32+
/// Wraps RadioListTile children and provides groupValue/onChanged context
class RadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }
}

/// InheritedWidget that provides RadioGroup data to descendants
class RadioGroupScope<T> extends InheritedWidget {
  final T groupValue;
  final ValueChanged<T?>? onChanged;

  const RadioGroupScope({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static RadioGroupScope<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioGroupScope<T>>();
  }

  @override
  bool updateShouldNotify(RadioGroupScope<T> oldWidget) {
    return groupValue != oldWidget.groupValue || onChanged != oldWidget.onChanged;
  }
}
