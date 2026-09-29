import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/storage/box_names.dart';
import '../shared/models/client.dart';
import '../shared/models/client_group.dart';
import '../shared/models/client_type.dart';
import '../shared/models/contact.dart';
import '../shared/models/iv.dart';
import '../shared/models/product_range.dart';

/// Visualisation et gestion des bases de données partagées.
///
/// Les entités définies ici (IV, groupes et types de clients, clients, contacts, gammes) sont communes
/// à tous les modules Sebae et, à terme, aux outils intégrés comme WUECT.
///
/// Convention importante : les entités sont stockées avec leur UUID comme
/// clé Hive (`box.put(id, ...)`), jamais avec la clé auto-incrémentée,
/// afin que les références croisées (Sales Plan, actions...) fonctionnent.
class DataHome extends StatelessWidget {
  const DataHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bases de données partagées'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'IV'),
              Tab(text: 'Clients'),
              Tab(text: 'Contacts'),
              Tab(text: 'Gammes Produits'),
              Tab(text: 'Groupes de clients'),
              Tab(text: 'Types de clients'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _IvTab(),
            _ClientTab(),
            _ContactTab(),
            _ProductRangeTab(),
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
                  leading: CircleAvatar(child: Text(iv.shortLabel)),
                  title: Text(iv.name),
                  subtitle: Text(
                    iv.trigramOrEmpty.isEmpty
                        ? (iv.active ? 'Actif' : 'Inactif')
                        : 'Trigramme : ${iv.trigramOrEmpty} - ${iv.active ? 'Actif' : 'Inactif'}',
                  ),
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
  final nameController = TextEditingController(text: iv?.name ?? '');
  final trigramController = TextEditingController(text: iv?.trigram ?? '');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(iv == null ? 'Nouveau IV' : 'Modifier l\'IV'),
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
            controller: trigramController,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Trigramme (convention société)',
              hintText: 'ex. DBA',
              counterText: '',
            ),
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
    final trigram = trigramController.text.trim().toUpperCase();
    if (iv == null) {
      final newIv = Iv(
        id: uuid.v4(),
        name: nameController.text.trim(),
        trigram: trigram.isEmpty ? null : trigram,
      );
      await box.put(newIv.id, newIv);
    } else {
      iv.name = nameController.text.trim();
      iv.trigram = trigram.isEmpty ? null : trigram;
      await iv.save();
    }
  }
  nameController.dispose();
  trigramController.dispose();
}

// ------------------------------------------------------------ Clients ---

