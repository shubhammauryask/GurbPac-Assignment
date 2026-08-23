import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task.dart';
import '../providers/auth_provider.dart';
import '../providers/core_providers.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;
  final String? initialProjectId;

  const CreateEditTaskScreen({
    super.key,
    this.taskId,
    this.initialProjectId,
  });

  @override
  ConsumerState<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedProjectId;
  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedAssigneeId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  TaskItem? _existingTask;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;

    if (_isEditing) {
      Future.microtask(() async {
        final task = await ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
        if (mounted) {
          setState(() {
            _existingTask = task;
            _titleController.text = task.title;
            _descriptionController.text = task.description;
            _selectedProjectId = task.projectId;
            _selectedStatus = task.status;
            _selectedPriority = task.priority;
            _selectedAssigneeId = task.assigneeId;
            _selectedDueDate = task.dueDate;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project'), backgroundColor: AppColors.error),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.user == null || authState.orgId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing && _existingTask != null) {
        final updated = _existingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          projectId: _selectedProjectId,
          status: _selectedStatus,
          priority: _selectedPriority,
          assigneeId: () => _selectedAssigneeId,
          dueDate: () => _selectedDueDate,
          updatedAt: DateTime.now(),
        );
        await ref.read(taskListProvider.notifier).updateTask(updated);
      } else {
        final newTask = TaskItem(
          id: '',
          projectId: _selectedProjectId!,
          orgId: authState.orgId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          priority: _selectedPriority,
          assigneeId: _selectedAssigneeId,
          createdBy: authState.user!.id,
          dueDate: _selectedDueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(taskListProvider.notifier).createTask(newTask);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Task updated' : 'Task created successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectListProvider);
    final usersAsync = ref.watch(orgMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Dropdown
              const Text('Project *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  hintText: 'Select project',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                items: (projectsState.value ?? [])
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProjectId = val;
                  });
                },
                validator: (val) => val == null ? 'Project is required' : null,
              ),
              const SizedBox(height: 16),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Implement OAuth login flow',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed requirements or acceptance criteria...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Row for Status and Priority
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<TaskStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: TaskStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName, style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<TaskPriority>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: TaskPriority.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.displayName, style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPriority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Assignee Selector Dropdown
              const Text('Assignee', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                value: _selectedAssigneeId,
                decoration: const InputDecoration(
                  hintText: 'Unassigned',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')),
                  ...(usersAsync.value ?? [])
                      .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                ],
                onChanged: (val) {
                  setState(() => _selectedAssigneeId = val);
                },
              ),
              const SizedBox(height: 16),

              // Due Date Selector
              const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkSurfaceVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDueDate == null
                            ? 'Select due date'
                            : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                        style: TextStyle(
                          color: _selectedDueDate == null
                              ? AppColors.darkTextSecondary
                              : AppColors.darkTextPrimary,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
