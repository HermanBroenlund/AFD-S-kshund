import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/afd_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final code = TextEditingController();
  bool codeSent = false;
  bool busy = false;
  String? message;

  Future<void> sendCode() async {
    setState(() { busy = true; message = null; });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email.text.trim(),
        shouldCreateUser: false,
      );
      setState(() { codeSent = true; message = 'Kode sendt på e-post.'; });
    } catch (e) { setState(() => message = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> verify() async {
    setState(() { busy = true; message = null; });
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: email.text.trim(),
        token: code.text.trim(),
        type: OtpType.email,
      );
    } catch (e) { setState(() => message = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(children: [
              const AfdLogo(height: 190),
              const SizedBox(height: 18),
              Text('AFD Søkshund', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-post')),
              const SizedBox(height: 12),
              if (codeSent) ...[
                TextField(controller: code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kode fra e-post')),
                const SizedBox(height: 12),
              ],
              ElevatedButton(onPressed: busy ? null : (codeSent ? verify : sendCode), child: Text(codeSent ? 'LOGG INN' : 'SEND KODE')),
              if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!, textAlign: TextAlign.center)),
            ]),
          ),
        ),
      ),
    ),
  );
}
