import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/components/widgets.dart';
import '../../../../core/notification/local_notification_manager.dart';
import '../bloc/authentication/authentication_bloc.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In'), centerTitle: true),
      // drawer: const AppNavigationDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      BlocProvider.of<AuthenticationBloc>(context).add(
                        SignInWithEmail(
                          email: _emailController.text,
                          password: _passwordController.text,
                        ),
                      );
                    }
                  },
                  child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
                    builder: (context, state) {
                      if (state.status == AuthenticationStatus.authenticating) {
                        return const SizedBox(
                          height: 16.0,
                          width: 16.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        );
                      }
                      return const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                const DividerWithText(text: 'Or sign in with'),
                const SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () async {
                    BlocProvider.of<AuthenticationBloc>(context).add(
                      SignInWithGoogle(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[400]!,
                      ),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/icon/google.svg',
                      height: 32.0,
                      width: 32.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  // NOTE: for testing
                  onLongPress: () async {
                    final pending = await di<LocalNotificationManager>().I.pendingNotificationRequests();
                    final activate = await di<LocalNotificationManager>().I.getActiveNotifications();

                    // ignore: use_build_context_synchronously
                    await showDialog(
                      context: context,
                      builder: (_) {
                        return SimpleDialog(
                          children: [
                            Text('pending: ${pending.length}'),
                            for (int i = 0; i < pending.length; i++)
                              Text(
                                '${pending[i].id} - ${pending[i].title} - ${pending[i].body}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text('activate: ${activate.length}'),
                            for (int i = 0; i < activate.length; i++)
                              Text(
                                '${activate[i].id} - ${activate[i].title} - ${activate[i].body}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        );
                      },
                    );
                  },
                  onPressed: () {
                    // context.go('/authentication/sign-up');
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ));
                  },
                  child: const Text(
                    'Don\'t have an account? Register now',
                    style: TextStyle(
                      fontSize: 14.0,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
