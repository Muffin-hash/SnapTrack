import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/post_card.dart';
import 'add_post_screen.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not signed in.'))
          : StreamBuilder<List<PostModel>>(
              stream: _databaseService.watchMyPosts(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong loading your posts.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data!;
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet. Tap + to create one.'));
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return PostCard(
                      post: post,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPostScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
