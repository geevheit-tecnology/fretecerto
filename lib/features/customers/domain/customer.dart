class Customer {
  const Customer({
    this.id,
    required this.type,
    required this.document,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    this.tradeName = '',
    this.status = '',
    this.mainActivity = '',
  });

  final String? id;
  final String type;
  final String document;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String tradeName;
  final String status;
  final String mainActivity;

  Customer copyWith({
    String? id,
    String? type,
    String? document,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? address,
    String? tradeName,
    String? status,
    String? mainActivity,
  }) {
    return Customer(
      id: id ?? this.id,
      type: type ?? this.type,
      document: document ?? this.document,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      tradeName: tradeName ?? this.tradeName,
      status: status ?? this.status,
      mainActivity: mainActivity ?? this.mainActivity,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'type': type,
      'document': document,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'address': address,
      'trade_name': tradeName,
      'status': status,
      'main_activity': mainActivity,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString(),
      type: map['type']?.toString() ?? '',
      document: map['document']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      tradeName: map['trade_name']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      mainActivity: map['main_activity']?.toString() ?? '',
    );
  }
}
