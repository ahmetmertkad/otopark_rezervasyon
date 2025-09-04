// lib/pages/airport_parking_login.dart
import 'package:flutter/material.dart';

class AirportParkingLoginPage extends StatefulWidget {
  final void Function(String username, String password)? onLogin;
  final bool busy;
  final String? errorText;

  const AirportParkingLoginPage({
    super.key,
    this.onLogin,
    this.busy = false,
    this.errorText,
  });

  @override
  State<AirportParkingLoginPage> createState() =>
      _AirportParkingLoginPageState();
}

class _AirportParkingLoginPageState extends State<AirportParkingLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const taxiwayCyan = Color(0xFF3EC6FF);
    const beaconYellow = Color(0xFFFFC857);
    const errorColor = Color(0xFFFF7043);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: Colors.white.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.flight_takeoff,
                            size: 28,
                            color: taxiwayCyan,
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.local_parking,
                            size: 28,
                            color: beaconYellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _u,
                        decoration: const InputDecoration(
                          hintText: "Kullanıcı adı",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty)
                                    ? "Zorunlu alan"
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _p,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: "Şifre",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed:
                                () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty)
                                    ? "Zorunlu alan"
                                    : null,
                      ),
                      if (widget.errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.errorText!,
                          style: const TextStyle(
                            color: errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              widget.busy
                                  ? null
                                  : () {
                                    if (_formKey.currentState!.validate()) {
                                      widget.onLogin?.call(
                                        _u.text.trim(),
                                        _p.text,
                                      );
                                    }
                                  },
                          child:
                              widget.busy
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(),
                                  )
                                  : const Text("Giriş Yap"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
