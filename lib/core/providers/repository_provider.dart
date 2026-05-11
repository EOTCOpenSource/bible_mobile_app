import 'package:flutter/material.dart';
import '../../data/repository/bible_repository.dart';

class BibleRepositoryProvider extends InheritedWidget {
  const BibleRepositoryProvider({
    super.key,
    required this.repository,
    required super.child,
  });

  final BibleRepository repository;

  static BibleRepository of(BuildContext context) {
    final p = context.getInheritedWidgetOfExactType<BibleRepositoryProvider>();
    assert(p != null, 'No BibleRepositoryProvider found. Wrap your app with BibleRepositoryProvider().');
    return p!.repository;
  }

  @override
  bool updateShouldNotify(BibleRepositoryProvider oldWidget) => false;
}
