import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/brl.dart';
import '../../quote/presentation/quote_controller.dart';
import '../../quote/domain/saved_quote.dart';
import '../../quote/presentation/quote_history_controller.dart';
import '../application/cep_lookup_service.dart';
import '../application/cnpj_lookup_service.dart';
import '../application/customer_repository.dart';
import '../domain/customer.dart';

enum _CustomerKind { company, person }

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key, this.returnTo, this.customerId});

  final String? returnTo;
  final String? customerId;

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _repository = CustomerRepository();
  late Future<List<Customer>> _customersFuture;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _customersFuture = _repository.recentCustomers();
    _selectInitialCustomer();
  }

  void _reloadCustomers() {
    setState(() {
      _customersFuture = _repository.recentCustomers();
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() => _selectedCustomer = customer);
  }

  Future<void> _selectInitialCustomer() async {
    final customerId = widget.customerId;
    if (customerId == null || customerId.isEmpty) return;
    final customers = await _customersFuture;
    if (!mounted) return;
    for (final customer in customers) {
      if (customer.id == customerId) {
        _selectCustomer(customer);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = ref.watch(quoteHistoryProvider);
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Clientes')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _CustomerWorkspace(
                repository: _repository,
                quotes: quotes,
                selectedCustomer: _selectedCustomer,
                onSaved: (customer) {
                  _reloadCustomers();
                  final returnTo = widget.returnTo;
                  if (returnTo != null && returnTo.isNotEmpty) {
                    if (returnTo == '/cotacao') {
                      final form = ref.read(quoteFormProvider);
                      ref
                          .read(quoteFormProvider.notifier)
                          .update(form.copyWith(customerName: customer.name));
                    }
                    context.go(returnTo);
                  }
                },
                onDeleted: () {
                  setState(() => _selectedCustomer = null);
                  _reloadCustomers();
                },
                onNew: () => setState(() => _selectedCustomer = null),
              ),
              const SizedBox(height: 20),
              _RecentCustomersCard(
                customersFuture: _customersFuture,
                onCustomerSelected: _selectCustomer,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CustomerWorkspace extends StatefulWidget {
  const _CustomerWorkspace({
    required this.repository,
    required this.quotes,
    required this.selectedCustomer,
    required this.onSaved,
    required this.onDeleted,
    required this.onNew,
  });

  final CustomerRepository repository;
  final List<SavedQuote> quotes;
  final Customer? selectedCustomer;
  final ValueChanged<Customer> onSaved;
  final VoidCallback onDeleted;
  final VoidCallback onNew;

  @override
  State<_CustomerWorkspace> createState() => _CustomerWorkspaceState();
}

class _CustomerWorkspaceState extends State<_CustomerWorkspace> {
  final _cnpjService = CnpjLookupService();
  final _cepService = CepLookupService();
  final _documentController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  _CustomerKind _kind = _CustomerKind.company;
  CnpjLookupResult? _cnpjLookup;
  bool _loadingDocument = false;
  bool _loadingCep = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void dispose() {
    _documentController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CustomerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final customer = widget.selectedCustomer;
    if (customer != null && customer.id != oldWidget.selectedCustomer?.id) {
      _loadCustomer(customer);
    }
  }

  void _loadCustomer(Customer customer) {
    setState(() {
      _kind = customer.type == 'person'
          ? _CustomerKind.person
          : _CustomerKind.company;
      _cnpjLookup = null;
      _documentController.text = customer.document;
      _nameController.text = customer.name;
      _emailController.text = customer.email;
      _phoneController.text = customer.phone;
      _cityController.text = customer.city;
      _addressController.text = customer.address;
      _cepController.clear();
    });
  }

  Future<void> _lookupCnpj() async {
    setState(() => _loadingDocument = true);
    try {
      final result = await _cnpjService.lookup(_documentController.text);
      if (!mounted) return;
      setState(() {
        _cnpjLookup = result;
        _documentController.text = result.cnpj;
        _nameController.text = result.legalName;
        _cepController.text = result.zipCode;
        _cityController.text = result.cityState;
        _addressController.text = result.address;
      });
      _message('Cliente localizado: ${result.displayName}.');
    } on CnpjLookupException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingDocument = false);
    }
  }

  Future<void> _lookupCep() async {
    setState(() => _loadingCep = true);
    try {
      final result = await _cepService.lookup(_cepController.text);
      if (!mounted) return;
      setState(() {
        _cepController.text = result.cep;
        _cityController.text = result.cityState;
        _addressController.text = result.address;
      });
      _message('Endereco localizado pelo CEP.');
    } on CepLookupException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _loadingCep = false);
    }
  }

  Future<void> _saveCustomer() async {
    final document = CnpjLookupService.onlyDigits(_documentController.text);
    final name = _nameController.text.trim();
    final expectedLength = _kind == _CustomerKind.company ? 14 : 11;
    if (document.length != expectedLength || name.isEmpty) {
      _message(
        _kind == _CustomerKind.company
            ? 'Informe CNPJ valido e razao social.'
            : 'Informe CPF com 11 digitos e nome completo.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final customer = Customer(
        id: widget.selectedCustomer?.id,
        type: _kind == _CustomerKind.company ? 'company' : 'person',
        document: document,
        name: name,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        tradeName: _cnpjLookup?.tradeName ?? '',
        status: _kind == _CustomerKind.company
            ? (_cnpjLookup?.status ?? '')
            : 'Pessoa fisica',
        mainActivity: _cnpjLookup?.mainActivity ?? '',
      );
      final saved = await widget.repository.save(customer);
      if (!mounted) return;
      widget.onSaved(saved);
      _message('Cliente salvo com sucesso.');
    } catch (_) {
      if (mounted) {
        _message('Nao consegui salvar. Confira login e permissao de acesso.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteCustomer() async {
    final customer = widget.selectedCustomer;
    if (customer?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text(
          'Excluir ${customer!.name}? As cotacoes salvas continuam no historico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.delete(customer!.id!);
      if (!mounted) return;
      _clearForm();
      widget.onDeleted();
      _message('Cliente excluido.');
    } catch (_) {
      if (mounted) _message('Nao consegui excluir. Confira sua permissao.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _changeKind(_CustomerKind kind) {
    setState(() {
      _kind = kind;
    });
    _clearForm();
  }

  void _clearForm() {
    setState(() {
      _cnpjLookup = null;
      _documentController.clear();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _cepController.clear();
      _cityController.clear();
      _addressController.clear();
    });
    widget.onNew();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final matchingQuotes = _quotesForCurrentCustomer(widget.quotes);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 940;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: compact
                  ? constraints.maxWidth
                  : constraints.maxWidth * .56,
              child: _CustomerFormCard(
                kind: _kind,
                documentController: _documentController,
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                cepController: _cepController,
                cityController: _cityController,
                addressController: _addressController,
                cnpjLookup: _cnpjLookup,
                loadingDocument: _loadingDocument,
                loadingCep: _loadingCep,
                saving: _saving,
                deleting: _deleting,
                editing: widget.selectedCustomer?.id != null,
                onKindChanged: _changeKind,
                onLookupDocument: _lookupCnpj,
                onLookupCep: _lookupCep,
                onSave: _saveCustomer,
                onNew: _clearForm,
                onDelete: _deleteCustomer,
              ),
            ),
            SizedBox(
              width: compact
                  ? constraints.maxWidth
                  : constraints.maxWidth * .44 - 16,
              child: _CustomerQuoteHistory(
                kind: _kind,
                name: _nameController.text.trim(),
                document: _documentController.text.trim(),
                quotes: matchingQuotes,
              ),
            ),
          ],
        );
      },
    );
  }

  List<SavedQuote> _quotesForCurrentCustomer(List<SavedQuote> quotes) {
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return const [];
    return quotes
        .where((quote) => quote.customerName.toLowerCase().contains(name))
        .toList();
  }
}

class _CustomerFormCard extends StatelessWidget {
  const _CustomerFormCard({
    required this.kind,
    required this.documentController,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.cepController,
    required this.cityController,
    required this.addressController,
    required this.cnpjLookup,
    required this.loadingDocument,
    required this.loadingCep,
    required this.saving,
    required this.deleting,
    required this.editing,
    required this.onKindChanged,
    required this.onLookupDocument,
    required this.onLookupCep,
    required this.onSave,
    required this.onNew,
    required this.onDelete,
  });

  final _CustomerKind kind;
  final TextEditingController documentController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController cepController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final CnpjLookupResult? cnpjLookup;
  final bool loadingDocument;
  final bool loadingCep;
  final bool saving;
  final bool deleting;
  final bool editing;
  final ValueChanged<_CustomerKind> onKindChanged;
  final VoidCallback onLookupDocument;
  final VoidCallback onLookupCep;
  final VoidCallback onSave;
  final VoidCallback onNew;
  final VoidCallback onDelete;

  bool get isCompany => kind == _CustomerKind.company;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing ? 'Editar cliente' : 'Cadastro de cliente',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SegmentedButton<_CustomerKind>(
                  segments: const [
                    ButtonSegment(
                      value: _CustomerKind.company,
                      label: Text('PJ'),
                      icon: Icon(Icons.apartment_outlined),
                    ),
                    ButtonSegment(
                      value: _CustomerKind.person,
                      label: Text('PF'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (value) => onKindChanged(value.single),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: documentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isCompany ? 'CNPJ' : 'CPF',
                helperText: isCompany
                    ? 'Consulta automatica por CNPJ'
                    : 'CPF validado por formato: 000.000.000-00',
                prefixIcon: const Icon(Icons.badge_outlined),
                suffixIcon: isCompany
                    ? IconButton(
                        tooltip: 'Consultar CNPJ',
                        onPressed: loadingDocument ? null : onLookupDocument,
                        icon: loadingDocument
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
              onSubmitted: isCompany ? (_) => onLookupDocument() : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isCompany ? 'Razao social' : 'Nome completo',
                prefixIcon: Icon(
                  isCompany
                      ? Icons.business_center_outlined
                      : Icons.person_outline,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp',
                prefixIcon: Icon(Icons.call_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cepController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'CEP',
                prefixIcon: const Icon(Icons.location_searching_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Consultar CEP',
                  onPressed: loadingCep ? null : onLookupCep,
                  icon: loadingCep
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => onLookupCep(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'Cidade / UF',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Endereco',
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
            if (cnpjLookup != null) ...[
              const SizedBox(height: 12),
              _CnpjLookupSummary(result: cnpjLookup!),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: saving || deleting ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Salvando...' : 'Salvar cliente'),
                ),
                OutlinedButton.icon(
                  onPressed: saving || deleting ? null : onNew,
                  icon: const Icon(Icons.add_outlined),
                  label: const Text('Novo'),
                ),
                if (editing)
                  OutlinedButton.icon(
                    onPressed: saving || deleting ? null : onDelete,
                    icon: deleting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(deleting ? 'Excluindo...' : 'Excluir'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerQuoteHistory extends StatelessWidget {
  const _CustomerQuoteHistory({
    required this.kind,
    required this.name,
    required this.document,
    required this.quotes,
  });

  final _CustomerKind kind;
  final String name;
  final String document;
  final List<SavedQuote> quotes;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  kind == _CustomerKind.company
                      ? Icons.apartment_outlined
                      : Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Historico e validade',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name.isEmpty
                  ? 'Preencha ou selecione um cliente para acompanhar as cotacoes.'
                  : '$name ${document.isEmpty ? '' : '- $document'}',
            ),
            const SizedBox(height: 14),
            if (quotes.isEmpty)
              _ValidityAlert(
                icon: Icons.add_alert_outlined,
                title: 'Sem cotacoes para este cliente',
                detail:
                    'Crie uma cotacao e salve no historico para controlar validade e follow-up.',
                color: const Color(0xFFFFF7E6),
              )
            else
              for (final quote in quotes)
                _QuoteValidityTile(quote: quote, now: now),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/cotacao'),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Nova cotacao para cliente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteValidityTile extends StatelessWidget {
  const _QuoteValidityTile({required this.quote, required this.now});

  final SavedQuote quote;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final expiresAt = quote.createdAt.add(const Duration(days: 7));
    final daysLeft = expiresAt.difference(now).inDays;
    final expired = daysLeft < 0;
    final expiring = !expired && daysLeft <= 2;
    return _ValidityAlert(
      icon: expired
          ? Icons.error_outline
          : expiring
          ? Icons.schedule_outlined
          : Icons.check_circle_outline,
      title: expired
          ? 'Cotacao vencida'
          : expiring
          ? 'Cotacao perto do vencimento'
          : 'Cotacao dentro da validade',
      detail:
          '${quote.origin} -> ${quote.destination} | ${brl(quote.commercialValue)} | validade ate ${_date(expiresAt)}',
      color: expired
          ? const Color(0xFFFFECEB)
          : expiring
          ? const Color(0xFFFFF7E6)
          : const Color(0xFFEAF4F2),
    );
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _ValidityAlert extends StatelessWidget {
  const _ValidityAlert({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCustomersCard extends StatelessWidget {
  const _RecentCustomersCard({
    required this.customersFuture,
    required this.onCustomerSelected,
  });

  final Future<List<Customer>> customersFuture;
  final ValueChanged<Customer> onCustomerSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Clientes recentes'),
            FutureBuilder<List<Customer>>(
              future: customersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final customers = snapshot.data ?? const [];
                if (customers.isEmpty) {
                  return const Text('Nenhum cliente salvo ainda.');
                }
                return Column(
                  children: [
                    for (final customer in customers)
                      _CustomerTile(
                        customer: customer,
                        onTap: () => onCustomerSelected(customer),
                      ),
                  ],
                );
              },
            ),
          ],
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
  const _CustomerTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        child: Icon(
          customer.type == 'person'
              ? Icons.person_outline
              : Icons.apartment_outlined,
        ),
      ),
      title: Text(customer.name),
      subtitle: Text('${customer.document} - ${customer.city}'),
      trailing: Chip(
        label: Text(customer.status.isEmpty ? 'Cadastrado' : customer.status),
      ),
    );
  }
}
