import 'package:flutter/material.dart';

import '../application/cnpj_lookup_service.dart';
import '../application/customer_repository.dart';
import '../domain/customer.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _repository = CustomerRepository();
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = _repository.recentCustomers();
  }

  void _reloadCustomers() {
    setState(() {
      _customersFuture = _repository.recentCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Clientes')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _CustomerFormCard(
                    title: 'Pessoa juridica',
                    document: 'CNPJ',
                    repository: _repository,
                    onSaved: _reloadCustomers,
                  ),
                  _CustomerFormCard(
                    title: 'Pessoa fisica',
                    document: 'CPF',
                    repository: _repository,
                    onSaved: _reloadCustomers,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Clientes recentes'),
                      FutureBuilder<List<Customer>>(
                        future: _customersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              'Crie a tabela customers no Supabase para listar clientes salvos.',
                            );
                          }
                          final customers = snapshot.data ?? const [];
                          if (customers.isEmpty) {
                            return const Text('Nenhum cliente salvo ainda.');
                          }
                          return Column(
                            children: [
                              for (final customer in customers)
                                _CustomerTile(
                                  name: customer.name,
                                  document: customer.document,
                                  city: customer.city,
                                  status: customer.status.isEmpty
                                      ? 'Cadastrado'
                                      : customer.status,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CustomerFormCard extends StatefulWidget {
  const _CustomerFormCard({
    required this.title,
    required this.document,
    required this.repository,
    required this.onSaved,
  });

  final String title;
  final String document;
  final CustomerRepository repository;
  final VoidCallback onSaved;

  @override
  State<_CustomerFormCard> createState() => _CustomerFormCardState();
}

class _CustomerFormCardState extends State<_CustomerFormCard> {
  final _cnpjService = CnpjLookupService();
  final _documentController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  CnpjLookupResult? _lookup;
  bool _loading = false;
  bool _saving = false;

  @override
  void dispose() {
    _documentController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _lookupCnpj() async {
    setState(() => _loading = true);
    try {
      final result = await _cnpjService.lookup(_documentController.text);
      if (!mounted) return;
      setState(() {
        _lookup = result;
        _documentController.text = result.cnpj;
        _nameController.text = result.legalName;
        _cityController.text = result.cityState;
        _addressController.text = result.address;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente localizado: ${result.displayName}.')),
      );
    } on CnpjLookupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCustomer() async {
    final document = CnpjLookupService.onlyDigits(_documentController.text);
    final name = _nameController.text.trim();
    if (document.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe documento e nome do cliente.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final customer = Customer(
        type: widget.document == 'CNPJ' ? 'company' : 'person',
        document: document,
        name: name,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        tradeName: _lookup?.tradeName ?? '',
        status: _lookup?.status ?? '',
        mainActivity: _lookup?.mainActivity ?? '',
      );
      await widget.repository.save(customer);
      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo no Supabase.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao consegui salvar. Confira se a tabela customers foi criada no Supabase.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompany = widget.document == 'CNPJ';
    return SizedBox(
      width: width < 820 ? width : 520,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(widget.title),
              TextField(
                controller: _documentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.document,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  suffixIcon: isCompany
                      ? IconButton(
                          tooltip: 'Consultar CNPJ',
                          onPressed: _loading ? null : _lookupCnpj,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                        )
                      : null,
                ),
                onSubmitted: isCompany ? (_) => _lookupCnpj() : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.document == 'CNPJ'
                      ? 'Razao social'
                      : 'Nome completo',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Telefone / WhatsApp'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              if (isCompany) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Endereco'),
                ),
                if (_lookup != null) ...[
                  const SizedBox(height: 12),
                  _CnpjLookupSummary(result: _lookup!),
                ],
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _saveCustomer,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando...' : 'Salvar cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CnpjLookupSummary extends StatelessWidget {
  const _CnpjLookupSummary({required this.result});

  final CnpjLookupResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8DEDA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLine('Fantasia', result.tradeName),
          _SummaryLine('Situacao', result.status),
          _SummaryLine('Atividade', result.mainActivity),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text('$label: $value'),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.name,
    required this.document,
    required this.city,
    required this.status,
  });

  final String name;
  final String document;
  final String city;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.apartment)),
      title: Text(name),
      subtitle: Text('$document - $city'),
      trailing: Chip(label: Text(status)),
    );
  }
}
