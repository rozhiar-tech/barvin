import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/search_screen.dart';
import 'package:flutter/material.dart';

// 1) Your tappable SearchBar
class SearchBar1 extends StatelessWidget {
  final String hint;
  const SearchBar1({Key? key, this.hint = 'Search…'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return InkWell(
      onTap: () {
        // 2) When tapped, navigate to SearchScreen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              s.hint,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
