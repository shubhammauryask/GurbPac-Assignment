import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/create_edit_project_screen.dart';
import '../../presentation/screens/create_edit_task_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/notifications_screen.dart';
import '../../presentation/screens/project_detail_screen.dart';
import '../../presentation/screens/project_list_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/task_detail_screen.dart';
import '../../presentation/screens/task_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: AuthStateListenable(ref),
    redirect: (context, state) {
      final status = authState.status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.uninitialized || status == AuthStatus.authenticating) {
        return loc == '/splash' ? null : '/splash';
      }

      final isAuthPage = loc == '/login' || loc == '/register';

      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        return isAuthPage ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        if (isAuthPage || loc == '/splash') {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/projects/new',
        builder: (context, state) => const CreateEditProjectScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/projects/:id/edit',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return CreateEditProjectScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: '/tasks/new',
        builder: (context, state) {
          final projId = state.uri.queryParameters['projectId'];
          return CreateEditTaskScreen(initialProjectId: projId);
        },
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return CreateEditTaskScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}
