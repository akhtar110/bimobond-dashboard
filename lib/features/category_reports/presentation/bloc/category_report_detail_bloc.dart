import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category_report_entities.dart';
import '../../domain/usecases/get_category_report_detail_usecase.dart';

part 'category_report_detail_event.dart';
part 'category_report_detail_state.dart';

class CategoryReportDetailBloc
    extends Bloc<CategoryReportDetailEvent, CategoryReportDetailState> {
  CategoryReportDetailBloc({required GetCategoryReportDetail getDetail})
      : _getDetail = getDetail,
        super(CategoryReportDetailInitial()) {
    on<LoadCategoryReportDetailEvent>(_onLoad);
    on<ChangeCategoryReportDetailDaysEvent>(_onChangeDays);
    on<RefreshCategoryReportDetailEvent>(_onRefresh);
  }

  final GetCategoryReportDetail _getDetail;

  String? _categoryId;
  int _days = 30;

  Future<void> _onLoad(
    LoadCategoryReportDetailEvent event,
    Emitter<CategoryReportDetailState> emit,
  ) async {
    _categoryId = event.categoryId;
    _days = event.days;
    emit(CategoryReportDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onChangeDays(
    ChangeCategoryReportDetailDaysEvent event,
    Emitter<CategoryReportDetailState> emit,
  ) async {
    _days = event.days;
    final current = state;
    if (current is CategoryReportDetailLoaded) {
      emit(current.copyWith(days: _days, isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshCategoryReportDetailEvent event,
    Emitter<CategoryReportDetailState> emit,
  ) async {
    final current = state;
    if (current is CategoryReportDetailLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<CategoryReportDetailState> emit) async {
    final categoryId = _categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      emit(CategoryReportDetailError('Missing category id'));
      return;
    }

    try {
      final detail = await _getDetail(
        categoryId: categoryId,
        query: CategoryReportPeriodQuery(days: _days),
      );
      emit(
        CategoryReportDetailLoaded(
          detail: detail,
          days: _days,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(CategoryReportDetailError(e.toString()));
    }
  }
}
