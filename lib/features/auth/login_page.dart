import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';
import '../shell/home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  bool _loading = false;
  bool _codeStep = false;
  String? _error;

  // Повторная отправка кода.
  int _resendIn = 0;
  Timer? _resendTimer;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _phoneValid => _digits.length == 10;

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 800)); // имитация запроса
    if (!mounted) return;
    setState(() {
      _loading = false;
      _codeStep = true;
    });
    _startResend();
  }

  void _startResend() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _submitCode(String code) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AppStore.I.authed = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, _) => FadeTransition(opacity: a, child: const HomeShell()),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _codeStep
          ? AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: () => setState(() {
                  _codeStep = false;
                  _error = null;
                }),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_codeStep) ...[
                const Spacer(flex: 2),
                SprintLogo(size: 56),
                const SizedBox(height: 30),
              ] else
                const SizedBox(height: 12),

              Text(_codeStep ? 'Код из СМС' : 'Вход для курьера',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                _codeStep
                    ? 'Отправили на +7 ${_formatted(_digits)}'
                    : 'Номер телефона, привязанный к аккаунту',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 28),

              if (_codeStep) _codeSection() else _phoneField(),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],

              const Spacer(flex: 3),

              if (!_codeStep)
                PrimaryButton(
                  label: 'Получить код',
                  icon: Icons.arrow_forward_rounded,
                  loading: _loading,
                  onPressed: _phoneValid ? _sendCode : null,
                ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Демо-версия · код может быть любым',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.faint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : CodeInput(length: 4, onCompleted: _submitCode),
        ),
        const SizedBox(height: 20),
        Center(
          child: _resendIn > 0
              ? Text('Отправить код повторно через $_resendIn с',
                  style: Theme.of(context).textTheme.bodySmall)
              : TextButton(
                  onPressed: _startResend,
                  child: const Text('Отправить код повторно',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
        ),
      ],
    );
  }

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: _phoneValid ? AppColors.primary : AppColors.line,
            width: _phoneValid ? 1.8 : 1.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('+7',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
          const SizedBox(width: 10),
          Container(width: 1, height: 26, color: AppColors.line),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                _PhoneMask(),
              ],
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: 0.5),
              decoration: InputDecoration(
                hintText: '900 000 00 00',
                hintStyle: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w700),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatted(String d) {
    if (d.length < 10) return d;
    return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8)}';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    super.dispose();
  }
}

/// Маска 900 000 00 00.
class _PhoneMask extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue value) {
    final d = value.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (int i = 0; i < d.length && i < 10; i++) {
      if (i == 3 || i == 6 || i == 8) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
