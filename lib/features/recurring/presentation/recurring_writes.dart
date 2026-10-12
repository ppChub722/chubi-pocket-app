import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/presentation/cubit/dashboard_cubit.dart';

/// A recurring write went through: Home's coming-up card and counts are
/// stale (the next Home open reloads them).
void markRecurringChanged(BuildContext context) =>
    context.read<DashboardCubit>().markStale();
