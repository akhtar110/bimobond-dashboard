import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/money_dashboard_entity.dart';
import '../../domain/usecases/load_money_dashboard_usecase.dart';

abstract class MoneyDashboardEvent extends Equatable {
  const MoneyDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadMoneyDashboardEvent extends MoneyDashboardEvent {
  const LoadMoneyDashboardEvent({this.days = 30});
  final int days;
  @override
  List<Object?> get props => [days];
}

abstract class MoneyDashboardState extends Equatable {
  const MoneyDashboardState();
  @override
  List<Object?> get props => [];
}

class MoneyDashboardInitial extends MoneyDashboardState {
  const MoneyDashboardInitial();
}

class MoneyDashboardLoading extends MoneyDashboardState {
  const MoneyDashboardLoading();
}

class MoneyDashboardLoaded extends MoneyDashboardState {
  const MoneyDashboardLoaded(this.data);
  final MoneyDashboardEntity data;
  @override
  List<Object?> get props => [data];
}

class MoneyDashboardError extends MoneyDashboardState {
  const MoneyDashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class MoneyDashboardBloc extends Bloc<MoneyDashboardEvent, MoneyDashboardState> {
  MoneyDashboardBloc({
    required LoadMoneyDashboardUseCase loadDashboard,
    required List<UserRole> roles,
  })  : _loadDashboard = loadDashboard,
        _roles = roles,
        super(const MoneyDashboardInitial()) {
    on<LoadMoneyDashboardEvent>(_onLoad);
  }

  final LoadMoneyDashboardUseCase _loadDashboard;
  final List<UserRole> _roles;

  Future<void> _onLoad(
    LoadMoneyDashboardEvent event,
    Emitter<MoneyDashboardState> emit,
  ) async {
    emit(const MoneyDashboardLoading());
    try {
      final data = await _loadDashboard(
        days: event.days,
        includeMonetization: canViewMonetizationAnalytics(_roles),
        includeCommissionSettings: canManageSettings(_roles),
      );
      emit(MoneyDashboardLoaded(data));
    } catch (e) {
      emit(MoneyDashboardError(e.toString()));
    }
  }
}
