import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/project.dart';
import '../providers/core_providers.dart';
import '../providers/project_provider.dart';

class CreateEditProjectScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const CreateEditProjectScreen({
    super.key,
    this.projectId,
  });

  @override
  ConsumerState<CreateEditProjectScreen> createState() =>
      _CreateEditProjectScreenState();
}

class _CreateEditProjectScreenState
    extends ConsumerState<CreateEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  Project? _existingProject;

  bool get _isEditing => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      Future.microtask(() async {
        final proj = await ref
            .read(projectRepositoryProvider)
            .getProjectById(widget.projectId!);
        if (mounted) {
          setState(() {
            _existingProject = proj;
            _nameController.text = proj.name;
            _descriptionController.text = proj.description;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    bool success = false;
    try {
      if (_isEditing && _existingProject != null) {
        final updated = _existingProject!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          updatedAt: DateTime.now(),
        );
        success = await ref.read(projectListProvider.notifier).updateProject(updated);
      } else {
        success = await ref.read(projectListProvider.notifier).createProject(
              _nameController.text.trim(),
              _descriptionController.text.trim(),
            );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Project updated' : 'Project created successfully',
            ),
          ),
        );
        context.go('/projects');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Project' : 'New Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'e.g. Mobile Application Redesign',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide a short overview of the project goal...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
