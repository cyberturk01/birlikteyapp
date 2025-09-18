import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/item.dart';
import '../../providers/family_provider.dart';
import '../../providers/item_cloud_provider.dart';

class MarketPage extends StatefulWidget {
  @override
  _MarketPageState createState() => _MarketPageState();
}

const String kAllFilter = '__ALL__';

class _MarketPageState extends State<MarketPage> {
  String? _filterMember;

  void _addItemDialog(BuildContext context) {
    final itemProvider = Provider.of<ItemCloudProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);

    const defaultItems = [
      "Milk",
      "Bread",
      "Eggs",
      "Butter",
      "Cheese",
      "Rice",
      "Pasta",
      "Tomatoes",
      "Potatoes",
      "Onions",
      "Apples",
      "Bananas",
      "Chicken",
      "Beef",
      "Fish",
      "Olive oil",
      "Salt",
      "Sugar",
      "Coffee",
      "Tea",
    ];

    TextEditingController controller = TextEditingController();
    String? selectedMember;

    final Set<String> suggestionSet = {
      ...itemProvider.frequentItems, // sık eklenenler
      ...defaultItems, // hazır liste
      ...itemProvider.items.map((e) => e.name), // mevcutlardan
    };
    final List<String> suggestions = suggestionSet
        .where((s) => s.trim().isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Item"),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Enter item (e.g., Milk)",
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Öneri chip'leri
                    if (suggestions.isNotEmpty) ...[
                      const Text("Suggestions"),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: suggestions.map((name) {
                          return ActionChip(
                            label: Text(name),
                            onPressed: () {
                              setLocalState(() {
                                controller.text = name;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Kişi atama
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Assign to (Optional)",
                        prefixIcon: Icon(Icons.person),
                      ),
                      value: selectedMember,
                      items: familyProvider.familyMembers
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setLocalState(() => selectedMember = val),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add"),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  itemProvider.addItem(Item(text, assignedTo: selectedMember));
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemCloudProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);

    final List<Item> filteredItems = _filterMember == null
        ? itemProvider.items
        : itemProvider.items
              .where((i) => (i.assignedTo ?? '') == _filterMember)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Market List"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterMember = (value == kAllFilter) ? null : value;
              });
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem(value: kAllFilter, child: Text("All")),
              ...familyProvider.familyMembers.map(
                (m) => PopupMenuItem(value: m, child: Text(m)),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];

          return ListTile(
            leading: Checkbox(
              value: item.bought,
              onChanged: (v) => Provider.of<ItemCloudProvider>(
                context,
                listen: false,
              ).toggleItem(item, v ?? false),
            ),
            title: Text(
              item.name +
                  (item.assignedTo != null ? " (${item.assignedTo})" : ""),
              style: TextStyle(
                decoration: item.bought ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'assign') {
                  _showAssignItemSheet(context, item);
                } else if (val == 'delete') {
                  Provider.of<ItemCloudProvider>(
                    context,
                    listen: false,
                  ).removeItem(item);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'assign',
                  child: Text('Assign / Change person'),
                ),
                PopupMenuItem(value: 'delete', child: Text(S.delete)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAssignItemSheet(BuildContext context, Item item) {
    final family = Provider.of<FamilyProvider>(
      context,
      listen: false,
    ).familyMembers;
    final itemProv = Provider.of<ItemCloudProvider>(context, listen: false);
    String? selected = item.assignedTo;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Assign to',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selected,
              items: [
                const DropdownMenuItem(value: null, child: Text('No one')),
                ...family.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m)),
                ),
              ],
              onChanged: (v) {
                selected = v;
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final normalized =
                    (selected != null && selected!.trim().isNotEmpty)
                    ? selected
                    : null;
                itemProv.updateAssignment(item, normalized);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
