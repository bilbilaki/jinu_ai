// lib/presentation/widgets/view_long_term_memory_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import '../providers/memory_provider.dart'; // Import the memory provider
import '../../data/models/memory_item.dart'; // Import the memory item model
// Import intl for formatting dates if desired
// import 'package:intl/intl.dart';

class ViewLongTermMemoryDialog extends ConsumerStatefulWidget { // Use ConsumerStatefulWidget
  const ViewLongTermMemoryDialog({super.key});

  @override
  ConsumerState<ViewLongTermMemoryDialog> createState() => _ViewLongTermMemoryDialogState(); // Use ConsumerState
}

class _ViewLongTermMemoryDialogState extends ConsumerState<ViewLongTermMemoryDialog> { // Use ConsumerState
  final TextEditingController _searchController = TextEditingController();
  List<MemoryItem> _filteredItems = []; // State for filtered items

  @override
  void initState() {
    super.initState();
    // Initialize filtered list with all items when dialog opens
    // Access provider via ref (available in initState in ConsumerStatefulWidget)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filteredItems = ref.read(memoryItemsProvider);
        if (mounted) setState(() {}); // Update UI after initial read
      });


    _searchController.addListener(_filterMemoryItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMemoryItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterMemoryItems() {
    final allItems = ref.read(memoryItemsProvider); // Read current list from provider
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredItems = allItems);
    } else {
      setState(() {
        _filteredItems = allItems.where((item) {
          return item.key.toLowerCase().contains(query) || item.content.toLowerCase().contains(query);
        }).toList();
      });
    }
  }


  void _showAddEditMemoryItemDialog({MemoryItem? itemToEdit}) {
    final isEditing = itemToEdit != null;
    final keyController = TextEditingController(text: itemToEdit?.key ?? '');
    final contentController = TextEditingController(text: itemToEdit?.content ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context, // Use the original context
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Memory Item' : 'Add Memory Item', style: const TextStyle(fontSize: 18)),
        contentPadding: const EdgeInsets.all(16), // Adjust padding
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: keyController,
                  decoration: const InputDecoration(labelText: 'Key / Topic', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Key cannot be empty' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content / Value', border: OutlineInputBorder(), isDense: true),
                  maxLines: 5,
                  minLines: 3, // Increase min lines
                  validator: (v) => v == null || v.trim().isEmpty ? 'Content cannot be empty' : null,
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween, // Align actions
        actions: [
          // Delete Button (only when editing)
            if (isEditing)
                TextButton(
                 style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
                 onPressed: () => _confirmDeleteItem(ctx, itemToEdit.id), // Pass outer dialog context and ID
                child: const Text('Delete'),
             ),
           // Spacer or alignment adjustment might be needed based on button presence
           if(!isEditing) const SizedBox.shrink(), // Placeholder if not editing

           Row( // Group Cancel and Save/Add
              children: [
                   TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                   ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    child: Text(isEditing ? 'Save Changes' : 'Add Item'),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Use ref.read inside the action to call service methods
                        final memoryService = ref.read(longTermMemoryServiceProvider);
                        if (isEditing) {
                          final updatedItem = MemoryItem(
                            id: itemToEdit.id,
                            key: keyController.text.trim(),
                            content: contentController.text.trim(),
                            timestamp: itemToEdit.timestamp, // Keep original timestamp or update? Let's update.
                          );
                          memoryService.updateMemoryItem(updatedItem);
                        } else {
                          memoryService.addMemoryManually(
                              keyController.text.trim(), contentController.text.trim());
                        }
                        Navigator.of(ctx).pop(); // Close the add/edit dialog
                        _filterMemoryItems(); // Refresh filtered list
                      }
                    },
                  ),
              ],
           )

        ],
      ),
    );
  }

 // Confirmation Dialog for Deletion
 void _confirmDeleteItem(BuildContext dialogContext, String itemId) {
    showDialog(
        context: context, // Use main build context for the confirmation
        builder: (confirmCtx) => AlertDialog(
           title: const Text('Confirm Delete'),
           content: const Text('Permanently delete this memory item?'),
           actions: [
               TextButton(onPressed: ()=> Navigator.of(confirmCtx).pop(), child: const Text('Cancel')),
                TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                     onPressed: (){
                         // Use ref.read to access service
                        ref.read(longTermMemoryServiceProvider).deleteMemoryItemById(itemId);
                         Navigator.of(confirmCtx).pop(); // Close confirmation dialog
                         Navigator.of(dialogContext).pop(); // Close the add/edit dialog afterwards
                         _filterMemoryItems(); // Refresh filtered list
                    },
                    child: const Text('Delete')
               )
           ]
        )
    );
 }


  @override
  Widget build(BuildContext context) {
    // No need for Consumer widget here, ref is available via ConsumerState

    // Read items directly (filtered list is managed by local state)
    final allItemsCount = ref.watch(memoryItemsProvider).length; // Watch original count for empty state check

    return AlertDialog(
      title: const Text('Long-Term Memory Store'),
      // Use scrollable content area
      content: SizedBox(
        width: double.maxFinite, // Use available width
        height: MediaQuery.of(context).size.height * 0.6, // Max height
        child: Column(
           mainAxisSize: MainAxisSize.min,
            children: [
               // Search Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                     controller: _searchController,
                      decoration: InputDecoration(
                         hintText: "Search memory...",
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          // Add clear button
                           suffixIcon: _searchController.text.isNotEmpty ?
                              IconButton(
                                   icon: const Icon(Icons.clear, size: 18),
                                   tooltip: "Clear search",
                                   onPressed: () {
                                      _searchController.clear(); // This triggers the listener -> _filterMemoryItems
                                  },
                               ) : null,
                      ),
                  ),
                ),
                // List or Empty State
                 Expanded(
                   child: allItemsCount == 0
                       ? const Center(child: Text('No memory items saved yet.'))
                        : _filteredItems.isEmpty
                           ? Center(child: Text('No items match "${_searchController.text}".'))
                           : ListView.builder(
                               shrinkWrap: true, // Important inside SizedBox/Column
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                   final item = _filteredItems[index];
                                   return Card( // Use Card for better visual separation
                                       elevation: 1,
                                       margin: const EdgeInsets.symmetric(vertical: 4),
                                       child: ListTile(
                                           title: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                           subtitle: Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis,),
                                            trailing: Text(
                                               // Format date nicely (requires intl package)
                                               // DateFormat.yMd().format(item.timestamp.toLocal()),
                                                item.timestamp.toLocal().toString().substring(0, 10), // Basic date
                                               style: Theme.of(context).textTheme.bodySmall,
                                           ),
                                           onTap: () => _showAddEditMemoryItemDialog(itemToEdit: item),
                                       ),
                                   );
                                },
                            ),
                 ),
            ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Add Manually'),
          onPressed: () => _showAddEditMemoryItemDialog(), // Launch add dialog
        ),
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}