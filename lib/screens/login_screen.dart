import 'package:flutter/material.dart';
import 'dart:convert'; // Para codificar/decodificar JSON
import 'package:http/http.dart' as http; // Para hacer llamadas API

// Asegúrate que la ruta a tu pantalla principal o la siguiente pantalla después del login sea correcta
// import 'home_screen.dart'; // Ejemplo
// import 'fighter_list_screen.dart'; // O esta si vas directo a la lista

// ✅ Clase global para guardar sesión (ya la tenías definida)
class Session {
  static String? token;
  static String? refreshToken;
  static String? userId;
  static String? username;
}

// Convertido a StatefulWidget para manejar el estado de carga (_isLoading)
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // Variable de estado para manejar el indicador de carga
  bool _isLoading = false;

  // --- Función para manejar el proceso de login ---
  Future<void> _loginUser() async {
    // Validaciones básicas (ya las tenías)
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un correo válido')),
      );
      return;
    }
    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener mínimo 8 caracteres')),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // URL del endpoint de login (la que tenías)
      // ¡Asegúrate que esta sea la URL correcta de TU backend!
      // Y que este endpoint devuelva { token, refreshToken, userId, username }
      // O { token, refreshToken, user: { id, username } } -> ajusta la extracción abajo si es así.
      final url = Uri.parse('http://localhost:9000/api/users/login');

      // Realizar la petición POST
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      // Procesar la respuesta
      if (response.statusCode == 200) { // 200 OK = Login exitoso
        final body = jsonDecode(response.body);

        // ---->>>> ASIGNACIÓN MEJORADA Y VERIFICACIÓN <<<<----
        // Asigna los valores recibidos a la clase Session
        Session.token = body['token']; // Asume que la respuesta tiene 'token'
        Session.refreshToken = body['refreshToken']; // Asume que la respuesta tiene 'refreshToken'
        Session.userId = body['userId'];
        Session.username = body['username'];

        // --- Log para depuración ---
        // Imprime los valores guardados para poder verificarlos en la consola
        print('--- Login Exitoso (login_screen.dart) ---');
        print('Token: ${Session.token}');
        print('RefreshToken: ${Session.refreshToken}'); // Añadido para completar
        print('UserID: ${Session.userId}');
        print('Username: ${Session.username}');
        // --- Fin Log ---

        // --- Verificación CRUCIAL ANTES de navegar ---
        // Comprueba si los datos esenciales (token, userId, username) NO son null o vacíos
        // Esto evita el error "Datos incompletos" en la siguiente pantalla
        if (Session.token == null || Session.token!.isEmpty ||
            Session.userId == null || Session.userId!.isEmpty ||
            Session.username == null || Session.username!.isEmpty)
        {
           print("ERROR LOGIN: Faltan datos esenciales (token, userId o username) en la respuesta del backend o son nulos/vacíos.");
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error en login: No se recibieron todos los datos necesarios del servidor.')),
           );
           setState(() { _isLoading = false; }); // Ocultar indicador de carga
           return; // No continuar si faltan datos
        }

        // Si todo está OK y los datos se guardaron:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );

        // Navega a la pantalla principal (o la que corresponda)
        // Reemplaza la pantalla actual para que no se pueda volver al login con 'atrás'
        Navigator.pushReplacementNamed(context, '/home'); // Usando la ruta que tenías

      } else {
        // Manejar error de login (credenciales incorrectas, usuario no encontrado, etc.)
        String errorMessage = 'Correo o contraseña incorrectos'; // Mensaje por defecto
        try {
           // Intenta obtener un mensaje más específico del cuerpo de la respuesta de error
           final errorBody = jsonDecode(response.body);
           errorMessage = errorBody['message'] ?? errorMessage;
        } catch(e) {
           // Si el cuerpo no es JSON o no tiene 'message', usa el mensaje por defecto
           print("No se pudo decodificar el mensaje de error del cuerpo: ${response.body}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        setState(() { _isLoading = false; }); // Ocultar indicador de carga
      }
    } catch (e) {
      // Manejar errores de conexión, timeout, formato de URL, etc.
      print("Error durante la llamada API de login: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
      setState(() { _isLoading = false; }); // Ocultar indicador de carga
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Correo Electrónico',
                      filled: true,
                      fillColor: Colors.black,
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Colors.white70), // Ícono
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress, // Teclado para email
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.black,
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Colors.white70), // Ícono
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    // Muestra indicador o botón según el estado _isLoading
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.red)) // Indicador centrado
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder( // Bordes redondeados (opcional)
                                borderRadius: BorderRadius.circular(8),
                              )
                            ),
                            // Llama a _loginUser cuando se presiona el botón
                            onPressed: _loginUser,
                            child: const Text(
                              'Ingresar',
                              style: TextStyle(color: Colors.white, fontSize: 16) // Estilo del texto del botón
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // GestureDetector para ir a la pantalla de registro
                  GestureDetector(
                    onTap: () {
                      // Asegúrate de tener una ruta llamada '/register' en tu MaterialApp
                      Navigator.pushNamed(context, '/register');
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.white),
                        children: [
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // Resaltado
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Limpia los controladores cuando el widget se elimina del árbol
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}