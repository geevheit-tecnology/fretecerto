import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/formatters/brl.dart';
import '../application/location_rate_pdf_service.dart';
import '../domain/location_rate.dart';

final _sampleTable = LocationRateTable(
  customerName: 'Forte Expressa Transportes',
  origin: 'Guarulhos, SP',
  validUntil: DateTime(2026, 8, 20),
  rows: const [
    LocationRateRow(
      destination: 'Campinas, SP',
      vehicle: 'VUC',
      maxWeightKg: 3000,
      deadline: '1 dia',
      price: 1250,
      notes: 'Coleta agendada',
    ),
    LocationRateRow(
      destination: 'Rio de Janeiro, RJ',
      vehicle: 'Truck',
      maxWeightKg: 8000,
      deadline: '2 dias',
      price: 4800,
      notes: 'Sem ajudante',
    ),
    LocationRateRow(
      destination: 'Curitiba, PR',
      vehicle: 'Carreta',
      maxWeightKg: 25000,
      deadline: '2 dias',
      price: 7900,
      notes: 'Pedagio incluso',
    ),
    LocationRateRow(
      destination: 'Belo Horizonte, MG',
      vehicle: 'Truck',
      maxWeightKg: 12000,
      deadline: '2 dias',
      price: 6200,
      notes: 'Carga seca',
    ),
  ],
);

class LocationRatesPage extends StatelessWidget {
  const LocationRatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Tabela de localidades')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SetupCard(table: _sampleTable),
                  _SummaryCard(table: _sampleTable),
                ],
              ),
              const SizedBox(height: 20),
              _RatesTableCard(table: _sampleTable),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.table});

  final LocationRateTable table;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 820 ? width : 520,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dados da tabela',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: TextEditingController(text: table.customerName),
                decoration: const InputDecoration(labelText: 'Cliente'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: table.origin),
                decoration: const InputDecoration(labelText: 'Origem base'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: '20/08/2026'),
                decoration: InputDecoration(labelText: 'Validade comercial'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final bytes = await const LocationRatePdfService().buildTable(
                    table,
                  );
                  await Printing.layoutPdf(
                    name: 'tabela-localidades-fretecerto.pdf',
                    onLayout: (_) async => bytes,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Gerar PDF da tabela'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.table});

  final LocationRateTable table;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final lowest = table.rows
        .map((row) => row.price)
        .reduce((a, b) => a < b ? a : b);
    return SizedBox(
      width: width < 820 ? width : 390,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo comercial',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              _SummaryRow('Localidades', '${table.rows.length} destinos'),
              _SummaryRow('Menor valor', brl(lowest)),
              const _SummaryRow('Modelo', 'Tabela dedicada por cliente'),
              const _SummaryRow('Revisao', 'Pendente validacao operacional'),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatesTableCard extends StatelessWidget {
  const _RatesTableCard({required this.table});

  final LocationRateTable table;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Faixas por destino',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar linha'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Destino')),
                  DataColumn(label: Text('Veiculo')),
                  DataColumn(label: Text('Peso ate')),
                  DataColumn(label: Text('Prazo')),
                  DataColumn(label: Text('Valor')),
                  DataColumn(label: Text('Obs.')),
                ],
                rows: table.rows
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(row.destination)),
                          DataCell(Text(row.vehicle)),
                          DataCell(
                            Text('${row.maxWeightKg.toStringAsFixed(0)} kg'),
                          ),
                          DataCell(Text(row.deadline)),
                          DataCell(Text(brl(row.price))),
                          DataCell(Text(row.notes)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
