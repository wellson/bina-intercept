import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/call_log.dart';
import '../cubit/call_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.phone,
      Permission.microphone,
      Permission.contacts,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bina Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<CallCubit, CallState>(
        builder: (context, state) {
          if (state is CallLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CallLoaded) {
            if (state.calls.isEmpty) {
              return const Center(child: Text('Nenhuma chamada interceptada ainda.'));
            }
            return ListView.builder(
              itemCount: state.calls.length,
              itemBuilder: (context, index) {
                final call = state.calls[index];
                return ListTile(
                  leading: Icon(
                    call.source == CallSource.whatsapp ? Icons.message : Icons.phone,
                    color: call.source == CallSource.whatsapp ? Colors.green : Colors.blue,
                  ),
                  title: Text(call.phoneNumber),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(call.timestamp)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          call.isSynced ? Icons.check_circle : (call.lastError != null ? Icons.error_outline : Icons.cloud_upload),
                          color: call.isSynced ? Colors.green : (call.lastError != null ? Colors.red : Colors.grey),
                        ),
                        onPressed: () {
                          if (call.id == null) return;
                          
                          if (!call.isSynced && call.lastError != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Falha no Envio'),
                                content: Text(call.lastError!),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fechar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // Retry immediately by triggering sync manually? 
                                      // Or just ensuring it's unsynced (it is).
                                      // Note: SyncService picks up isSynced=false.
                                      // We can trigger a sync via background service or just wait.
                                    },
                                    child: const Text('Entendi'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            context.read<CallCubit>().toggleSyncStatus(call.id!, call.isSynced);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(call.isSynced 
                                  ? 'Marcado para reenvio' 
                                  : 'Marcado como enviado manualmente'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        tooltip: call.isSynced 
                            ? 'Enviado (Toque para reenviar)' 
                            : (call.lastError != null ? 'Erro: ${call.lastError}' : 'Aguardando envio'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (call.id != null) {
                            context.read<CallCubit>().deleteCall(call.id!);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is CallError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulate incoming call for testing
          final call = CallLog(
            phoneNumber: '+5511999999999',
            source: CallSource.cellular,
            timestamp: DateTime.now(),
          );
            context.read<CallCubit>().addCall(call);
        },
        child: const Icon(Icons.add_call),
      ),
    );
  }
}
