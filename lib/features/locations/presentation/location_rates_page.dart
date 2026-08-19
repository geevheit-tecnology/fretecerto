import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/formatters/brl.dart';
import '../application/location_rate_pdf_service.dart';
import '../domain/location_rate.dart';

class LocationRatesPage extends StatefulWidget {
  const LocationRatesPage({super.key});

  @override
  State<LocationRatesPage> createState() => _LocationRatesPageState();
}

class _LocationRatesPageState extends State<LocationRatesPage> {
  final _customerController = TextEditingController();
  final _originController = TextEditingController();
  final _validityController = TextEditingController();
  final _rows = <LocationRateRow>[];

  @override
  void dispose() {
    _customerController.dispose();
    _originController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  LocationRateTable get _table {
    return LocationRateTable(
      customerName: _customerController.text.trim(),
      origin: _originController.text.trim(),
      validUntil: _parseDate(_validityController.text),
      rows: List.unmodifiable(_rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final table = _table;
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
                  _SetupCard(
                    customerController: _customerController,
                    originController: _originController,
                    validityController: _validityController,
                    table: table,
                    onChanged: () => setState(() {}),
                  ),
                  _SummaryCard(table: table),
                ],
              ),
              const SizedBox(height: 20),
              _RatesTableCard(
                rows: _rows,
                onAdd: _showAddRowDialog,
                onRemove: (index) => setState(() => _rows.removeAt(index)),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddRowDialog() async {
    final row = await showDialog<LocationRateRow>(
      context: context,
      builder: (context) => const _LocationRowDialog(),
    );
    if (row == null) return;
    setState(() => _rows.add(row));
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.now().add(const Duration(days: 7));
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.customerController,
    required this.originController,
    required this.validityController,
    required this.table,
    required this.onChanged,
  });

  final TextEditingController customerController;
  final TextEditingController originController;
  final TextEditingController validityController;
  final LocationRateTable table;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 820 ? width : 520,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
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
                controller: customerController,
                decoration: const InputDecoration(labelText: 'Cliente'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'Origem base'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: validityController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Validade comercial',
                  hintText: 'dd/mm/aaaa',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: table.rows.isEmpty
                    ? null
                    : () async {
                        final bytes = await const LocationRatePdfService()
                            .buildTable(table);
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
    final lowest = table.rows.isEmpty
        ? 0.0
        : table.rows.map((row) => row.price).reduce((a, b) => a < b ? a : b);
    return SizedBox(
      width: width < 820 ? width : 390,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
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
              _SummaryRow(
                'Menor valor',
                table.rows.isEmpty ? 'aguardando cadastro' : brl(lowest),
              ),
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
  const _RatesTableCard({
    required this.rows,
    required this.onAdd,
    required this.onRemove,
  });

  final List<LocationRateRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
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
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar linha'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const _EmptyRatesState()
            else
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
                    DataColumn(label: Text('Acoes')),
                  ],
                  rows: [
                    for (var index = 0; index < rows.length; index++)
                      DataRow(
                        cells: [
                          DataCell(Text(rows[index].destination)),
                          DataCell(Text(rows[index].vehicle)),
                          DataCell(
                            Text(
                              '${rows[index].maxWeightKg.toStringAsFixed(0)} kg',
                            ),
                          ),
                          DataCell(Text(rows[index].deadline)),
                          DataCell(Text(brl(rows[index].price))),
                          DataCell(Text(rows[index].notes)),
                          DataCell(
                            IconButton(
                              tooltip: 'Remover linha',
                              onPressed: () => onRemove(index),
                              icon: const Icon(Icons.delete_outline),
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
    );
  }
}

class _EmptyRatesState extends StatelessWidget {
  const _EmptyRatesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7E4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.playlist_add_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma localidade cadastrada. Adicione a primeira linha para montar a tabela do cliente.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRowDialog extends StatefulWidget {
  const _LocationRowDialog();

  @override
  State<_LocationRowDialog> createState() => _LocationRowDialogState();
}

class _LocationRowDialogState extends State<_LocationRowDialog> {
  final _destination = TextEditingController();
  final _vehicle = TextEditingController();
  final _weight = TextEditingController();
  final _deadline = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _destination.dispose();
    _vehicle.dispose();
    _weight.dispose();
    _deadline.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar localidade'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _destination,
                decoration: const InputDecoration(labelText: 'Destino'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _vehicle,
                decoration: const InputDecoration(labelText: 'Veiculo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso ate',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deadline,
                decoration: const InputDecoration(labelText: 'Prazo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Observacao'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final row = LocationRateRow(
              destination: _destination.text.trim(),
              vehicle: _vehicle.text.trim(),
              maxWeightKg:
                  double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0,
              deadline: _deadline.text.trim(),
              price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
              notes: _notes.text.trim(),
            );
            if (row.destination.isEmpty || row.price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Informe destino e valor da localidade.'),
                ),
              );
              return;
            }
            Navigator.pop(context, row);
          },
          child: const Text('Adicionar'),
        ),
      ],
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
