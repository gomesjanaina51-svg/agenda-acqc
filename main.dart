import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. MODELO ---
class Task {
  String id;
  String title;
  bool isDone;
  DateTime date;
  String? imageUrl;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.date,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'isDone': isDone,
        'date': date.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool,
      date: DateTime.parse(json['date'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

// --- 2. PROVIDER ---
class AppProvider extends ChangeNotifier {
  final List<Task> _tasks;
  bool _isLoggedIn;
  DateTime _selectedDate;
  String? _userName;
  String? _savedEmail;
  String? _savedPassword;

  AppProvider()
      : _tasks = <Task>[],
        _isLoggedIn = false,
        _selectedDate = DateTime.now(),
        _userName = null,
        _savedEmail = null,
        _savedPassword = null {
    loadState();
  }

  // Chaves para Shared Preferences
  static const String _tasksKey = 'tasks';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userNameKey = 'userName';
  static const String _savedEmailKey = 'savedEmail';
  static const String _savedPasswordKey = 'savedPassword';

  // --- MÉTODOS DE PERSISTÊNCIA ---

  Future<void> _saveState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isLoggedInKey, _isLoggedIn);
    
    if (_userName != null) {
      await prefs.setString(_userNameKey, _userName!);
    } else {
      await prefs.remove(_userNameKey);
    }
    
    if (_savedEmail != null) {
        await prefs.setString(_savedEmailKey, _savedEmail!);
        await prefs.setString(_savedPasswordKey, _savedPassword!);
    } else {
        await prefs.remove(_savedEmailKey);
        await prefs.remove(_savedPasswordKey);
    }

    final List<String> jsonTasks = _tasks.map((Task t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_tasksKey, jsonTasks);
  }

  Future<void> loadState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _userName = prefs.getString(_userNameKey);
    _savedEmail = prefs.getString(_savedEmailKey);
    _savedPassword = prefs.getString(_savedPasswordKey);

    final List<String> jsonTasks = prefs.getStringList(_tasksKey) ?? <String>[];
    _tasks.clear();
    _tasks.addAll(jsonTasks.map((String jsonString) {
      return Task.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    }));

    notifyListeners();
  }

  // --- GETTERS ---
  bool get isLoggedIn => _isLoggedIn;
  DateTime get selectedDate => _selectedDate;
  String? get userName => _userName;

  List<Task> get tasksForSelectedDate {
    final List<Task> filteredTasks = _tasks.where((Task task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();

    filteredTasks.sort((Task a, Task b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return filteredTasks;
  }

  // --- MÉTODOS DE AÇÃO (Login, Cadastro, Logout) ---

  bool login(String email, String password) {
    if (email == _savedEmail && password == _savedPassword) {
      _isLoggedIn = true;
      _saveState();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void register(String name, String email, String password) {
    if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
      _isLoggedIn = true;
      _userName = name;
      _savedEmail = email;
      _savedPassword = password;
      _saveState();
      notifyListeners();
    }
  }

  void logout() {
    _isLoggedIn = false;
    _userName = null;
    _saveState();
    notifyListeners();
  }

  // --- MÉTODOS DE TAREFAS ---

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void addTask(String title, {String? imageUrl}) {
    _tasks.add(Task(
      id: DateTime.now().toString(),
      title: title,
      date: _selectedDate,
      isDone: false,
      imageUrl: imageUrl,
    ));
    _saveState();
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((Task t) => t.id == id);
    _saveState();
    notifyListeners();
  }

  void toggleTaskStatus(String id) {
    final int index = _tasks.indexWhere((Task t) => t.id == id);
    if (index != -1) {
      _tasks[index].isDone = !_tasks[index].isDone;
      _saveState();
      notifyListeners();
    }
  }

  void editTask(String id, {String? title, String? imageUrl}) {
    final int index = _tasks.indexWhere((Task t) => t.id == id);
    if (index != -1) {
      if (title != null) _tasks[index].title = title;
      if (imageUrl != null) _tasks[index].imageUrl = imageUrl;
      _saveState();
      notifyListeners();
    }
  }
}

// --- 3. MAIN E WIDGETS BASE ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider<AppProvider>(
      create: (BuildContext _) => AppProvider(),
      builder: (BuildContext context, Widget? child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Agenda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          onPrimary: Colors.black,
          secondary: Color(0xFF03DAC6),
          onSecondary: Colors.black,
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
          error: Color(0xFFCF6679),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AppProvider provider = context.watch<AppProvider>();
    return provider.isLoggedIn ? const HomePage() : const LoginPage();
  }
}

// --- 4. LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Future<void>.delayed(const Duration(milliseconds: 800), () {
        final bool success =
            context.read<AppProvider>().login(_emailController.text, _passController.text);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Email ou senha incorretos!"),
              backgroundColor: Color(0xFFCF6679),
              duration: Duration(seconds: 2),
            ));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Image.network(
                      'https://uniube.br/img/landing/tecnico/logoUniube.png',
                      height: 60,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const Text("MINHA AGENDA",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 40),
                  _buildTextFormField(_emailController, "Email", Icons.email, validator: (String? value) {
                    if (value == null || value.isEmpty) return 'Por favor, insira seu email';
                    if (!value.contains('@')) return 'Email inválido';
                    return null;
                  }),
                  const SizedBox(height: 20),
                  _buildTextFormField(_passController, "Senha", Icons.lock, isPass: true, validator: (String? value) {
                    if (value == null || value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
                    return null;
                  }),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB86FC), foregroundColor: Colors.black),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text("ENTRAR", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push<Widget>(context, MaterialPageRoute<Widget>(builder: (BuildContext context) => const RegisterPage())),
                    child: const Text("Criar nova conta", style: TextStyle(color: Color(0xFF03DAC6))),
                  ),
                  const SizedBox(height: 40),
                  Divider(color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 20),
                  const Text("Aluno: JANAINA GOMES",
                      style: TextStyle(color: Color(0xFF03DAC6), fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("RA: 1165625", style: TextStyle(color: Colors.white70, fontFamily: 'Monospace', fontSize: 16)),
                  const Text("UNIUBE, CACHOEIRO DE ITAPEMIRIM",
                      style: TextStyle(color: Colors.white70, fontFamily: 'Monospace', fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String hint, IconData icon,
      {bool isPass = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFBB86FC)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: Color(0xFFCF6679)),
      ),
    );
  }
}

// --- 5. REGISTER PAGE ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        context.read<AppProvider>().register(_nameController.text, _emailController.text, _passController.text);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pop(context); 
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context))),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const Icon(Icons.person_add, size: 60, color: Color(0xFF03DAC6)),
                  const SizedBox(height: 10),
                  const Text("CRIAR CONTA",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 40),
                  _buildTextFormField(_nameController, "Nome Completo", Icons.person,
                      validator: (String? value) => value == null || value.isEmpty ? 'Insira seu nome' : null),
                  const SizedBox(height: 20),
                  _buildTextFormField(_emailController, "Email", Icons.email, validator: (String? value) {
                    if (value == null || value.isEmpty) return 'Insira seu email';
                    if (!value.contains('@')) return 'Email inválido';
                    return null;
                  }),
                  const SizedBox(height: 20),
                  _buildTextFormField(_passController, "Senha", Icons.lock, isPass: true, validator: (String? value) {
                    if (value == null || value.length < 6) return 'Mínimo de 6 caracteres';
                    return null;
                  }),
                  const SizedBox(height: 20),
                  _buildTextFormField(_confirmPassController, "Confirmar Senha", Icons.lock_outline, isPass: true,
                      validator: (String? value) {
                    if (value == null || value.isEmpty) return 'Confirme a senha';
                    if (value != _passController.text) return 'As senhas não conferem!';
                    return null;
                  }),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03DAC6), foregroundColor: Colors.black),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text("CADASTRAR", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String hint, IconData icon,
      {bool isPass = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF03DAC6)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: Color(0xFFCF6679)),
      ),
    );
  }
}

