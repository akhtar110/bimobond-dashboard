import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';
import '../../domain/entities/user_detail_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/usecases/get_user_posts.dart';

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
  final GetUserPosts getUserPosts;

  UserDetailBloc({
    required this.getUserById,
    required this.getUserPosts,
  }) : super(UserDetailInitial()) {
    on<LoadUserDetailEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadUserDetailEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(UserDetailLoading());

    try {
      final fullUser = await getUserById(event.user.id);
      var user = fullUser.user;

      if (user.postCount == 0) {
        try {
          final postsPage =
              await getUserPosts(user.id, page: 1, limit: 1);
          final total = postsPage.meta['total'];
          if (total is int && total > 0) {
            user = UserModel(
              id: user.id,
              firebaseUid: user.firebaseUid,
              username: user.username,
              fullName: user.fullName,
              email: user.email,
              phoneNumber: user.phoneNumber,
              bio: user.bio,
              avatarUrl: user.avatarUrl,
              gender: user.gender,
              dateOfBirth: user.dateOfBirth,
              isVerified: user.isVerified,
              instagramUrl: user.instagramUrl,
              youtubeUrl: user.youtubeUrl,
              isPrivate: user.isPrivate,
              allowComments: user.allowComments,
              allowDirectMsgs: user.allowDirectMsgs,
              language: user.language,
              theme: user.theme,
              country: user.country,
              region: user.region,
              city: user.city,
              followerCount: user.followerCount,
              followingCount: user.followingCount,
              postCount: total,
              totalLikes: user.totalLikes,
              isBanned: user.isBanned,
              banReason: user.banReason,
              bannedUntil: user.bannedUntil,
              fcmToken: user.fcmToken,
              createdAt: user.createdAt,
              updatedAt: user.updatedAt,
              roles: user.roles,
            );
          }
        } catch (_) {
          // Keep profile post count from user detail response.
        }
      }

      emit(
        UserDetailLoaded(
          userDetail: UserDetailEntity(
            user: user,
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
