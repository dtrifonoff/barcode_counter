import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import 'session_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadSessions();
    });
  }

  Future<void> _deleteAllSessions() async {
    final historyProvider = context.read<HistoryProvider>();

    if (!historyProvider.hasSessions) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на всички заявки'),
        content: const Text(
          'Сигурни ли сте, че искате да изтриете всички заявки? Това действие не може да бъде отменено.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Изтрий всички'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await historyProvider.deleteAllSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Всички заявки са изтрити')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Грешка: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История на заявките'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _deleteAllSessions,
            tooltip: 'Изтрий всички',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<HistoryProvider>(
          builder: (context, historyProvider, child) {
            if (historyProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!historyProvider.hasSessions) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Няма записани заявки',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final sessions = historyProvider.sessions;
            final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Dismissible(
                    key: Key('session_${session.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Изтриване'),
                          content: Text('Изтриване на "${session.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Не'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Да'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      historyProvider.deleteSession(session.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сесията е изтрита')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${session.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        session.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateFormatter.format(session.createdDate)),
                          Text(
                            '${session.itemCount} артикула, Общо: ${session.totalQuantity}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SessionDetailsScreen(session: session),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
