import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  String _selectedCountry = 'India';
  bool _isLoading = false;

  // Supported countries with their currency symbols
  final Map<String, Map<String, String>> _countries = {
    'India': {'symbol': '₹', 'code': 'INR', 'locale': 'en_IN'},
    'United States': {'symbol': '\$', 'code': 'USD', 'locale': 'en_US'},
    'United Kingdom': {'symbol': '£', 'code': 'GBP', 'locale': 'en_GB'},
    'European Union': {'symbol': '€', 'code': 'EUR', 'locale': 'en_EU'},
    'Japan': {'symbol': '¥', 'code': 'JPY', 'locale': 'ja_JP'},
    'Australia': {'symbol': 'A\$', 'code': 'AUD', 'locale': 'en_AU'},
    'Canada': {'symbol': 'C\$', 'code': 'CAD', 'locale': 'en_CA'},
    'Switzerland': {'symbol': 'CHF', 'code': 'CHF', 'locale': 'de_CH'},
    'China': {'symbol': '¥', 'code': 'CNY', 'locale': 'zh_CN'},
    'South Korea': {'symbol': '₩', 'code': 'KRW', 'locale': 'ko_KR'},
    'Brazil': {'symbol': 'R\$', 'code': 'BRL', 'locale': 'pt_BR'},
    'Russia': {'symbol': '₽', 'code': 'RUB', 'locale': 'ru_RU'},
    'Mexico': {'symbol': 'MX\$', 'code': 'MXN', 'locale': 'es_MX'},
    'Singapore': {'symbol': 'S\$', 'code': 'SGD', 'locale': 'en_SG'},
    'Hong Kong': {'symbol': 'HK\$', 'code': 'HKD', 'locale': 'en_HK'},
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedCountry();
  }

  Future<void> _loadSelectedCountry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCountry = prefs.getString('selected_country') ?? 'India';
    });
  }

  Future<void> _saveCountrySelection(String country) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_country', country);
      await prefs.setString('currency_symbol', _countries[country]!['symbol']!);
      await prefs.setString('currency_code', _countries[country]!['code']!);
      await prefs.setString('currency_locale', _countries[country]!['locale']!);

      setState(() {
        _selectedCountry = country;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Country updated to $country'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save country selection'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Country'),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating country selection...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose your country to set the appropriate currency symbol and formatting:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _countries.length,
                      itemBuilder: (context, index) {
                        final country = _countries.keys.toList()[index];
                        final countryData = _countries[country]!;
                        final isSelected = country == _selectedCountry;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected ? Colors.green.shade50 : null,
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  countryData['symbol']!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              country,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.green.shade700 : null,
                              ),
                            ),
                            subtitle: Text(
                              '${countryData['code']} - ${countryData['symbol']}',
                              style: TextStyle(
                                color: isSelected ? Colors.green.shade600 : Colors.grey.shade600,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 28,
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.shade400,
                                  ),
                            onTap: () => _saveCountrySelection(country),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This setting affects how currency amounts are displayed throughout the app. You can change this anytime in settings.',
                              style: TextStyle(color: Colors.blue, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
