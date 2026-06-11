import 'package:flutter/material.dart';
import '../../data/services/clientes_service.dart';
import '../../global/models/models.dart';

/// Controlador para la gestión del catálogo de clientes.
/// Integra con [ClientesService] para operaciones CRUD.
class ClientesController extends ChangeNotifier {
  final _service = ClientesService();

  List<Cliente> _allClientes = [];
  List<Cliente> _filteredClientes = [];
  
  bool _isLoading = false;
  
  String _query = '';

  List<Cliente> get clientes => _filteredClientes;
  
  bool get isLoading => _isLoading;
  
  String get query => _query;

  /// Carga la lista de clientes desde la API de forma asíncrona.
  /// Muestra el indicador de carga y una vez descargados, aplica el filtro actual.
  Future<void> cargarClientes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allClientes = await _service.getClientes();
      _filtrar();
    } catch (e) {
      debugPrint("Error cargando clientes: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra la lista local de clientes en tiempo real por nombre o email.
  /// Llama internamente a [_filtrar] para calcular la lista resultante.
  void search(String q) {
    _query = q;
    _filtrar();
    notifyListeners();
  }

  /// Método privado que recalcula la lista `_filteredClientes` buscando 
  /// la coincidencia de texto dentro del nombre completo o correo.
  void _filtrar() {
    if (_query.isEmpty) {
      /// Si no hay búsqueda, mostramos todos los clientes.
      _filteredClientes = List.from(_allClientes);
    } else {
      final q = _query.toLowerCase();
      _filteredClientes = _allClientes.where((c) {
        return c.fullName.toLowerCase().contains(q) || 
               c.email.toLowerCase().contains(q);
      }).toList();
    }
  }

  /// Crea un nuevo cliente conectándose al endpoint correspondiente
  /// y recarga la lista automáticamente si la creación es exitosa.
  Future<void> crearCliente(Cliente cliente) async {
    try {
      await _service.crearCliente(cliente);
      await cargarClientes();
    } catch (e) {
      debugPrint("Error al crear cliente: $e");
    }
  }

  /// Actualiza los datos de un cliente existente y refresca la lista.
  Future<void> actualizarCliente(Cliente cliente) async {
    try {
      await _service.actualizarCliente(cliente);
      await cargarClientes();
    } catch (e) {
      debugPrint("Error al actualizar cliente: $e");
    }
  }

  /// Elimina un cliente por su ID y actualiza el estado de la vista.
  Future<void> eliminarCliente(String id) async {
    try {
      await _service.eliminarCliente(id);
      await cargarClientes();
    } catch (e) {
      debugPrint("Error al eliminar cliente: $e");
    }
  }
}
