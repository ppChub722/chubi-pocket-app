import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';

/// `/personal-debts/new` — manual debt entry, both directions.
class PersonalDebtFormPage extends StatefulWidget {
  const PersonalDebtFormPage({super.key});

  @override
  State<PersonalDebtFormPage> createState() => _PersonalDebtFormPageState();
}

class _PersonalDebtFormPageState extends State<PersonalDebtFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'THB');
  final _note = TextEditingController();
  DebtDirection _direction = DebtDirection.iOwe;

  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<PersonalDebtsCubit>().create(
            direction: _direction,
            counterpartyPersonName: _name.text.trim(),
            amount: double.parse(_amount.text),
            currency: _currency.text.trim().toUpperCase(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New debt')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<DebtDirection>(
              segments: const [
                ButtonSegment(value: DebtDirection.iOwe, label: Text('I owe')),
                ButtonSegment(
                    value: DebtDirection.owedToMe, label: Text('Owed to me')),
              ],
              selected: {_direction},
              onSelectionChanged: (v) => setState(() => _direction = v.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: _direction == DebtDirection.iOwe
                    ? 'I owe whom *'
                    : 'Who owes me *',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a positive amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              maxLength: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _currency.dispose();
    _note.dispose();
    super.dispose();
  }
}
