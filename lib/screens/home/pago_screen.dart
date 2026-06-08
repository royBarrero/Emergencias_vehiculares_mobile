import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class PagoScreen extends StatefulWidget {
  final int idEmergencia;
  final double montoTotal;

  const PagoScreen({
    super.key,
    required this.idEmergencia,
    required this.montoTotal,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  bool _procesando = false;
  bool _pagado = false;
  String _metodoPago = 'tarjeta';
  String? _error;

  double get _comision => widget.montoTotal * 0.10;
  double get _montoNeto => widget.montoTotal - _comision;

  Future<void> _procesarPagoTarjeta() async {
    setState(() { _procesando = true; _error = null; });
    try {
      final intent = await ApiService.crearPaymentIntent(
        widget.idEmergencia,
        widget.montoTotal,
      );
      if (intent == null) throw Exception('Error al crear el pago');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent['client_secret'],
          merchantDisplayName: 'EmergenciasVial',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final confirmacion = await ApiService.confirmarPago(
        widget.idEmergencia,
        intent['payment_intent_id'],
        widget.montoTotal,
        'tarjeta',
      );

      if (confirmacion != null) {
        setState(() { _pagado = true; _procesando = false; });
      }
    } on StripeException catch (e) {
      setState(() {
        _error = e.error.localizedMessage ?? 'Pago cancelado';
        _procesando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error procesando el pago: $e';
        _procesando = false;
      });
    }
  }

  Future<void> _procesarPagoEfectivo() async {
    setState(() { _procesando = true; _error = null; });
    try {
      final confirmacion = await ApiService.confirmarPagoEfectivo(
        widget.idEmergencia,
        widget.montoTotal,
      );
      if (confirmacion != null) {
        setState(() { _pagado = true; _procesando = false; });
      }
    } catch (e) {
      setState(() {
        _error = 'Error registrando pago: $e';
        _procesando = false;
      });
    }
  }

  void _mostrarCalificacion() {
    int estrellas = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('¡Pago completado!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                      color: Color(0xFF2c3e50))),
              const SizedBox(height: 8),
              const Text('¿Cómo calificarías el servicio?',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => estrellas = index + 1),
                    child: Icon(
                      index < estrellas ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFB300),
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                estrellas == 0 ? 'Toca para calificar' :
                estrellas == 1 ? 'Malo' :
                estrellas == 2 ? 'Regular' :
                estrellas == 3 ? 'Bueno' :
                estrellas == 4 ? 'Muy bueno' : '¡Excelente!',
                style: TextStyle(
                  fontSize: 13,
                  color: estrellas == 0 ? Colors.grey : const Color(0xFFFFB300),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: estrellas == 0 ? null : () async {
                  await ApiService.calificarTaller(
                    widget.idEmergencia,
                    estrellas,
                  );
                  Navigator.pop(ctx);
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2c3e50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Enviar calificación'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Pago del servicio'),
      ),
      body: _pagado ? _buildComprobante() : _buildFormulario(),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text('Resumen del servicio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        color: Color(0xFF2c3e50))),
                const SizedBox(height: 16),
                _buildFilaPago('Servicio de emergencia',
                    'Bs ${widget.montoTotal.toStringAsFixed(2)}'),
                const Divider(height: 20),
                _buildFilaPago('Comisión plataforma (10%)',
                    '- Bs ${_comision.toStringAsFixed(2)}', color: Colors.red),
                const Divider(height: 20),
                _buildFilaPago('Total a pagar',
                    'Bs ${widget.montoTotal.toStringAsFixed(2)}', bold: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Método de pago',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Color(0xFF2c3e50))),
          ),
          const SizedBox(height: 12),

          _buildMetodoPago('tarjeta', Icons.credit_card,
              'Tarjeta de crédito/débito', 'Pago seguro con Stripe'),
          const SizedBox(height: 10),
          _buildMetodoPago('efectivo', Icons.payments,
              'Efectivo', 'Pago en mano al técnico'),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _procesando ? null : () {
                if (_metodoPago == 'tarjeta') {
                  _procesarPagoTarjeta();
                } else {
                  _procesarPagoEfectivo();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _procesando
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _metodoPago == 'tarjeta'
                          ? 'Pagar con tarjeta'
                          : 'Confirmar pago en efectivo',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPago(String valor, IconData icono,
      String titulo, String subtitulo) {
    final seleccionado = _metodoPago == valor;
    return GestureDetector(
      onTap: () => setState(() => _metodoPago = valor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFFE53935)
                : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2c3e50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: const Color(0xFF2c3e50)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitulo, style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
            ],
          )),
          if (seleccionado)
            const Icon(Icons.check_circle, color: Color(0xFFE53935)),
        ]),
      ),
    );
  }

  Widget _buildFilaPago(String label, String valor,
      {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(valor, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF2c3e50),
        )),
      ],
    );
  }

  // ← COMPROBANTE ACTUALIZADO — muestra calificación al finalizar
  Widget _buildComprobante() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                color: Color(0xFF4CAF50), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          const Text('¡Pago exitoso!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: Color(0xFF2c3e50))),
          const SizedBox(height: 8),
          const Text('Tu pago fue procesado correctamente',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _buildFilaPago('Emergencia #', '${widget.idEmergencia}'),
              const Divider(height: 20),
              _buildFilaPago('Monto total',
                  'Bs ${widget.montoTotal.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _buildFilaPago('Comisión (10%)',
                  'Bs ${_comision.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _buildFilaPago('Método',
                  _metodoPago == 'tarjeta' ? 'Tarjeta' : 'Efectivo'),
              const Divider(height: 20),
              _buildFilaPago('Estado', '✅ Completado',
                  color: Colors.green, bold: true),
            ]),
          ),
          const SizedBox(height: 32),
          // ← BOTÓN QUE ABRE CALIFICACIÓN PRIMERO
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mostrarCalificacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2c3e50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Calificar y finalizar',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}