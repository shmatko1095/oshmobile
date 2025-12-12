import 'package:flutter/cupertino.dart';
import 'package:oshmobile/generated/l10n.dart';

class UnassignDeviceDialog extends StatelessWidget {
  final String deviceName;

  const UnassignDeviceDialog({
    super.key,
    required this.deviceName,
  });

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _contentStyle = TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );
  static final TextStyle _deviceNameStyle = TextStyle(
    color: CupertinoColors.activeBlue.withValues(alpha: 0.8),
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Column(
        children: [
          Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.extraLightBackgroundGray.withValues(alpha: 0.8),
            size: 60.0,
          ),
          const SizedBox(height: 10),
          Text(S.of(context).UnlinkDevice, style: _titleStyle),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text.rich(
          TextSpan(
            text: S.of(context).DeviceUnlinkAlertContent1,
            style: _contentStyle,
            children: [
              TextSpan(text: ' '), // small spacing before name
              TextSpan(text: deviceName, style: _deviceNameStyle),
              TextSpan(text: ' ${S.of(context).DeviceUnlinkAlertContent2}'),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            S.of(context).Cancel,
            style: TextStyle(color: CupertinoColors.inactiveGray),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(S.of(context).Yes),
        ),
      ],
    );
  }
}
