import 'package:flutter/material.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class ServerInfo extends StatelessWidget {
  const ServerInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().getLoggedUser();

    final deviceId = context.watch<SettingsViewModel>().deviceId();

    final isServerReachable = context.select<NetworkInfo, bool>(
      (networkInfo) => networkInfo.isServerRecheable(),
    );

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
              Text(
                "${t.general.user} :",
                style: const TextStyle(
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
              Text(
                "${t.general.host} :",
                style: const TextStyle(
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
              Text(
                "${t.general.deviceId} :",
                style: const TextStyle(
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
              Text(
                "${t.general.status} :",
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  letterSpacing: 16 * 0.04,
                ),
              ),
              Expanded(
                child: Text(
                  switch (isServerReachable) {
                    true => t.general.online,
                    false => t.general.offline,
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
