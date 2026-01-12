import 'package:flutter/material.dart';
import 'package:aya_isp/services/notification_center.dart';

import '../../../models/userinfo_model.dart';

class AppBarUser extends StatelessWidget {
  final UserData? data;
  final VoidCallback? onTap;
  final VoidCallback? onNotifications;
  final VoidCallback? onSettings;

  const AppBarUser({
    super.key,
    this.data,
    this.onTap,
    this.onNotifications,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 50,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              iconSize: 30,
              icon: ValueListenableBuilder(
                valueListenable: NotificationCenter.instance.version,
                builder: (context, _, __) {
                  final unread = NotificationCenter.instance.unreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications,
                        color: theme.colorScheme.onPrimary,
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              onPressed: onNotifications,
            ),

            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimary,
                      size: 25,
                    ),
                    const SizedBox(width: 6),

                    SizedBox(
                      width: 140,
                      child: Text(
                        data?.fullName ??
                            // data?.user?.personal?.username ??
                            "مستخدم",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onPrimary,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),

            IconButton(
              iconSize: 30,
              icon: Icon(Icons.settings, color: theme.colorScheme.onPrimary),
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}
