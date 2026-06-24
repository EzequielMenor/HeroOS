import 'package:flutter/material.dart';
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Recuperar contraseña',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.scaffold,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.habits),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.habits),
            onPressed: () async {
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
                        : vm.errorMessage ?? 'Error al enviar el email.',
                  ),
                  backgroundColor: ok ? AppColors.habits : AppColors.danger,
                ),
              );
            },
            child: Text('Enviar enlace'),
          ),
        ],
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
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.habits, width: 2),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 36,
                        color: AppColors.habits,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'HeroOS',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                    ),
                    SizedBox(height: 40),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration:
                          _inputDecoration('Email', Icons.email_outlined),
                      validator: (v) =>
                          v != null && v.contains('@') ? null : 'Email inválido',
                    ),
                    SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        'Contraseña',
                        Icons.lock_outline,
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
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Mínimo 6 caracteres',
                    ),

                    // Confirmar contraseña (solo en modo registro)
                    if (_isRegisterMode) ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          'Confirmar contraseña',
                          Icons.lock_outline,
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
                        validator: (v) =>
                            v == _passwordController.text
                                ? null
                                : 'Las contraseñas no coinciden',
                      ),
                    ],
                    SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: vm.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.habits,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                        style:
                            TextStyle(color: AppColors.textSecondary),
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
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final vm = context.read<AuthViewModel>();
                            final ok = await vm.devQuickLogin();
                            if (!mounted) return;
                            if (ok) {
                              // El redirect en main.dart lleva a dashboard
                            }
                          },
                          icon: Icon(Icons.flash_on, size: 18),
                          label: Text('Acceso rápido (Dev)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.habits,
                            side: BorderSide(color: AppColors.habits),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
