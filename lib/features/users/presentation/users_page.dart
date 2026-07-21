import 'package:flutter/material.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Usuarios e acessos')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [_UserFormCard(), _RolePolicyCard()],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Title('Equipe cadastrada'),
                      _UserTile(
                        name: 'Administrador FreteCerto',
                        email: 'admin@forteexpressa.com.br',
                        role: 'Administrador',
                        status: 'Ativo',
                      ),
                      _UserTile(
                        name: 'Comercial Interno',
                        email: 'comercial@forteexpressa.com.br',
                        role: 'Comercial',
                        status: 'Ativo',
                      ),
                      _UserTile(
                        name: 'Auditoria',
                        email: 'consulta@forteexpressa.com.br',
                        role: 'Consulta',
                        status: 'Somente leitura',
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

class _UserFormCard extends StatelessWidget {
  const _UserFormCard();

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
              const _Title('Cadastrar usuario'),
              const TextField(decoration: InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'E-mail')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: 'Comercial',
                decoration: const InputDecoration(labelText: 'Perfil'),
                items: const [
                  DropdownMenuItem(
                    value: 'Administrador',
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(
                    value: 'Comercial',
                    child: Text('Comercial'),
                  ),
                  DropdownMenuItem(value: 'Consulta', child: Text('Consulta')),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: true,
                onChanged: (_) {},
                title: const Text('Usuario ativo'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Enviar convite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePolicyCard extends StatelessWidget {
  const _RolePolicyCard();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 820 ? width : 520,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Title('Politicas de acesso'),
              _PermissionRow(
                'Administrador',
                'Usuarios, parametros e descontos',
              ),
              _PermissionRow(
                'Comercial',
                'Clientes, cotacoes, propostas e PDF',
              ),
              _PermissionRow('Consulta', 'Visualizacao autorizada'),
              Divider(height: 28),
              _PermissionRow(
                'Seguranca',
                'Sessao, logout e recuperacao de senha',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String name;
  final String email;
  final String role;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(name),
      subtitle: Text(email),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Text(role), Text(status)],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
