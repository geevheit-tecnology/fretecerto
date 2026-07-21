import 'package:flutter/material.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

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
                children: const [
                  _CustomerFormCard(title: 'Pessoa juridica', document: 'CNPJ'),
                  _CustomerFormCard(title: 'Pessoa fisica', document: 'CPF'),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SectionTitle('Clientes recentes'),
                      _CustomerTile(
                        name: 'Forte Expressa Transportes',
                        document: '12.345.678/0001-90',
                        city: 'Guarulhos, SP',
                        status: 'Ativo',
                      ),
                      _CustomerTile(
                        name: 'Delta Pecas Industriais',
                        document: '44.312.928/0001-10',
                        city: 'Campinas, SP',
                        status: 'Ativo',
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

class _CustomerFormCard extends StatelessWidget {
  const _CustomerFormCard({required this.title, required this.document});

  final String title;
  final String document;

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
              _SectionTitle(title),
              TextField(
                decoration: InputDecoration(
                  labelText: document,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  suffixIcon: document == 'CNPJ'
                      ? IconButton(
                          tooltip: 'Consultar CNPJ',
                          onPressed: () {},
                          icon: const Icon(Icons.search),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: document == 'CNPJ'
                      ? 'Razao social'
                      : 'Nome completo',
                ),
              ),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'E-mail')),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Telefone / WhatsApp'),
              ),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Cidade')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar cliente'),
              ),
            ],
          ),
        ),
      ),
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
