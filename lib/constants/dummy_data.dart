import 'package:latlong2/latlong.dart'; // ম্যাপের লোকেশনের জন্য

class DummyData {
  // ওয়ার্কার লিস্ট
  static final List<Map<String, dynamic>> baseWorkers = [
    {
      "id": "1",
      "name": "Rahim (BD)",
      "role": "RICKSHAW",
      "location": const LatLng(23.8103, 90.4125),
      "address": "Dhaka, BD",
      "image": "https://i.pravatar.cc/150?img=11",
      "price": "50 ৳",
      "verified": true,
      "isLive": true,
      "phone": "01700000000",
      "gender": "Male",
      "experience": 5,
    },
    {
      "id": "2",
      "name": "Fatima (BD)",
      "role": "MAID",
      "location": const LatLng(23.8150, 90.4150),
      "address": "Mirpur, BD",
      "image": "https://i.pravatar.cc/150?img=5",
      "price": "5000 ৳",
      "verified": true,
      "isLive": false,
      "phone": "01800000000",
      "gender": "Female",
      "experience": 2,
    },
    {
      "id": "3",
      "name": "John (USA)",
      "role": "ELECTRICIAN",
      "location": const LatLng(40.7128, -74.0060),
      "address": "NY, USA",
      "image": "https://i.pravatar.cc/150?img=33",
      "price": "\$ 80",
      "verified": true,
      "isLive": false,
      "phone": "123456",
      "gender": "Male",
      "experience": 8,
    },
  ];

  // কিছু ডামি নোটিফিকেশন
  static List<Map<String, dynamic>> notifications = [
    {
      "id": 1,
      "title": "Mithila accepted request",
      "time": "2m ago",
      "read": false,
    },
    {"id": 2, "title": "New gardener nearby", "time": "1h ago", "read": false},
    {"id": 3, "title": "Payment success", "time": "4pm", "read": true},
  ];
}
