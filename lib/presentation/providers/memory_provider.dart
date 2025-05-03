// lib/presentation/providers/memory_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/long_term_memory_service.dart'; // Adjust path
import '../../data/models/memory_item.dart'; // Adjust path

// Provider for the LongTermMemoryService instance (ChangeNotifier based)
final longTermMemoryServiceProvider =
    ChangeNotifierProvider<LongTermMemoryService>((ref) {
  // Constructor handles initialization and loading from prefs
  return LongTermMemoryService();
});

// Provider to get the list of all memory items
final memoryItemsProvider = Provider<List<MemoryItem>>((ref) {
  final memoryService = ref.watch(longTermMemoryServiceProvider);
  return memoryService.memoryItems;
});