import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meditrack.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        bloodGroup TEXT,
        conditions TEXT,
        allergies TEXT,
        emergencyContactName TEXT,
        emergencyContactPhone TEXT,
        createdAt TEXT NOT NULL,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0,
        lastUpdated TEXT,
        profileImagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        systolic REAL,
        diastolic REAL,
        heartRate REAL,
        temperature REAL,
        oxygenSaturation REAL,
        bloodGlucose REAL,
        weight REAL,
        notes TEXT,
        recordedAt TEXT NOT NULL,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0,
        lastUpdated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        createdAt TEXT NOT NULL,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0,
        lastUpdated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE symptoms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symptomName TEXT NOT NULL,
        severity INTEGER NOT NULL,
        notes TEXT,
        recordedAt TEXT NOT NULL,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0,
        lastUpdated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE doctor_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctorName TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        diagnosis TEXT,
        prescription TEXT,
        followUpDate TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0,
        lastUpdated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        doctorName TEXT,
        date TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        userId TEXT,
        syncStatus INTEGER DEFAULT 0,
        lastUpdated TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS user_profile');
      await db.execute('DROP TABLE IF EXISTS vitals');
      await db.execute('DROP TABLE IF EXISTS medicines');
      await db.execute('DROP TABLE IF EXISTS symptoms');
      await db.execute('DROP TABLE IF EXISTS doctor_visits');
      await db.execute('DROP TABLE IF EXISTS prescriptions');
      await _onCreate(db, newVersion);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prescriptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          doctorName TEXT,
          date TEXT NOT NULL,
          imagePath TEXT NOT NULL,
          notes TEXT,
          createdAt TEXT NOT NULL,
          userId TEXT,
          syncStatus INTEGER DEFAULT 0,
          lastUpdated TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN profileImagePath TEXT');
      } catch (e) {
        // Ignore if the column already exists
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
