import 'package:birlikteyapp/constants/app_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/family_provider.dart';
import '../../providers/task_cloud_provider.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

const String kAllFilter = '__ALL__';

class _TasksPageState extends State<TasksPage> {
  String? _filterMember;

  void _addTaskDialog(BuildContext context) {
    final taskProvider = Provider.of<TaskCloudProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);

    const defaultTasks = AppLists.defaultTasks;

    TextEditingController controller = TextEditingController();
    String? selectedMember;

    final Set<String> suggestionSet = {
      ...taskProvider.suggestedTasks, // sık yapılanlar
      ...defaultTasks, // hazır görevler
      ...taskProvider.tasks.map((t) => t.name), // mevcut listeden
    };

    final List<String> suggestions = suggestionSet
        .where((s) => s.trim().isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Task"),
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
                        hintText: "Enter task (e.g., Do the laundry)",
                        prefixIcon: Icon(Icons.task_alt),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Öneri chip’leri
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
                      onChanged: (val) => setLocalState(() {
                        selectedMember = val;
                      }),
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
                  taskProvider.addTask(
                    Task(text, assignedToUid: selectedMember),
                  );
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
    final taskProvider = Provider.of<TaskCloudProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);

    // 🔎 Filtreleme: _filterMember null ise hepsi
    final List<Task> filteredTasks = _filterMember == null
        ? taskProvider.tasks
        : taskProvider.tasks
              .where((t) => (t.assignedToUid ?? '') == _filterMember)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks"),
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
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];

          return ListTile(
            leading: Checkbox(
              value: task.completed,
              onChanged: (v) => Provider.of<TaskCloudProvider>(
                context,
                listen: false,
              ).toggleTask(task, v ?? false),
            ),
            title: Text(
              task.name +
                  (task.assignedToUid != null
                      ? " (${task.assignedToUid})"
                      : ""),
              style: TextStyle(
                decoration: task.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'assign') {
                  _showAssignSheet(context, task);
                } else if (val == 'delete') {
                  Provider.of<TaskCloudProvider>(
                    context,
                    listen: false,
                  ).removeTask(task);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'assign',
                  child: Text('Assign / Change person'),
                ),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAssignSheet(BuildContext context, Task task) {
    final family = Provider.of<FamilyProvider>(
      context,
      listen: false,
    ).familyMembers;
    final taskProv = Provider.of<TaskCloudProvider>(context, listen: false);
    String? selected = task.assignedToUid;

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
                taskProv.updateAssignment(task, normalized);
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
