import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post.dart';
import '../bloc/post_bloc.dart';
import '../bloc/post_event.dart';
import '../bloc/post_state.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          if (state.status == PostStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == PostStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PostStatus.success) {
            return _PostsList(posts: state.posts);
          }

          return Center(
            child: ElevatedButton(
              onPressed: () => context.read<PostBloc>().add(const PostRequested()),
              child: const Text('Load Posts'),
            ),
          );
        },
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final post = posts[index];
        return ListTile(
          title: Text(
            post.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(post.body),
          leading: CircleAvatar(child: Text(post.id.toString())),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: posts.length,
    );
  }
}
