import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../models/one2one_meeting.dart';
import '../models/one2one_task.dart';
import '../services/one2one_service.dart';

class One2OneHome extends StatefulWidget {
  const One2OneHome({super.key});

  @override
  State<One2OneHome> createState() => _One2OneHomeState();
}

class _One2OneHomeState extends State<One2OneHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final One2OneService _service = One2OneService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _service.addListener(_onChanged);
    _tabs.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _createMeeting() async {
    final titleController = TextEditingController();
    final peopleController = TextEditingController();
    DateTime date = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau One2One'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre / sujet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: peopleController,
                  decoration: const InputDecoration(
                    labelText: 'Collègues / directeur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(DateFormat('dd MMM yyyy', 'fr_FR').format(date)),
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
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      await _service.createMeeting(
        title: titleController.text,
        people: peopleController.text,
        date: date,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One2One'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.forum_outlined), text: 'Mes One2One'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Vue globale'),
          ],
        ),
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: _createMeeting,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau'),
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          _MeetingsList(service: _service),
          _GlobalProgress(service: _service),
        ],
      ),
    );
  }
}

class _MeetingsList extends StatelessWidget {
  const _MeetingsList({required this.service});
  final One2OneService service;

  @override
  Widget build(BuildContext context) {
    final meetings = service.meetings;
    if (meetings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_outlined, size: 64),
            SizedBox(height: 12),
            Text('Aucun One2One pour le moment'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        final percent = (meeting.progress * 100).round();
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            leading: CircleAvatar(
              child: Text('$percent%'),
            ),
            title: Text(meeting.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(meeting.people.isEmpty ? 'Participant non renseigné' : meeting.people),
                Text(DateFormat('dd MMM yyyy', 'fr_FR').format(meeting.date)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: meeting.progress),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _MeetingDetail(meeting: meeting, service: service),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlobalProgress extends StatelessWidget {
  const _GlobalProgress({required this.service});
  final One2OneService service;

  @override
  Widget build(BuildContext context) {
    final meetings = service.meetings;
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Avancement global', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: service.overallProgress, minHeight: 12),
                const SizedBox(height: 8),
                Text('${(service.overallProgress * 100).round()} % — ${service.completedTasks} sur ${service.totalTasks} tâches terminées'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard('One2One', meetings.length.toString(), Icons.groups_outlined, colorScheme.primary),
            _MetricCard('En cours', service.inProgressTasks.toString(), Icons.play_circle_outline, Colors.blue),
            _MetricCard('En attente', service.waitingTasks.toString(), Icons.pause_circle_outline, Colors.orange),
            _MetricCard('Terminées', service.completedTasks.toString(), Icons.check_circle_outline, Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        Text('Avancement par One2One', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final meeting in meetings)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meeting.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: meeting.progress),
                  const SizedBox(height: 6),
                  Text('${meeting.completedCount}/${meeting.tasks.length} terminée(s)'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingDetail extends StatefulWidget {
  const _MeetingDetail({required this.meeting, required this.service});
  final One2OneMeeting meeting;
  final One2OneService service;

  @override
  State<_MeetingDetail> createState() => _MeetingDetailState();
}

class _MeetingDetailState extends State<_MeetingDetail> {
  Future<void> _pickPresentation() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pptx', 'ppt'],
    );
    if (result.isEmpty) return;
    final filePath = result.first.path;
    if (filePath == null) return;

    await widget.service.importPresentation(widget.meeting, filePath);
    if (mounted) setState(() {});
  }

  Future<void> _editMeeting() async {
    final titleController = TextEditingController(text: widget.meeting.title);
    final peopleController = TextEditingController(text: widget.meeting.people);
    DateTime date = widget.meeting.date;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le One2One'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre / sujet', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: peopleController,
                  decoration: const InputDecoration(labelText: 'Collègues / directeur', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(DateFormat('dd MMM yyyy', 'fr_FR').format(date)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );

    if (result == true) {
      widget.meeting.title = titleController.text.trim();
      widget.meeting.people = peopleController.text.trim();
      widget.meeting.date = date;
      await widget.service.updateMeeting(widget.meeting);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editTask({One2OneTask? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final commentsController = TextEditingController(text: existing?.comments ?? '');
    One2OneTaskStatus status = existing?.status ?? One2OneTaskStatus.inProgress;
    DateTime? dueDate = existing?.dueDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nouvelle tâche' : 'Modifier la tâche'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tâche', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentsController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Commentaires', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<One2OneTaskStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder()),
                    items: One2OneTaskStatus.values
                        .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => dueDate = picked);
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(dueDate == null
                        ? 'Ajouter une échéance'
                        : DateFormat('dd MMM yyyy', 'fr_FR').format(dueDate!)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      if (existing == null) {
        widget.service.addTask(widget.meeting, titleController.text, commentsController.text, status, dueDate);
      } else {
        existing.title = titleController.text.trim();
        existing.comments = commentsController.text.trim();
        existing.status = status;
        existing.dueDate = dueDate;
        widget.service.updateTask(widget.meeting, existing);
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteMeeting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce One2One ?'),
        content: const Text('La réunion et toutes ses tâches seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      await widget.service.deleteMeeting(widget.meeting);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.title),
        actions: [
          IconButton(onPressed: _editMeeting, icon: const Icon(Icons.edit_outlined), tooltip: 'Modifier'),
          IconButton(onPressed: _deleteMeeting, icon: const Icon(Icons.delete_outline), tooltip: 'Supprimer'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editTask(),
        icon: const Icon(Icons.add_task),
        label: const Text('Ajouter une tâche'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meeting.people.isEmpty ? 'Participants non renseignés' : meeting.people,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE dd MMM yyyy', 'fr_FR').format(meeting.date)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: LinearProgressIndicator(value: meeting.progress, minHeight: 10)),
                      const SizedBox(width: 12),
                      Text('${(meeting.progress * 100).round()} %'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.slideshow_outlined, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Présentation', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(meeting.presentationName ?? 'Aucune présentation ajoutée'),
                      ],
                    ),
                  ),
                  if (meeting.presentationPath != null)
                    IconButton(
                      tooltip: 'Ouvrir',
                      onPressed: () => OpenFilex.open(meeting.presentationPath!),
                      icon: const Icon(Icons.open_in_new),
                    ),
                  if (meeting.presentationPath != null)
                    IconButton(
                      tooltip: 'Retirer',
                      onPressed: () {
                        widget.service.removePresentation(meeting);
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
                  FilledButton.icon(
                    onPressed: _pickPresentation,
                    icon: const Icon(Icons.attach_file),
                    label: Text(meeting.presentationPath == null ? 'Ajouter PPT' : 'Remplacer'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (meeting.tasks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucune tâche pour ce One2One')),
              ),
            )
          else
            for (final task in meeting.tasks)
              Card(
                child: ListTile(
                  leading: Icon(
                    task.status == One2OneTaskStatus.completed
                        ? Icons.check_circle
                        : task.status == One2OneTaskStatus.waiting
                            ? Icons.pause_circle
                            : Icons.play_circle,
                    color: task.status == One2OneTaskStatus.completed
                        ? Colors.green
                        : task.status == One2OneTaskStatus.waiting
                            ? Colors.orange
                            : Colors.blue,
                  ),
                  title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.comments.isNotEmpty) Text(task.comments),
                      const SizedBox(height: 4),
                      Text('Statut : ${task.status.label}${task.dueDate == null ? '' : ' — Échéance : ${DateFormat('dd MMM yyyy', 'fr_FR').format(task.dueDate!)}'}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTask(existing: task);
                      } else if (value == 'delete') {
                        widget.service.removeTask(meeting, task);
                        setState(() {});
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
