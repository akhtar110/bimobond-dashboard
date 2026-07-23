part of 'seller_verification_bloc.dart';

sealed class SellerVerificationEvent extends Equatable {
  const SellerVerificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadSellerVerificationsEvent extends SellerVerificationEvent {
  const LoadSellerVerificationsEvent({this.refresh = false, this.page});

  final bool refresh;
  final int? page;

  @override
  List<Object?> get props => [refresh, page];
}

class GoToSellerVerificationPageEvent extends SellerVerificationEvent {
  const GoToSellerVerificationPageEvent(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class LoadMoreSellerVerificationsEvent extends SellerVerificationEvent {
  const LoadMoreSellerVerificationsEvent();
}

class FilterSellerVerificationsEvent extends SellerVerificationEvent {
  const FilterSellerVerificationsEvent(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class UpdateSellerVerificationSearchEvent extends SellerVerificationEvent {
  const UpdateSellerVerificationSearchEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ApproveSellerVerificationEvent extends SellerVerificationEvent {
  const ApproveSellerVerificationEvent(this.applicationId);

  final String applicationId;

  @override
  List<Object?> get props => [applicationId];
}

class RejectSellerVerificationEvent extends SellerVerificationEvent {
  const RejectSellerVerificationEvent({
    required this.applicationId,
    required this.rejectionReason,
  });

  final String applicationId;
  final String rejectionReason;

  @override
  List<Object?> get props => [applicationId, rejectionReason];
}

class ClearSellerVerificationFeedbackEvent extends SellerVerificationEvent {
  const ClearSellerVerificationFeedbackEvent();
}
