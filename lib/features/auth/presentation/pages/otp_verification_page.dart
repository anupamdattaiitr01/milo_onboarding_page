import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/milo_brand_logo.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _pinController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _authCubit = sl<AuthCubit>();

  Timer? _timer;
  int _secondsRemaining = 20;

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 20);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsRemaining = 0);
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _submitOtp([String? code]) {
    final otp = code ?? _pinController.text;
    if (otp.length != 6) return;
    FocusScope.of(context).unfocus();
    _authCubit.verifyOtp(otp);
  }

  Widget _buildSixDigitPinRow({required bool enabled}) {
    final code = _pinController.text;

    return GestureDetector(
      onTap: enabled
          ? () => FocusScope.of(context).requestFocus(_otpFocusNode)
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 6 Burgundy-Outlined PIN Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < code.length;
              final isActive =
                  _otpFocusNode.hasFocus && index == code.length && enabled;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 54,
                margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF17171B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.miloCrimsonLight
                        : (isFilled
                        ? AppColors.miloCrimson
                        : const Color(0xFF6E2239)),
                    width: isActive ? 1.7 : 1.25,
                  ),
                ),
                child: Text(
                  isFilled ? code[index] : '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),

          // Hidden Native Input Capturing 6 Digits & SMS Autofill/Paste
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _pinController,
                focusNode: _otpFocusNode,
                enabled: enabled,
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.length == 6) {
                    _submitOtp(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
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
        final isVerifying = state is AuthVerifyingOtp || state is AuthSendingOtp;
        final isComplete = _pinController.text.length == 6;
        final rawPhone = (_authCubit.lastPhoneNumber ?? '+919876543210')
            .replaceFirst('+91', '')
            .trim();

        return Scaffold(
          backgroundColor: AppColors.canvasDark,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Subtle Back Button to Edit Phone Number
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: isVerifying
                                  ? null
                                  : _authCubit.resetToPhoneInput,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Centered Milo Drive PNG Logo
                          const MiloBrandLogo(height: 92),

                          const SizedBox(height: 44),

                          // Centered Heading & Subtitle
                          const Text(
                            'Enter Login Code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'We have sent the login code to your phone no',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rawPhone,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 6-Digit PIN Boxes
                          _buildSixDigitPinRow(enabled: !isVerifying),

                          const SizedBox(height: 24),

                          // Resend OTP Countdown / Action
                          _secondsRemaining > 0
                              ? Text(
                            'Resend OTP in $_secondsRemaining seconds',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFA8425E),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                              : GestureDetector(
                            onTap: isVerifying
                                ? null
                                : () {
                              _authCubit.sendOtp(
                                rawPhone,
                                isResend: true,
                              );
                              _startResendTimer();
                            },
                            child: const Text(
                              'Resend OTP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.miloCrimsonLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),

                          // Bottom Full-Width Continue Button
                          GestureDetector(
                            onTap: (isComplete && !isVerifying)
                                ? () => _submitOtp()
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: double.infinity,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: isComplete
                                    ? const LinearGradient(
                                  colors: [
                                    Color(0xFFC22D5B),
                                    Color(0xFF8C1C40),
                                  ],
                                )
                                    : null,
                                color: isComplete
                                    ? null
                                    : const Color(0xFF4B554E),
                                boxShadow: isComplete
                                    ? [
                                  BoxShadow(
                                    color: AppColors.miloCrimson
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                                    : null,
                              ),
                              child: isVerifying
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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