import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_detail_entity.dart';
import '../../domain/usecases/get_user_by_id.dart';

// EVENTS
sealed class UserDetailEvent {}

class LoadUserDetailEvent extends UserDetailEvent {
  final UserEntity user;
  LoadUserDetailEvent(this.user);
}

// STATES
sealed class UserDetailState {}

class UserDetailInitial extends UserDetailState {}

class UserDetailLoading extends UserDetailState {}

class UserDetailLoaded extends UserDetailState {
  final UserDetailEntity userDetail;

  UserDetailLoaded({required this.userDetail});
}

class UserDetailError extends UserDetailState {
  final String message;
  UserDetailError(this.message);
}

// BLOC
class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  final GetUserById getUserById;

  UserDetailBloc({required this.getUserById}) : super(UserDetailInitial()) {
    on<LoadUserDetailEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadUserDetailEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(UserDetailLoading());

    try {
      final fullUser = await getUserById(event.user.id);

      emit(
        UserDetailLoaded(
          userDetail: UserDetailEntity(
            user: fullUser.user,
            posts: const [],
            wallet: fullUser.wallet,
            devices: fullUser.devices,
            counts: fullUser.counts,
          ),
        ),
      );
    } catch (e) {
      emit(UserDetailError(e.toString()));
    }
  }
}
