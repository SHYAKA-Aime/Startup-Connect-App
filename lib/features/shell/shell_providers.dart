import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tab of the student shell; in Riverpod so other screens can switch tabs.
final studentTabProvider = StateProvider<int>((ref) => 0);
