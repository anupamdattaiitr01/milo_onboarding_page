import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/milo_brand_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _authCubit = sl<AuthCubit>();
  bool _isValidPhone = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _phoneFocusNode.hasFocus);
      }
    });
    _phoneController.addListener(() {
      final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final valid = digits.length == 10;
      if (valid != _isValidPhone) {
        setState(() => _isValidPhone = valid);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _submitPhone() {
    if (!_isValidPhone) return;
    FocusScope.of(context).unfocus();
    _authCubit.sendOtp(_phoneController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: _authCubit,
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.miloCrimson,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthSendingOtp;

        return Scaffold(
          backgroundColor: AppColors.canvasDark,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 36),

                          // Centered Milo Drive Emblem & Wordmark
                          const MiloBrandLogo(),

                          const SizedBox(height: 44),

                          // Centered Welcome Headline
                          const Text(
                            'Welcome!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your Phone Number to login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 34),

                          // Sleek +91 Phone Input Container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isFocused || _isValidPhone
                                    ? AppColors.miloCrimsonLight
                                    : AppColors.borderSubtle,
                                width: _isFocused ? 1.5 : 1.1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // +91 Country Code Prefix
                                const Padding(
                                  padding: EdgeInsets.only(left: 18, right: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '+91',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textSecondary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),

                                // Subtle Vertical Divider
                                Container(
                                  width: 1,
                                  height: 26,
                                  color: AppColors.borderSubtle,
                                ),

                                // Auto-Formatted Phone Number Field
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                      _IndianPhoneSpacingFormatter(),
                                    ],
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '98765  43210',
                                      hintStyle: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.2,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                    onSubmitted: (_) => _submitPhone(),
                                  ),
                                ),

                                if (_phoneController.text.isNotEmpty &&
                                    !isLoading)
                                  IconButton(
                                    onPressed: () {
                                      _phoneController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textMuted,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Glowing Crimson Gradient Continue Button
                          GestureDetector(
                            onTap: (_isValidPhone && !isLoading)
                                ? _submitPhone
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: _isValidPhone
                                      ? const [
                                    Color(0xFFC22D5B),
                                    Color(0xFF8C1C40),
                                  ]
                                      : const [
                                    Color(0xFF4A1B2B),
                                    Color(0xFF381420),
                                  ],
                                ),
                                boxShadow: _isValidPhone
                                    ? [
                                  BoxShadow(
                                    color: AppColors.miloCrimson
                                        .withValues(alpha: 0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                                    : null,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                'Continue',
                                style: TextStyle(
                                  color: _isValidPhone
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),

                          // Bottom Scheme Value Proposition Footer
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Verify your mobile number to explore Salary, Rental & Drive-to-Own (DTO) EV plans.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Formats 10 digits visually as `98765  43210` while keeping raw digits clean.
class _IndianPhoneSpacingFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}