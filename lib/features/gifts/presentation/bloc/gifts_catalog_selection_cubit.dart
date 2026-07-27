import 'package:flutter_bloc/flutter_bloc.dart';

/// Page-local catalog tab selection for the gifts screen.
///
/// Kept separate from [GiftsBloc] / [GiftGroupsBloc] so selecting a group only
/// rebuilds widgets that [BlocSelector] this cubit — not the whole page.
class GiftsCatalogSelectionCubit extends Cubit<String?> {
  GiftsCatalogSelectionCubit() : super(null);

  void selectGroup(String? groupId) {
    if (state == groupId) return;
    emit(groupId);
  }

  void clear() {
    if (state == null) return;
    emit(null);
  }
}
