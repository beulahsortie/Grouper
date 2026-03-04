import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bg_scaffold.dart';

class AuthScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> user)? onLogin;
  const AuthScreen({Key? key, this.onLogin}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign in fields
  final _signInIdentifier = TextEditingController();
  final _signInPassword = TextEditingController();
  bool _signInObscure = true;
  bool _signInLoading = false;

  // Sign up fields
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirm = TextEditingController();
  bool _signUpObscure = true;
  bool _signUpConfirmObscure = true;
  bool _signUpLoading = false;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInIdentifier.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirm.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    setState(() => _signInLoading = true);
    try {
      final user = await ApiService.login(
        _signInIdentifier.text.trim(),
        _signInPassword.text,
      );
      if (!mounted) return;
      _showSuccess('Welcome back, ${user?['name'] ?? ''}!');
      widget.onLogin?.call(user!);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _signInLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _signUpLoading = true);
    try {
      final user = await ApiService.signup(
        _signUpName.text.trim(),
        _signUpEmail.text.trim(),
        _signUpPassword.text,
      );
      if (!mounted) return;
      _showSuccess('Account created! Welcome, ${user['name']}!');
      widget.onLogin?.call(user);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _signUpLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BgScaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navy.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 26),

                  
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.location_city_rounded,
                        color: AppColors.navy, size: 28),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Crew',
                    style: TextStyle(
                      color: Color.fromARGB(255, 37, 22, 149),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Find your crew. \nBook your game.',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 108, 107, 107)
                          .withOpacity(0.55),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Card with tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.navy.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        

                        // Tab content
                        SizedBox(
                          height: 350,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _SignInForm(
                                formKey: _signInFormKey,
                                identifier: _signInIdentifier,
                                password: _signInPassword,
                                obscure: _signInObscure,
                                onToggleObscure: () => setState(
                                    () => _signInObscure = !_signInObscure),
                                loading: _signInLoading,
                                onSubmit: _handleSignIn,
                              ),
                              _SignUpForm(
                                formKey: _signUpFormKey,
                                name: _signUpName,
                                email: _signUpEmail,
                                password: _signUpPassword,
                                confirm: _signUpConfirm,
                                obscure: _signUpObscure,
                                confirmObscure: _signUpConfirmObscure,
                                onToggleObscure: () => setState(
                                    () => _signUpObscure = !_signUpObscure),
                                onToggleConfirmObscure: () => setState(() =>
                                    _signUpConfirmObscure =
                                        !_signUpConfirmObscure),
                                loading: _signUpLoading,
                                onSubmit: _handleSignUp,
                                passwordValue: () => _signUpPassword.text,
                              ),
                            ],
                          ),
                        ),
                        Container(
  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: Colors.grey.shade200,
      width: 1.5,
    ),
  ),
  child: TabBar(
    controller: _tabController,
    indicator: BoxDecoration(
      color: const Color.fromARGB(255, 222, 222, 222),
      borderRadius: BorderRadius.circular(26),
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.grey.shade500,
    labelStyle: const TextStyle(
      fontWeight: FontWeight.w600, 
      fontSize: 14,
    ),
    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w500, 
      fontSize: 14,
    ),
    tabs: const [
      Tab(text: 'Sign In'),
      Tab(text: 'Sign Up'),
    ],
  ),
),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign In Form ──────────────────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController identifier;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;

  const _SignInForm({
    required this.formKey,
    required this.identifier,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Text('Welcome back',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 37, 22, 149))),
            const SizedBox(height: 4),
            const Text('Sign in to your account',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            _AuthField(
              controller: identifier,
              hint: 'Email or username',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _AuthField(
              controller: password,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: obscure,
              suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textMuted),
                onPressed: onToggleObscure,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Sign In',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign Up Form ──────────────────────────────────────────────────────────────

class _SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final bool obscure;
  final bool confirmObscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirmObscure;
  final bool loading;
  final VoidCallback onSubmit;
  final String Function() passwordValue;

  const _SignUpForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.password,
    required this.confirm,
    required this.obscure,
    required this.confirmObscure,
    required this.onToggleObscure,
    required this.onToggleConfirmObscure,
    required this.loading,
    required this.onSubmit,
    required this.passwordValue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create account',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 37, 22, 149))),
            // const SizedBox(height: 4),
            // const Text('Join and start booking',
                // style: TextStyle(
                //     fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),

            _AuthField(
              controller: name,
              hint: 'Full name',
              icon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _AuthField(
              controller: email,
              hint: 'Email address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 10),
            _AuthField(
              controller: password,
              hint: 'Password (min 6 chars)',
              icon: Icons.lock_outline_rounded,
              obscure: obscure,
              suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textMuted),
                onPressed: onToggleObscure,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 10),
            _AuthField(
              controller: confirm,
              hint: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              obscure: confirmObscure,
              suffixIcon: IconButton(
                icon: Icon(
                    confirmObscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textMuted),
                onPressed: onToggleConfirmObscure,
              ),
              validator: (v) => v != passwordValue()
                  ? 'Passwords do not match'
                  : null,
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.navy)))
                    : const Text('Create Account',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared field ──────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon:
            Icon(icon, size: 18, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color.fromARGB(255, 231, 230, 230),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}