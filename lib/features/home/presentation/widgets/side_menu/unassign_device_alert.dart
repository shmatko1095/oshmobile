import 'package:flutter/cupertino.dart';
import 'package:oshmobile/generated/l10n.dart';

class UnassignDeviceDialog extends StatelessWidget {
  final String deviceName;
  final String deviceSn;

  const UnassignDeviceDialog({
    super.key,
    required this.deviceName,
    required this.deviceSn,
  });

  final TextStyle _titleStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  final TextStyle _contentStyle = const TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );
  final TextStyle _deviceNameStyle = const TextStyle(
    color: CupertinoColors.activeBlue,
  );

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Column(
        children: [
          Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.systemRed,
            size: 60.0,
          ),
          const SizedBox(height: 10),
          Text(S.of(context).UnlinkDevice, style: _titleStyle),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: S.of(context).DeviceUnlinkAlertContent1,
              style: _contentStyle,
              children: [
                TextSpan(
                  text: "$deviceName ($deviceSn)",
                  style: _deviceNameStyle,
                ),
                TextSpan(text: S.of(context).DeviceUnlinkAlertContent2),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            S.of(context).Yes,
            style: TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            S.of(context).Cancel,
            style: TextStyle(color: CupertinoColors.inactiveGray),
          ),
        ),
      ],
    );
  }
}