// --- 6. HOME PAGE (Com Botão Excluir no Diálogo) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppProvider provider = context.watch<AppProvider>();
    final List<Task> tasks = provider.tasksForSelectedDate;
    final DateTime selectedDate = provider.selectedDate;
    final String dateString = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    final String welcomeText = provider.userName != null
        ? "BEM VINDO, ${provider.userName!.toUpperCase()}"
        : "BEM VINDO";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(welcomeText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Tarefas para $dateString", style: const TextStyle(fontSize: 12, color: Color(0xFFBB86FC))),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF03DAC6)),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFBB86FC),
                        onPrimary: Colors.black,
                        surface: Color(0xFF1E1E1E),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != selectedDate) {
                provider.setDate(picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppProvider>().logout(),
          )
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.event_available, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 10),
                  Text("Sem tarefas para $dateString", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (BuildContext context, int index) {
                final Task task = tasks[index];
                // Funcionalidade de Excluir por Deslizamento (Dismissible)
                return Dismissible(
                  key: Key(task.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (DismissDirection direction) => context.read<AppProvider>().removeTask(task.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    color: task.isDone ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C),
                    child: Column(
                      children: <Widget>[
                        if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                task.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                  return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                                },
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => _showEditTaskDialog(context, task),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isDone,
                              activeColor: const Color(0xFF03DAC6),
                              checkColor: Colors.black,
                              onChanged: (bool? _) => context.read<AppProvider>().toggleTaskStatus(task.id),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isDone ? TextDecoration.lineThrough : null,
                                color: task.isDone ? Colors.grey : Colors.white,
                              ),
                            ),
                            trailing: const Icon(Icons.edit, color: Color(0xFFBB86FC)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF03DAC6),
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final TextEditingController imageController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Nova Tarefa", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "O que precisa ser feito?",
                hintStyle: TextStyle(color: Colors.white54),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: imageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.image, color: Color(0xFFBB86FC)),
                hintText: "URL da Imagem (Opcional)",
                hintStyle: TextStyle(color: Colors.white54),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC), foregroundColor: Colors.black),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AppProvider>().addTask(controller.text,
                    imageUrl: imageController.text.isEmpty ? null : imageController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    ).then((void value) {
      controller.dispose();
      imageController.dispose();
    });
  }

  // Diálogo para Edição de Tarefas (AGORA COM BOTÃO EXCLUIR)
  void _showEditTaskDialog(BuildContext context, Task task) {
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController imageController = TextEditingController(text: task.imageUrl);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Editar Tarefa", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Título da tarefa",
                hintStyle: TextStyle(color: Colors.white54),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: imageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.image, color: Color(0xFFBB86FC)),
                hintText: "URL da Imagem (Opcional)",
                hintStyle: TextStyle(color: Colors.white54),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          // NOVO BOTÃO EXCLUIR
          TextButton(
            onPressed: () {
              context.read<AppProvider>().removeTask(task.id);
              Navigator.pop(ctx);
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Color(0xFFCF6679))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC), foregroundColor: Colors.black),
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                context.read<AppProvider>().editTask(
                      task.id,
                      title: titleController.text,
                      imageUrl: imageController.text.isEmpty ? null : imageController.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    ).then((void value) {
      titleController.dispose();
      imageController.dispose();
    });
  }
}