class _ClientTab extends StatelessWidget {
  const _ClientTab();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Client>(BoxNames.clients);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addClient',
        onPressed: () => showClientDialog(context),
        icon: const Icon(Icons.business),
        label: const Text('Client'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Client> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (items.isEmpty) {
            return const _EmptyBox(message: 'Aucun client défini.');
          }
          return ListView(
            children: [
              for (final client in items)
                ListTile(
                  leading: CircleAvatar(child: Text(client.name.isNotEmpty ? client.name[0] : '?')),
                  title: Text(client.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.clientNumber.isNotEmpty)
                        Text('N°: ${client.clientNumber}'),
                      if (client.city.isNotEmpty)
                        Text(client.city),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.contacts),
                        onPressed: () => _showClientContactsDialog(context, client),
                        tooltip: 'Contacts',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showClientDialog(context, client: client),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => client.delete(),
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

Future<void> showClientDialog(BuildContext context, {Client? client}) async {
  const uuid = Uuid();
  final box = Hive.box<Client>(BoxNames.clients);
  final clientGroupsBox = Hive.box<ClientGroup>(BoxNames.clientGroups);
  final clientTypesBox = Hive.box<ClientType>(BoxNames.clientTypes);
  final clientNumberController = TextEditingController(text: client?.clientNumber ?? '');
  final nameController = TextEditingController(text: client?.name ?? '');
  final shortNameController = TextEditingController(text: client?.shortName ?? '');
  final cityController = TextEditingController(text: client?.city ?? '');
  final descController = TextEditingController(text: client?.description ?? '');
  
  // Valeurs sélectionnées pour les dropdowns
  String? selectedGroupId = client?.clientGroupId;
  String? selectedTypeId = client?.clientTypeId;
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(client == null ? 'Nouveau client' : 'Modifier le client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientNumberController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'N° Client',
                  hintText: 'Ex: CLI001',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shortNameController,
                decoration: const InputDecoration(labelText: 'Nom court'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
              const SizedBox(height: 12),
              // Groupe de clients
              DropdownButtonFormField<String?>(
                initialValue: selectedGroupId,
                decoration: const InputDecoration(labelText: 'Groupe de clients'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Aucun groupe'),
                  ),
                  for (final group in clientGroupsBox.values)
                    DropdownMenuItem(
                      value: group.id,
                      child: Text(group.name),
                    ),
                ],
                onChanged: (value) => setState(() => selectedGroupId = value),
              ),
              const SizedBox(height: 12),
              // Type de client
              DropdownButtonFormField<String?>(
                initialValue: selectedTypeId,
                decoration: const InputDecoration(labelText: 'Type de client'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Aucun type'),
                  ),
                  for (final type in clientTypesBox.values)
                    DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    ),
                ],
                onChanged: (value) => setState(() => selectedTypeId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
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
  ),
  );
  if (confirmed == true && nameController.text.trim().isNotEmpty) {
    if (client == null) {
      final newClient = Client(
        id: uuid.v4(),
        name: nameController.text.trim(),
        shortName: shortNameController.text.trim(),
        description: descController.text.trim(),
        address: '',
        postalCode: '',
        city: cityController.text.trim(),
        country: '',
        phone: '',
        email: '',
        website: '',
        sector: '',
        annualRevenue: null,
        employeeCount: null,
        active: true,
        clientNumber: clientNumberController.text.trim(),
        clientGroupId: selectedGroupId,
        clientTypeId: selectedTypeId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await box.put(newClient.id, newClient);
    } else {
      client.clientNumber = clientNumberController.text.trim();
      client.name = nameController.text.trim();
      client.shortName = shortNameController.text.trim();
      client.city = cityController.text.trim();
      client.description = descController.text.trim();
      client.clientGroupId = selectedGroupId;
      client.clientTypeId = selectedTypeId;
      await client.save();
    }
  }
  clientNumberController.dispose();
  nameController.dispose();
  shortNameController.dispose();
  cityController.dispose();
  descController.dispose();
}

/// Dialogue pour afficher et gérer les contacts d'un client.
Future<void> _showClientContactsDialog(BuildContext context, Client client) async {
  final contactsBox = Hive.box<Contact>(BoxNames.contacts);
  
  final clientContacts = contactsBox.values
      .where((c) => c.clientId == client.id)
      .toList()
    ..sort((a, b) => a.lastName.compareTo(b.lastName));

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Contacts de ${client.displayName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (clientContacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aucun contact pour ce client.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: clientContacts.length,
                  itemBuilder: (context, index) {
                    final contact = clientContacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          contact.fullName.isNotEmpty && contact.fullName.isNotEmpty
                              ? contact.fullName[0]
                              : '?',
                        ),
                      ),
                      title: Text(contact.fullName),
                      subtitle: contact.position.isNotEmpty ? Text(contact.position) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          Navigator.pop(context);
                          showContactDialog(context, contact: contact);
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            showContactDialog(context, clientId: client.id);
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Ajouter'),
        ),
      ],
    ),
  );
}

// ----------------------------------------------------------- Contacts ---

/// Helper pour afficher le client associé à un contact.
Widget _buildClientSubtitle(String clientId) {
  final client = Hive.box<Client>(BoxNames.clients).get(clientId);
  if (client == null) return const SizedBox.shrink();
  return Text(
    'Client: ${client.displayName}${client.clientNumber.isNotEmpty ? ' (${client.clientNumber})' : ''}',
    style: const TextStyle(fontSize: 12),
  );
}

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Contact>(BoxNames.contacts);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addContact',
        onPressed: () => showContactDialog(context),
        icon: const Icon(Icons.person),
        label: const Text('Contact'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Contact> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => a.lastName.compareTo(b.lastName));
          if (items.isEmpty) {
            return const _EmptyBox(message: 'Aucun contact défini.');
          }
          return ListView(
            children: [
              for (final contact in items)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${contact.firstName.isNotEmpty ? contact.firstName[0] : ''}${contact.lastName.isNotEmpty ? contact.lastName[0] : ''}'
                    ),
                  ),
                  title: Text('${contact.firstName} ${contact.lastName}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contact.position.isNotEmpty)
                        Text(contact.position),
                      if (contact.clientId != null && contact.clientId!.isNotEmpty)
                        _buildClientSubtitle(contact.clientId!),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showContactDialog(context, contact: contact),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => contact.delete(),
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

Future<void> showContactDialog(BuildContext context, {Contact? contact, String? clientId}) async {
  const uuid = Uuid();
  final box = Hive.box<Contact>(BoxNames.contacts);
  final clientsBox = Hive.box<Client>(BoxNames.clients);
  final firstNameController = TextEditingController(text: contact?.firstName ?? '');
  final lastNameController = TextEditingController(text: contact?.lastName ?? '');
  final positionController = TextEditingController(text: contact?.position ?? '');
  final phoneController = TextEditingController(text: contact?.phone ?? '');
  final emailController = TextEditingController(text: contact?.email ?? '');
  
  // Pour l'affichage du client actuel
  String? selectedClientId = contact?.clientId ?? clientId;
  Client? selectedClient;
  if (selectedClientId != null && selectedClientId.isNotEmpty) {
    selectedClient = clientsBox.get(selectedClientId);
  }
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(contact == null ? 'Nouveau contact' : 'Modifier le contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du client
            DropdownButtonFormField<String>(
              initialValue: selectedClientId,
              decoration: const InputDecoration(labelText: 'Client'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Sélectionner un client'),
                ),
                for (final c in clientsBox.values)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.displayName} (${c.clientNumber})'),
                  ),
              ],
              onChanged: (value) => selectedClientId = value,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: firstNameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Poste'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (selectedClient != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Client actuel: ${selectedClient.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
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
  if (confirmed == true && lastNameController.text.trim().isNotEmpty) {
    if (contact == null) {
      final newContact = Contact(
        id: uuid.v4(),
        clientId: selectedClientId ?? '',
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        position: positionController.text.trim(),
        phone: phoneController.text.trim(),
        mobile: '',
        email: emailController.text.trim(),
        notes: '',
        isPrimary: false,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await box.put(newContact.id, newContact);
    } else {
      contact.firstName = firstNameController.text.trim();
      contact.lastName = lastNameController.text.trim();
      contact.position = positionController.text.trim();
      contact.phone = phoneController.text.trim();
      contact.email = emailController.text.trim();
      if (selectedClientId != null) {
        contact.clientId = selectedClientId;
      }
      await contact.save();
    }
  }
  firstNameController.dispose();
  lastNameController.dispose();
  positionController.dispose();
  phoneController.dispose();
  emailController.dispose();
}

// ------------------------------------------------------- Gammes Produits ---

class _ProductRangeTab extends StatelessWidget {
  const _ProductRangeTab();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ProductRange>(BoxNames.productRanges);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addProductRange',
        onPressed: () => showProductRangeDialog(context),
        icon: const Icon(Icons.category),
        label: const Text('Gamme'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ProductRange> box, _) {
          final items = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (items.isEmpty) {
            return const _EmptyBox(message: 'Aucune gamme de produits définie.');
          }
          return ListView(
            children: [
              for (final range in items)
                ListTile(
                  leading: CircleAvatar(child: Text(range.code.isNotEmpty ? range.code[0] : range.name.isNotEmpty ? range.name[0] : '?')),
                  title: Text(range.name),
                  subtitle: range.code.isNotEmpty ? Text('Code: ${range.code}') : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showProductRangeDialog(context, productRange: range),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => range.delete(),
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

Future<void> showProductRangeDialog(BuildContext context, {ProductRange? productRange}) async {
  const uuid = Uuid();
  final box = Hive.box<ProductRange>(BoxNames.productRanges);
  final nameController = TextEditingController(text: productRange?.name ?? '');
  final codeController = TextEditingController(text: productRange?.code ?? '');
  final descController = TextEditingController(text: productRange?.description ?? '');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(productRange == null ? 'Nouvelle gamme' : 'Modifier la gamme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
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
    if (productRange == null) {
      final newRange = ProductRange(
        id: uuid.v4(),
        name: nameController.text.trim(),
        code: codeController.text.trim(),
        description: descController.text.trim(),
        parentId: null,
        averagePrice: null,
        averageMargin: null,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await box.put(newRange.id, newRange);
    } else {
      productRange.name = nameController.text.trim();
      productRange.code = codeController.text.trim();
      productRange.description = descController.text.trim();
      await productRange.save();
    }
  }
  nameController.dispose();
  codeController.dispose();
  descController.dispose();
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
      final newGroup = ClientGroup(
        id: uuid.v4(),
        name: nameController.text.trim(),
        description: descController.text.trim(),
      );
      await box.put(newGroup.id, newGroup);
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
      final newType = ClientType(id: uuid.v4(), name: controller.text.trim());
      await box.put(newType.id, newType);
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
