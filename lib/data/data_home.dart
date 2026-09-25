import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/storage/box_names.dart';
import '../shared/models/client_group.dart';
import '../shared/models/client_type.dart';
import '../shared/models/iv.dart';

/// Visualisation et gestion des bases de données partagées.
///
/// Les entités définies ici (IV, groupes et types de clients) sont communes
/// à tous les modules Sebae et, à terme, aux outils intégrés comme WUECT.
class DataHome extends StatelessWidget {
  const DataHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bases de données partagées'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'IV'),
              Tab(text: 'Groupes de clients'),
              Tab(text: 'Types de clients'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _IvTab(),
            _ClientGroupTab(),
            _ClientTypeTab(),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- IV ---

class _IvTab extends StatelessWidget {
  const _IvTab();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Iv>(BoxNames.ivs);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addIv',
        onPressed: () => showIvDialog(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('IV'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Iv> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (items.isEmpty) {
            return const _EmptyBox(message: 'Aucun IV défini.');
          }
          return ListView(
            children: [
              for (final iv in items)
                ListTile(
                  leading: CircleAvatar(child: Text(iv.name.isNotEmpty ? iv.name[0] : '?')),
                  title: Text(iv.name),
                  subtitle: Text(iv.active ? 'Actif' : 'Inactif'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: iv.active,
                        onChanged: (v) {
                          iv.active = v;
                          iv.save();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showIvDialog(context, iv: iv),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => iv.delete(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showIvDialog(BuildContext context, {Iv? iv}) async {
  const uuid = Uuid();
  final box = Hive.box<Iv>(BoxNames.ivs);
  final controller = TextEditingController(text: iv?.name ?? '');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(iv == null ? 'Nouveau IV' : 'Modifier l\'IV'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
  if (confirmed == true && controller.text.trim().isNotEmpty) {
    if (iv == null) {
      await box.add(Iv(id: uuid.v4(), name: controller.text.trim()));
    } else {
      iv.name = controller.text.trim();
      await iv.save();
    }
  }
  controller.dispose();
}

// ---------------------------------------------------------- Groupes clients ---

class _ClientGroupTab extends StatelessWidget {
  const _ClientGroupTab();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ClientGroup>(BoxNames.clientGroups);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addGroup',
        onPressed: () => showClientGroupDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Groupe'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ClientGroup> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (items.isEmpty) {
            return const _EmptyBox(message: 'Aucun groupe de clients défini.');
          }
          return ListView(
            children: [
              for (final group in items)
                ListTile(
                  title: Text(group.name),
                  subtitle: group.description.isEmpty ? null : Text(group.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showClientGroupDialog(context, group: group),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => group.delete(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showClientGroupDialog(BuildContext context, {ClientGroup? group}) async {
  const uuid = Uuid();
  final box = Hive.box<ClientGroup>(BoxNames.clientGroups);
  final nameController = TextEditingController(text: group?.name ?? '');
  final descController = TextEditingController(text: group?.description ?? '');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(group == null ? 'Nouveau groupe de clients' : 'Modifier le groupe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
  if (confirmed == true && nameController.text.trim().isNotEmpty) {
    if (group == null) {
      await box.add(ClientGroup(
        id: uuid.v4(),
        name: nameController.text.trim(),
        description: descController.text.trim(),
      ));
    } else {
      group.name = nameController.text.trim();
      group.description = descController.text.trim();
      await group.save();
    }
  }
  nameController.dispose();
  descController.dispose();
}

// ------------------------------------------------------------ Types clients ---

class _ClientTypeTab extends StatelessWidget {
  const _ClientTypeTab();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ClientType>(BoxNames.clientTypes);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addType',
        onPressed: () => showClientTypeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Type'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ClientType> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (items.isEmpty) {
            return const _EmptyBox(message: 'Aucun type de clients défini.');
          }
          return ListView(
            children: [
              for (final type in items)
                ListTile(
                  title: Text(type.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showClientTypeDialog(context, type: type),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => type.delete(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showClientTypeDialog(BuildContext context, {ClientType? type}) async {
  const uuid = Uuid();
  final box = Hive.box<ClientType>(BoxNames.clientTypes);
  final controller = TextEditingController(text: type?.name ?? '');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(type == null ? 'Nouveau type de clients' : 'Modifier le type'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
  if (confirmed == true && controller.text.trim().isNotEmpty) {
    if (type == null) {
      await box.add(ClientType(id: uuid.v4(), name: controller.text.trim()));
    } else {
      type.name = controller.text.trim();
      await type.save();
    }
  }
  controller.dispose();
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).disabledColor),
      ),
    );
  }
}
