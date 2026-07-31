import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/linkify.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/translator.dart';

class ElfPage extends StatelessWidget {
  const ElfPage({super.key});

  @override
  Widget build(BuildContext context) {
    // vertical center
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Container(
              decoration: const BoxDecoration(
                // moon white
                color: Color(0xFFF4F6F0),
                shape: .circle,
              ),
              child: Image.asset('assets/feature_request_please.gif', key: const Key('elf_page')),
            ),
            const SizedBox(height: 14.0),
            Linkify.fromString(S.settingElfContent, textAlign: .center),
            const SizedBox(height: kFABSpacing),
          ],
        ),
      ),
    );
  }
}
