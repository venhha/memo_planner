import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/text_style.dart';

import '../../features/authentication/presentation/bloc/authentication/authentication_bloc.dart';

void showDialogForEditName(BuildContext context, String prevName) async {
  final controller = TextEditingController(text: prevName);
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Name'),
      content: TextField(
        controller: controller,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            context.read<AuthBloc>().add(UpdateDisplayName(name: controller.text));
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void showMyDialogConfirmSignOut(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(SignOutEvent());
            Navigator.pop(context);
          },
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}

Future<T?> showMyDialogToConfirm<T>(
  BuildContext context, {
  required String title,
  required String content,
  VoidCallback? onConfirm,
}) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No', style: MyTextStyle.blueTextDialog),
          ),
          TextButton(
            onPressed: () async {
              onConfirm?.call();
              Navigator.of(context).pop(true);
            },
            child: Text('Yes', style: MyTextStyle.redTextDialog),
          ),
        ],
      );
    },
  );
}

void showMyDialogToAddMember(
  BuildContext context, {
  required void Function(String? value) onSubmitted, // callback to return value (String email)
  required TextEditingController controller,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Member'),
        content: // text field
            TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email',
          ),
          onSubmitted: (value) {
            onSubmitted(value);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSubmitted(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

void showMyAlertDialogMessage({
  required BuildContext context,
  required String message,
  required Icon icon,
}) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          icon: icon,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      });
}
