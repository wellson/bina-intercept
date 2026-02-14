import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../calls/presentation/cubit/call_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiUrlController = TextEditingController();
  final _syncIntervalController = TextEditingController();
  final _binaIdController = TextEditingController();
  bool _isSyncEnabled = true;

  @override
  void dispose() {
    _apiUrlController.dispose();
    _syncIntervalController.dispose();
    _binaIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SettingsCubit>()..loadSettings(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
        ),
        body: BlocConsumer<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações salvas com sucesso!')),
              );
            } else if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${state.message}')),
              );
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SettingsLoaded) {
              _apiUrlController.text = state.apiUrl;
              _syncIntervalController.text = state.syncInterval.toString();
              _binaIdController.text = state.binaId;
              _isSyncEnabled = state.isSyncEnabled;
              return _buildForm(context);
            }
            return _buildForm(context); // Fallback or Initial
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'https://api.exemplo.com',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a URL da API';
                }
                if (!Uri.parse(value).isAbsolute) {
                  return 'Por favor, insira uma URL válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _syncIntervalController,
              decoration: const InputDecoration(
                labelText: 'Tempo de Sincronização (segundos)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o intervalo';
                }
                if (int.tryParse(value) == null) {
                  return 'Por favor, insira um número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _binaIdController,
              decoration: const InputDecoration(
                labelText: 'ID da Bina',
                hintText: 'Ex: DEVICE_001',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o ID da Bina';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Habilitar Sincronização'),
              subtitle: const Text('Enviar dados para a API periodicamente'),
              value: _isSyncEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isSyncEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: 
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<SettingsCubit>().saveSettings(
                      _apiUrlController.text,
                      int.parse(_syncIntervalController.text),
                      _binaIdController.text,
                      _isSyncEnabled,
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
              )
            ),
            const SizedBox(height: 48),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Zona de Perigo',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Limpar Histórico de Chamadas',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Apaga permanentemente todas as chamadas'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Confirmar Exclusão'),
                    content: const Text(
                      'Tem certeza que deseja apagar todo o histórico de chamadas? Essa ação não pode ser desfeita.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Close dialog first
                          Navigator.pop(dialogContext);
                          
                          // Execute clear history
                          sl<CallCubit>().clearHistory();
                          
                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Histórico limpo com sucesso!')),
                          );
                        },
                        child: const Text('Apagar Tudo', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ));
  }
}
