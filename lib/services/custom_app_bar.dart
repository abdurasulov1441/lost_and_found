import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogoutButton;
  final VoidCallback? onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showLogoutButton = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 19, 195, 169),
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Poppins'),
      ),
      actions: showLogoutButton
          ? [
              IconButton(
                icon: const Icon(Icons.logout),
                color: Colors.white,
                onPressed: onLogout,
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
