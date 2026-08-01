import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shrimpai_pos/helpers/logger.dart';
import 'package:shrimpai_pos/services/auth.dart';
import 'package:shrimpai_pos/translator.dart';

const _googleBlue = Color(0xff4285f4);
const _googleWhite = Color(0xffffffff);
const _googleDark = Color(0xff757575);

class SignInButton extends StatelessWidget {
  final Widget? signedInWidget;
  final EdgeInsetsGeometry padding;

  // if we are in local test it might be null, but it should be fine.
  final Widget Function(GoogleSignInAccount? user)? signedInWidgetBuilder;

  const SignInButton({super.key, this.padding = const .all(0), this.signedInWidget, this.signedInWidgetBuilder})
    : assert(signedInWidget != null || signedInWidgetBuilder != null);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GoogleSignInAccount?>(
      stream: Auth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final account = snapshot.data;

        // 未登录时显示 Google 登录按钮
        if (account == null) {
          return Padding(
            padding: padding,
            child: const _GoogleSignInButton(key: Key('google_sign_in')),
          );
        }

        // 已登录时渲染业务组件
        return signedInWidget ?? signedInWidgetBuilder!(account);
      },
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton({super.key});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool isLoading = false;

  String? error;

  /// follow https://developers.google.com/identity/branding-guidelines#top_of_page
  @override
  Widget build(BuildContext context) {
    const size = 21.0;
    const padding = size * 1.33 / 2;
    const margin = (size + padding * 2) / 10;
    const height = size + padding * 2;
    const borderRadius = size / 3;
    const borderWidth = 1.0;
    const iconBorderRadius = borderRadius - borderWidth;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == .dark;
    final backgroundColor = isDark ? _googleBlue : _googleWhite;
    final fontColor = isDark ? _googleWhite : _googleDark;

    return Column(
      children: [
        Container(
          margin: const .symmetric(vertical: margin),
          child: Stack(
            children: [
              Material(
                elevation: 1,
                color: backgroundColor,
                borderRadius: .circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: backgroundColor),
                    borderRadius: .circular(borderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: .circular(iconBorderRadius),
                    child: SizedBox(
                      height: height,
                      child: Row(
                        children: [
                          SizedBox(
                            width: height,
                            height: height,
                            child: SvgPicture.asset('assets/google_signin_button.svg', width: size, height: size),
                          ),
                          Expanded(
                            child: Text(
                              S.btnSignInWithGoogle,
                              textAlign: .center,
                              style: TextStyle(height: 1.1, color: fontColor, fontSize: size),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(borderRadius: .circular(borderRadius), onTap: isLoading ? null : signIn),
                ),
              ),
              if (isLoading)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator.adaptive(value: size, strokeWidth: borderWidth * 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const .symmetric(vertical: 4),
            child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }

  Future<void> signIn() async {
    setState(() => isLoading = true);

    bool success = false;
    try {
      success = await Auth.instance.signIn();
    } catch (e, stack) {
      Log.err(e, 'login', stack);
      if (mounted) {
        setState(() {
          error = e is Exception ? e.toString() : e.toString();
        });
      }
    } finally {
      if (mounted && !success) setState(() => isLoading = false);
    }
  }
}

