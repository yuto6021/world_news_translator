import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserService.instance.currentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('プロフィール')),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : user == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_off,
                              size: 72, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('ログインしていません'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await Navigator.pushNamed(context, '/login');
                              if (result == true) setState(() {});
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('ログイン'),
                          )
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                child: Text(user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 4),
                                    Text(user.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('登録日時',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(user.createdAt.toLocal().toString()),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await UserService.instance.logout();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ログアウトしました')));
                              setState(() {});
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('ログアウト'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
