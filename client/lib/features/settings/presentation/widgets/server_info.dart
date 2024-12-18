import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';

class ServerInfo extends ConsumerWidget {
  const ServerInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(loggedUserProvider).valueOrNull;

    final deviceId = ref.watch(deviceIdProvider).valueOrNull;

    final isServerReachable = ref.watch(isServerReachableProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "User :",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  letterSpacing: 16 * 0.04,
                ),
              ),
              Expanded(
                child: Text(
                  user != null ? user.name : "N/A",
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    letterSpacing: 16 * 0.04,
                    color: Colors.grey[350],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                "Host :",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  letterSpacing: 16 * 0.04,
                ),
              ),
              Expanded(
                child: Text(
                  AppApi().getServerUrl(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    letterSpacing: 16 * 0.04,
                    color: Colors.grey[350],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                "Device ID :",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  letterSpacing: 16 * 0.04,
                ),
              ),
              Expanded(
                child: Text(
                  deviceId ?? "N/A",
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    letterSpacing: 16 * 0.04,
                    color: Colors.grey[350],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                "Status :",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  letterSpacing: 16 * 0.04,
                ),
              ),
              Expanded(
                child: Text(
                  switch (isServerReachable) {
                    true => "Online",
                    false => "Offline",
                  },
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    letterSpacing: 16 * 0.04,
                    color: Colors.grey[350],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
