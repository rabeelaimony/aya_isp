import 'dart:convert';

import 'package:flutter/material.dart';

class SavedCredential {
  final String username;
  final String password;

  const SavedCredential({
    required this.username,
    required this.password,
  });

  static SavedCredential? fromStorage(String value) {
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final username = decoded['username'] as String? ?? '';
      if (username.isEmpty) return null;
      final password = decoded['password'] as String? ?? '';
      return SavedCredential(username: username, password: password);
    } catch (_) {
      return null;
    }
  }

  String toStorage() {
    return jsonEncode({'username': username, 'password': password});
  }
}

class SavedCredentialsField extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode focusNode;
  final List<SavedCredential> credentials;
  final String? savedUsername;

  const SavedCredentialsField({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.focusNode,
    required this.credentials,
    required this.savedUsername,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<SavedCredential>(
          textEditingController: usernameController,
          focusNode: focusNode,
          displayStringForOption: (option) => option.username,
          optionsBuilder: (TextEditingValue value) {
            if (credentials.isEmpty) {
              return const Iterable<SavedCredential>.empty();
            }

            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) {
              return credentials;
            }

            return credentials.where(
              (cred) => cred.username.toLowerCase().contains(query),
            );
          },
          onSelected: (option) {
            usernameController.text = option.username;
            if (option.password.isNotEmpty) {
              passwordController.text = option.password;
            }
          },
          optionsViewBuilder: (context, onSelected, options) {
            final suggestionList = options.toList();
            if (suggestionList.isEmpty) {
              return const SizedBox.shrink();
            }

            final itemExtent = 56.0;
            final padding = 12.0;
            final maxHeight =
                MediaQuery.of(context).size.height * 0.4; // cap height
            final computedHeight = (suggestionList.length * itemExtent) +
                padding * 2; // include padding around list
            final sheetHeight = computedHeight
                .clamp(padding * 2, maxHeight)
                .toDouble();

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: sheetHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: suggestionList.length,
                    physics: suggestionList.length * itemExtent > sheetHeight
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.5,
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = suggestionList[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(suggestion.username),
                        onTap: () => onSelected(suggestion),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, _) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
              cursorColor: theme.colorScheme.primary,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                labelStyle: TextStyle(color: theme.colorScheme.primary),
                labelText: 'اسم المستخدم',
                hintText: savedUsername ?? 'example@aya.sy',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'يرجى إدخال اسم المستخدم';
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}
