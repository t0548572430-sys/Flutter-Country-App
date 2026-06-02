import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CountryExplorerApp());
}

class CountryExplorerApp extends StatelessWidget {
  const CountryExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // העלמת פס הדיבאג
      title: 'מגלה המדינות',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CountrySearchScreen(),
    );
  }
}

// === מסך 1: חיפוש המדינות ורשימת המועדפים ===
class CountrySearchScreen extends StatefulWidget {
  const CountrySearchScreen({super.key});

  @override
  State<CountrySearchScreen> createState() => _CountrySearchScreenState();
}

class _CountrySearchScreenState extends State<CountrySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _countries = [];
  final List _favorites = []; // רשימת מדינות מועדפות
  bool _isLoading = false;
  String _errorMessage = '';

  // פונקציה לשליפת נתונים מה-API
  Future<void> searchCountry(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _countries = [];
    });

    final url = Uri.parse('https://restcountries.com/v3.1/name/$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _countries = data;
        });
      } else {
        setState(() {
          _errorMessage = 'לא נמצאה מדינה בשם זה, נסי שוב.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאת תקשורת. בדקי את חיבור האינטרנט שלך.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // פונקציה להוספה/הסרה של מדינה ממועדפים
  void toggleFavorite(Map<String, dynamic> country) {
    setState(() {
      final countryName = country['name']['common'];
      if (_favorites.any((item) => item['name']['common'] == countryName)) {
        _favorites.removeWhere((item) => item['name']['common'] == countryName);
      } else {
        _favorites.add(country);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 מגלה המדינות',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade300,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // שורת חיפוש מעוצבת
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'הקלידי שם מדינה באנגלית (Israel, Japan, Brazil)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.public),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.teal),
                  onPressed: () => searchCountry(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (value) => searchCountry(value.trim()),
            ),
            const SizedBox(height: 20),

            // תצוגת מועדפים רוחבית (אם יש)
            if (_favorites.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '⭐ מדינות ששמרתי:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    return GestureDetector(
                      onTap: () => openDetailScreen(fav),
                      child: Container(
                        margin: const EdgeInsets.only(left: 12),
                        width: 80,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fav['flags']['png'],
                                width: 60,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fav['name']['common'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
            ],

            // תצוגת התוצאות מה-API
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                          _errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ))
                      : _countries.isEmpty
                          ? const Center(
                              child: Text(
                              'התחילי בחיפוש מדינה כדי לגלות עליה פרטים מעניינים!',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ))
                          : ListView.builder(
                              itemCount: _countries.length,
                              itemBuilder: (context, index) {
                                final country = _countries[index];
                                final countryName = country['name']['common'];
                                final isFav = _favorites.any((item) =>
                                    item['name']['common'] == countryName);

                                // שליפת הבירה בצורה בטוחה
                                final capital = (country['capital'] != null &&
                                        country['capital'].isNotEmpty)
                                    ? country['capital'][0]
                                    : 'לא ידוע';

                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        country['flags']['png'],
                                        width: 60,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(countryName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    subtitle: Text(
                                        'עיר בירה: $capital\nיבשת: ${country['region']}'),
                                    trailing: IconButton(
                                      icon: Icon(
                                        isFav ? Icons.star : Icons.star_border,
                                        color:
                                            isFav ? Colors.amber : Colors.grey,
                                        size: 30,
                                      ),
                                      onPressed: () => toggleFavorite(country),
                                    ),
                                    onTap: () => openDetailScreen(country),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ניווט למסך פרטי המדינה
  void openDetailScreen(Map<String, dynamic> country) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountryDetailScreen(country: country),
      ),
    );
  }
}

// === מסך 2: פירוט מלא על המדינה ===
class CountryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> country;

  const CountryDetailScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final capital =
        (country['capital'] != null && country['capital'].isNotEmpty)
            ? country['capital'][0]
            : 'לא ידוע';
    final population = country['population'] ?? 'לא ידוע';
    final region = country['region'] ?? 'לא ידוע';
    final subregion = country['subregion'] ?? 'לא ידוע';

    // חילוץ נתוני שפות בצורה בטוחה
    String languages = 'לא ידוע';
    if (country['languages'] != null) {
      final Map<String, dynamic> langMap = country['languages'];
      languages = langMap.values.join(', ');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(country['name']['common']),
        backgroundColor: Colors.teal.shade300,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // תמונת הדגל בגדול בראש המסך
            Image.network(
              country['flags']['png'],
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📌 פרטים כלליים:',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 16),

                  // שימוש בווידג'טים מעוצבים להצגת המידע
                  _buildInfoRow(Icons.location_city, 'עיר בירה', capital),
                  const Divider(),
                  _buildInfoRow(Icons.map, 'יבשת', region),
                  const Divider(),
                  _buildInfoRow(Icons.explore, 'אזור', subregion),
                  const Divider(),
                  _buildInfoRow(
                      Icons.people, 'אוכלוסייה', _formatPopulation(population)),
                  const Divider(),
                  _buildInfoRow(Icons.language, 'שפות רשמיות', languages),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // פונקציית עזר לבניית שורת מידע עם אייקון
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 28),
          const SizedBox(width: 12),
          Text(
            '$title: ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  // פונקציית עזר להוספת פסיקים למספרים גדולים (כדי שהאוכלוסייה תיראה קריאה)
  String _formatPopulation(dynamic pop) {
    if (pop is int) {
      return pop.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
    return pop.toString();
  }
}
