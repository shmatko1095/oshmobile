// import 'package:flutter/material.dart';
//
// class RenameThingDialog {
//   static Future<void> show({
//     required BuildContext context,
//     required String? name,
//     required Function(String? name) onChanged,
//   }) {
//     Widget clearButton = Builder(
//       builder: (context) => SizedBox(
//         width: double.infinity,
//         child: TextButton(
//           child: Text(S.of(context).resetName),
//           onPressed: () {
//             onChanged(null);
//             Navigator.of(context).pop();
//           },
//         ),
//       ),
//     );
//
//     Widget renameButton = SizedBoxElevatedButton(
//       text: Text(S.of(context).confirm),
//       onPressed: () {
//         onChanged(name);
//         Navigator.of(context).pop();
//       },
//     );
//
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(S.of(context).renameDevice),
//           content: TextFormField(
//             initialValue: name,
//             decoration: InputDecoration(
//               hintText: S.of(context).deviceName,
//             ),
//             onChanged: (value) => name = value,
//           ),
//           actions: <Widget>[
//             renameButton,
//             clearButton,
//           ],
//         );
//       },
//     );
//   }
// }
