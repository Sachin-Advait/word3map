import 'package:flutter/material.dart';

class SearchCard extends StatelessWidget {
  final String? hintText;
  final TextEditingController searchController;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final IconData? icon;

  const SearchCard({
    super.key,
    this.hintText,
    required this.searchController,
    this.keyboardType,
    this.suffixIcon,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: searchController,
      style: const TextStyle(
        height: 1.1,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      keyboardType: TextInputType.text,
      cursorColor: Colors.indigo,
      onChanged: (query) {
        if (query.isNotEmpty && query.length > 1) {
          searchController.text = query;
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 7),
        hintText: hintText ?? 'Search...',
        hintStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        prefixIcon: SizedBox(
          width: 53,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  // Image.asset(
                  //   AppImages.searchIcon,
                  //   width: 22,
                  //   color: AppColors.secondaryColor,
                  // ),
                  Icon(icon ?? Icons.search),
                ],
              ),
            ),
          ),
        ),
        suffixIcon: SizedBox(
          width: 80,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: suffixIcon,
          ),
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
