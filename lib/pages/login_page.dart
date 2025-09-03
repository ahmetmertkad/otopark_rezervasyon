// lib/pages/airport_parking_login.dart
import 'package:flutter/material.dart';

/// Havaalanı Otopark temalı giriş sayfası (yalnızca UI).
/// - Arkaplan: pist çizgileri + yumuşak gradient
/// - Kart: cam (glass) efekti, airport ikonografi
/// - Renk paleti: apron mavisi, gece laciverti, apron ışıkları sarısı
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
    // Tema renkleri (havaalanı / apron paleti)
    const nightBlue = Color(0xFF0F1B2B);
    const apronBlue = Color(0xFF183C72);
    const taxiwayCyan = Color(0xFF3EC6FF);
    const beaconYellow = Color(0xFFFFC857);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Arkaplan gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [nightBlue, apronBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Pist (runway) çizgileri
          Positioned.fill(
            child: CustomPaint(
              painter: _RunwayPainter(
                lineColor: Colors.white.withOpacity(0.08),
                centerlineColor: beaconYellow.withOpacity(0.25),
              ),
            ),
          ),
          // Hafif blur “bokeh” daireler (apron ışıkları hissi)
          Positioned(
            top: -60,
            left: -40,
            child: _GlowCircle(color: taxiwayCyan.withOpacity(0.35), size: 180),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: _GlowCircle(
              color: beaconYellow.withOpacity(0.28),
              size: 220,
            ),
          ),

          // İçerik
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.45),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: taxiwayCyan),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Başlık ve ikonografi
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
                          const SizedBox(height: 10),
                          const Text(
                            "Havaalanı Otopark Rezervasyon",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _u,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: "Kullanıcı adı",
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? "Zorunlu alan"
                                              : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _p,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText: "Şifre",
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed:
                                          () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      tooltip: _obscure ? "Göster" : "Gizle",
                                    ),
                                  ),
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? "Zorunlu alan"
                                              : null,
                                ),
                                const SizedBox(height: 8),

                                if (widget.errorText != null) ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.errorText!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      backgroundColor: taxiwayCyan,
                                      foregroundColor: nightBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed:
                                        widget.busy
                                            ? null
                                            : () {
                                              if (_formKey.currentState!
                                                  .validate()) {
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
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : const Text(
                                              "Giriş Yap",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Küçük alt metin (opsiyonel)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        "Şifremi unuttum",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        "Kayıt ol",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
        ],
      ),
    );
  }
}

/// Cam (glassmorphism) kart
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Apron ışıkları efekti için yumuşak parlayan daire
class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
      ),
    );
  }
}

/// Pist ve centerline boyaması
class _RunwayPainter extends CustomPainter {
  final Color lineColor;
  final Color centerlineColor;
  _RunwayPainter({required this.lineColor, required this.centerlineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2;

    // Yana doğru birkaç paralel çizgi (apron şeritleri)
    for (double x = 40; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine);
    }

    // Centerline (pist ortası kesik çizgisi)
    final paintDash =
        Paint()
          ..color = centerlineColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    const dash = 24.0;
    const gap = 16.0;
    final cx = size.width * 0.5;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + dash), paintDash);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
