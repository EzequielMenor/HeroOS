import 'package:flutter/material.dart';
import '../widgets/zen_glass.dart';
import '../widgets/zen_solid_card.dart';
import '../widgets/glass_input.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de Login / Register.
/// Toggle entre ambos modos con un TextButton.
/// Dumb Widget: solo lee del ViewModel y delega acciones.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final bool success;
    if (_isRegisterMode) {
      success = await vm.signUp(email: email, password: password);
    } else {
      success = await vm.signIn(email: email, password: password);
    }

    if (!mounted) return;

    if (success && _isRegisterMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Cuenta creada! Revisa tu email para verificar tu cuenta.',
          ),
          backgroundColor: AppColors.habits,
          duration: Duration(seconds: 4),
        ),
      );
      setState(() => _isRegisterMode = false);
    } else if (!success && vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ZenGlass(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recuperar contraseña',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 16),
                GlassInput(
                  controller: emailCtrl,
                  hint: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),

                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    InkWell(
                      onTap: () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty || !email.contains('@')) return;
                        Navigator.of(ctx).pop();
                        final vm = context.read<AuthViewModel>();
                        final ok = await vm.resetPassword(email);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Revisa tu bandeja de entrada.'
                                  : vm.errorMessage ??
                                        'Error al enviar el email.',
                            ),
                            backgroundColor: ok
                                ? AppColors.habits
                                : AppColors.danger,
                          ),
                        );
                      },

                      child: Icon(
                        Icons.send,
                        color: AppColors.scaffold,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    ZenGlass(
                      width: 72,
                      height: 72,

                      child: Icon(
                        Icons.shield_outlined,
                        size: 36,
                        color: AppColors.habits,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'HeroOS',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                    ),
                    SizedBox(height: 40),

                    // Email
                    GlassInput(
                      controller: _emailController,
                      hint: 'Email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.textSecondary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),

                    // Password
                    GlassInput(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hint: 'Contraseña',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),

                    // Confirmar contraseña (solo en modo registro)
                    if (_isRegisterMode) ...[
                      SizedBox(height: 16),
                      GlassInput(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        hint: 'Confirmar contraseña',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: InkWell(
                        onTap: () => _submit(),

                        child: vm.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Text(
                                _isRegisterMode
                                    ? 'Registrarse'
                                    : 'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Olvidaste tu contraseña (solo en login)
                    if (!_isRegisterMode)
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // Toggle login/register
                    TextButton(
                      onPressed: () {
                        setState(() => _isRegisterMode = !_isRegisterMode);
                        context.read<AuthViewModel>().clearError();
                      },
                      child: Text(
                        _isRegisterMode
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Regístrate',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),

                    // --- Acceso rápido desarrollador (solo en debug) ---
                    if (AuthRepository.devQuickAccess) ...[
                      SizedBox(height: 24),
                      Divider(color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: InkWell(
                          onTap: () async {
                            final vm = context.read<AuthViewModel>();
                            final ok = await vm.devQuickLogin();
                            if (!mounted) return;
                            if (ok) {
                              // El redirect en main.dart lleva a dashboard
                            }
                          },

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_on, size: 18),
                              SizedBox(width: 8),
                              Text('Acceso rápido (Dev)'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.habits),
      ),
    );
  }
}
