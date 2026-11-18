
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';

abstract final class PdfPlanilla {
  static const _azul = PdfColor.fromInt(0xFF1E3A8A);
  static const _azulOscuro = PdfColor.fromInt(0xFF00236F);
  static const _gris = PdfColor.fromInt(0xFF6B7280);
  static const _fondo = PdfColor.fromInt(0xFFEFF4FF);
  static const _borde = PdfColor.fromInt(0xFFD1D5DB);

  static String _limpio(String texto) => texto
      .replaceAll('—', '-')
      .replaceAll('→', '-')
      .replaceAll('·', '-');

  static Future<Uint8List> generar(
    Planilla planilla, {
    Tarifa? tarifa,
    String? empresa,
  }) async {
    final documento = pw.Document(
      title: 'Planilla ${planilla.codigo}',
      author: 'TRANSCOOP',
    );

    pw.MemoryImage? logo;
    try {
      final datos = await rootBundle.load('assets/images/transcoop_logo.png');
      logo = pw.MemoryImage(datos.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (contexto) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _encabezado(planilla, logo, empresa),
            pw.SizedBox(height: 24),
            _seccion('Datos de la operación', [
              ['Fecha', Fechas.corta(planilla.fecha)],
              ['Hora', Fechas.horaTexto(planilla.hora)],
              ['Tipo de planilla', TipoPlanilla.etiqueta(planilla.tipo)],
              ['Estado', Formato.capitalizar(planilla.estado)],
            ]),
            pw.SizedBox(height: 16),
            _seccion('Vehículo y conductor', [
              ['Placa', planilla.placaVehiculo],
              ['Conductor', Formato.valorO(planilla.nombreConductor, 'Sin asignar')],
              [
                'Identificación',
                Formato.valorO(planilla.identificacionConductor, '-'),
              ],
            ]),
            pw.SizedBox(height: 16),
            _seccion('Liquidación', [
              if (tarifa != null) ...[
                ['Aportes gastos varios', Formato.moneda(tarifa.aportesGastosVarios)],
                ['Fondo de reposición', Formato.moneda(tarifa.fondoReposicion)],
                ['Aporte social del socio', Formato.moneda(tarifa.aporteSocialSocio)],
                ['Total tarifa', Formato.moneda(tarifa.total)],
              ] else
                ['Tarifa', planilla.tarifaId == null ? 'Sin tarifa' : 'N. ${planilla.tarifaId}'],
              ['Estado de pago', planilla.pagada ? 'Pagada' : 'Pendiente'],
              if (planilla.pagada) ...[
                ['Valor pagado', Formato.moneda(planilla.valorPagado)],
                ['Fecha de pago', Fechas.corta(planilla.fechaPago)],
              ],
            ]),
            pw.Spacer(),
            _firmas(),
            pw.SizedBox(height: 16),
            pw.Divider(color: _borde),
            pw.Text(
              _limpio(
                'Registrada por ${Formato.valorO(planilla.registradoPor, 'el sistema')} el ${Fechas.fechaHora(planilla.fechaRegistro)}. '
                'Documento generado el ${Fechas.fechaHora(DateTime.now())} desde la aplicación TRANSCOOP.',
              ),
              style: const pw.TextStyle(fontSize: 8, color: _gris),
            ),
          ],
        ),
      ),
    );

    return documento.save();
  }

  static Future<void> compartir(
    Planilla planilla, {
    Tarifa? tarifa,
    String? empresa,
  }) async {
    final bytes = await generar(planilla, tarifa: tarifa, empresa: empresa);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'planilla_${planilla.numero}.pdf',
    );
  }

  static pw.Widget _encabezado(
    Planilla planilla,
    pw.MemoryImage? logo,
    String? empresa,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _fondo,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            pw.Image(logo, height: 46),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _limpio(empresa ?? 'TRANSCOOP'),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _azulOscuro,
                  ),
                ),
                pw.Text(
                  'Cooperativa de Transporte Mixto',
                  style: const pw.TextStyle(fontSize: 10, color: _gris),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PLANILLA DE VIAJE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _azul,
                ),
              ),
              pw.Text(
                planilla.codigo,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _azulOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _seccion(String titulo, List<List<String>> filas) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          titulo.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _azul,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _borde, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
          },
          children: [
            for (final fila in filas)
              pw.TableRow(
                children: [
                  pw.Container(
                    color: _fondo,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: pw.Text(
                      fila[0],
                      style: const pw.TextStyle(fontSize: 10, color: _gris),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: pw.Text(
                      _limpio(fila[1]),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _firmas() {
    pw.Widget firma(String rol) => pw.Expanded(
      child: pw.Column(
        children: [
          pw.Container(height: 1, color: _borde),
          pw.SizedBox(height: 4),
          pw.Text(rol, style: const pw.TextStyle(fontSize: 9, color: _gris)),
        ],
      ),
    );

    return pw.Row(
      children: [
        firma('Firma del despachador'),
        pw.SizedBox(width: 40),
        firma('Firma del conductor'),
      ],
    );
  }
}
