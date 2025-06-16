import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Para formatear fechas y horas

import 'package:face2face_app/session.dart';
import 'package:face2face_app/config/app_config.dart';

// Modelo simple para el gimnasio en el dropdown
class GymMenuItem {
  final String id;
  final String name;

  GymMenuItem({required this.id, required this.name});

  factory GymMenuItem.fromJson(Map<String, dynamic> json) {
    return GymMenuItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Gimnasio sin nombre',
    );
  }
}

class CreateCombatScreen extends StatefulWidget {
  final String creatorId;
  final String creatorName; // Para mostrar en la UI
  final String opponentId;
  final String opponentName; // Para mostrar en la UI

  const CreateCombatScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.opponentId,
    required this.opponentName,
  });

  @override
  State<CreateCombatScreen> createState() => _CreateCombatScreenState();
}

class _CreateCombatScreenState extends State<CreateCombatScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Añade opciones de nivel con un valor inicial nulo
  final List<String> _levels = ['Amateur', 'Sparring', 'Profesional'];
  String? _selectedLevel;

  List<GymMenuItem> _gyms = [];
  String? _selectedGymId;
  bool _isLoadingGyms = true;
  bool _isSubmitting = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchGyms();
    _selectedLevel = null; // Por defecto, nada seleccionado
  }

  Future<void> _fetchGyms() async {
    setState(() {
      _isLoadingGyms = true;
    });
    try {
      final token = Session.token;
      if (token == null) {
        throw Exception('Usuario no autenticado para cargar gimnasios.');
      }

      final url = Uri.parse('$API_BASE_URL/gym');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        List<dynamic> data = [];

        if (responseBody is List) {
          data = responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          data = responseBody['gyms'] ??
              responseBody['results'] ??
              responseBody['data'] ??
              [];
        }

        setState(() {
          _gyms = data.map((g) => GymMenuItem.fromJson(g)).toList();
          _isLoadingGyms = false;
        });
      } else {
        throw Exception(
            'Error al obtener gimnasios: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar gimnasios: ${e.toString()}')),
        );
        setState(() {
          _isLoadingGyms = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
       builder: (context, child) { // Opcional: Para tematizar el DatePicker
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.red, // Color primario
              onPrimary: Colors.white, // Color del texto sobre el primario
              surface: Colors.grey[800]!, // Fondo del DatePicker
              onSurface: Colors.white, // Texto del DatePicker
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) { // Opcional: Para tematizar el TimePicker
        return Theme(
          data: ThemeData.dark().copyWith(
             colorScheme: ColorScheme.dark(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Colors.grey[800]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey[900],
              hourMinuteTextColor: Colors.white,
              hourMinuteColor: Colors.grey[800],
              dayPeriodTextColor: Colors.white,
              dayPeriodColor: Colors.grey[700],
              dialHandColor: Colors.red,
              dialBackgroundColor: Colors.grey[800],
              dialTextColor: Colors.white,
              entryModeIconColor: Colors.red,
            )
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitCreateCombat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedGymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un gimnasio.')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona fecha y hora.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = Session.token;
      if (token == null) {
        throw Exception('Usuario no autenticado.');
      }

      final DateTime combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final String isoDateTimeInUtc = combinedDateTime.toUtc().toIso8601String();

      final combatData = {
        "creator": widget.creatorId,
        "opponent": widget.opponentId,
        "date": isoDateTimeInUtc,
        "time": _timeController.text,
        "level": _selectedLevel ?? '',
        "gym": _selectedGymId,
        "boxers": [widget.creatorId, widget.opponentId],
      };

      print('Enviando datos de combate: ${json.encode(combatData)}');

      final url = Uri.parse('$API_BASE_URL/combat');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(combatData),
      );

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('¡Propuesta de combate enviada exitosamente!')),
          );
          Navigator.pop(context, true);
        } else {
          final responseBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error al crear combate: ${responseBody['message'] ?? response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputBorder finalInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: Colors.grey.shade700),
    );

    InputDecoration finalInputDecoration(String label, {Widget? suffixIcon}) =>
        InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey.shade900.withOpacity(0.85),
          border: finalInputBorder,
          enabledBorder: finalInputBorder,
          focusedBorder: finalInputBorder.copyWith(
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          suffixIcon: suffixIcon,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proponer Combate'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCombatantInfoCard(),
                  const SizedBox(height: 28),
                  DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Seleccione nivel...', style: TextStyle(color: Colors.white54)),
                      ),
                      ..._levels.map((level) => DropdownMenuItem(
                            value: level,
                            child: Row(
                              children: [
                                Icon(
                                  level == 'Amateur'
                                      ? Icons.school
                                      : level == 'Sparring'
                                          ? Icons.sports_mma
                                          : Icons.workspace_premium,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(level, style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLevel = value;
                      });
                    },
                    decoration: finalInputDecoration('Nivel del Combate'),
                    dropdownColor: Colors.grey.shade900,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.redAccent,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecciona el nivel del combate.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  // --- GIMNASIO COMO DROPDOWN SELECTOR ---
                  DropdownButtonFormField<String>(
                    value: _selectedGymId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Seleccione gimnasio...', style: TextStyle(color: Colors.white54)),
                      ),
                      ..._gyms.map((gym) => DropdownMenuItem(
                            value: gym.id,
                            child: Row(
                              children: [
                                const Icon(Icons.fitness_center, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(gym.name, style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGymId = value;
                      });
                    },
                    decoration: finalInputDecoration('Gimnasio Sede del Combate',
                        suffixIcon: const Icon(Icons.sports_kabaddi, color: Colors.white70)),
                    dropdownColor: Colors.grey.shade900,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    iconEnabledColor: Colors.redAccent,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecciona un gimnasio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _dateController,
                    style: const TextStyle(color: Colors.white),
                    decoration: finalInputDecoration(
                      'Fecha del Combate',
                      suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecciona una fecha.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _timeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: finalInputDecoration(
                      'Hora del Combate',
                      suffixIcon: const Icon(Icons.access_time, color: Colors.white70),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecciona una hora.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  if (_isSubmitting)
                    const Center(child: CircularProgressIndicator(color: Colors.red))
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Enviar Propuesta',
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                        onPressed: _submitCreateCombat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCombatantInfoCard() {
    return Card(
      color: Colors.black.withOpacity(0.6),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.red.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de la Propuesta:',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _combatantColumn(widget.creatorName, "Proponente", Icons.person_pin_circle_rounded)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 36),
                      SizedBox(height: 4),
                      Text("VS",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(child: _combatantColumn(widget.opponentName, "Oponente", Icons.person_pin_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _combatantColumn(String name, String role, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.red.shade300, size: 32),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          role,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildGymDropdown(
      InputDecoration Function(String, {Widget? suffixIcon}) inputDecoration) {
    if (_isLoadingGyms) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: CircularProgressIndicator(color: Colors.red),
      ));
    }
    if (_gyms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No hay gimnasios disponibles para seleccionar.',
          style: TextStyle(color: Colors.orangeAccent.shade100, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedGymId,
      items: _gyms.map((gym) {
        return DropdownMenuItem<String>(
          value: gym.id,
          child: Text(gym.name, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGymId = value;
        });
      },
      decoration: inputDecoration('Gimnasio Sede del Combate',
          suffixIcon: Icon(Icons.sports_kabaddi, color: Colors.white70)),
      dropdownColor: Colors.grey.shade800,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      isExpanded: true,
      iconEnabledColor: Colors.redAccent,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, selecciona un gimnasio.';
        }
        return null;
      },
      hint: const Text('Selecciona un gimnasio',
          style: TextStyle(color: Colors.white54)),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}