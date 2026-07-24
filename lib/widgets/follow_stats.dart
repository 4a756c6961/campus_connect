import 'package:flutter/material.dart';

import 'package:campus_connect/services/follow_service.dart';

class FollowStats extends StatelessWidget {
  const FollowStats({
    super.key,
    required this.userId,
  });

  final String userId;

  static final FollowService _followService = FollowService();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FollowCount(
          stream: _followService.followersCountStream(userId),
          label: 'Follower',
        ),
        const SizedBox(width: 48),
        _FollowCount(
          stream: _followService.followingCountStream(userId),
          label: 'Folgt',
        ),
      ],
    );
  }
}

class _FollowCount extends StatelessWidget {
  const _FollowCount({
    required this.stream,
    required this.label,
  });

  final Stream<int> stream;
  final String label;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '–',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label),
            ],
          );
        }

        final count = snapshot.data ?? 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}