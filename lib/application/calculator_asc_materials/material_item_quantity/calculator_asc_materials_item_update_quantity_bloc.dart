import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shiori/domain/enums/item_type.dart';
import 'package:shiori/domain/services/data_service.dart';
import 'package:shiori/domain/services/telemetry_service.dart';

part 'calculator_asc_materials_item_update_quantity_bloc.freezed.dart';
part 'calculator_asc_materials_item_update_quantity_event.dart';
part 'calculator_asc_materials_item_update_quantity_state.dart';

class CalculatorAscMaterialsItemUpdateQuantityBloc
    extends Bloc<CalculatorAscMaterialsItemUpdateQuantityEvent, CalculatorAscMaterialsItemUpdateQuantityState> {
  final DataService _dataService;
  final TelemetryService _telemetryService;

  CalculatorAscMaterialsItemUpdateQuantityBloc(this._dataService, this._telemetryService)
      : super(const CalculatorAscMaterialsItemUpdateQuantityState.loading()) {
    on<CalculatorAscMaterialsItemUpdateQuantityEvent>((event, emit) => _mapEventToState(event, emit));
  }

  Future<void> _mapEventToState(
    CalculatorAscMaterialsItemUpdateQuantityEvent event,
    Emitter<CalculatorAscMaterialsItemUpdateQuantityState> emit,
  ) async {
    final s = await event.map(
      load: (e) async {
        final int quantity = _dataService.inventory.getItemQuantityFromInventory(e.key, ItemType.material);
        return CalculatorAscMaterialsItemUpdateQuantityState.loaded(key: e.key, quantity: quantity);
      },
      update: (e) async {
        await _updateMaterialQuantity(e.key, e.quantity);
        return CalculatorAscMaterialsItemUpdateQuantityState.saved(key: e.key, quantity: e.quantity);
      },
    );

    emit(s);
  }

  Future<void> _updateMaterialQuantity(String key, int quantity) async {
    await _telemetryService.trackItemUpdatedInInventory(key, quantity);
    await _dataService.inventory.addMaterialToInventory(key, quantity, redistribute: _dataService.calculator.redistributeInventoryMaterial);
  }
}
