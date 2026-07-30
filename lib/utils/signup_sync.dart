class SignupSync {
  static List<Map<String, dynamic>> vegetables = [
    {
      "key": "gajar",
      "name": "Gajar",
      "path": "assets/vegetables/01.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "chukundar",
      "name": "Chukundar",
      "path": "assets/vegetables/02.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "mashroom",
      "name": "Mashroom",
      "path": "assets/vegetables/03.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "simla_mirch",
      "name": "Simla mirch",
      "path": "assets/vegetables/04.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "sahjan",
      "name": "Sahjan",
      "path": "assets/vegetables/05.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "bhindi",
      "name": "Bhindi",
      "path": "assets/vegetables/06.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "papita",
      "name": "Papita",
      "path": "assets/vegetables/07.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "nimbu",
      "name": "Nimbu",
      "path": "assets/vegetables/08.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "parval",
      "name": "Parval",
      "path": "assets/vegetables/09.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "katahal",
      "name": "Katahal",
      "path": "assets/vegetables/10.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "kadima",
      "name": "Kadima",
      "path": "assets/vegetables/11.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "muli",
      "name": "Muli",
      "path": "assets/vegetables/12.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "mirch",
      "name": "Mirch",
      "path": "assets/vegetables/13.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "matar",
      "name": "Matar",
      "path": "assets/vegetables/14.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "lahsun",
      "name": "Lahsun",
      "path": "assets/vegetables/15.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "aadi",
      "name": "Aadi",
      "path": "assets/vegetables/16.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "karela",
      "name": "Karela",
      "path": "assets/vegetables/17.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "khira",
      "name": "Khira",
      "path": "assets/vegetables/18.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "kadua",
      "name": "Kadua",
      "path": "assets/vegetables/19.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "foolgobhi",
      "name": "Foolgobhi",
      "path": "assets/vegetables/20.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "bhatta_baingan",
      "name": "Bhatta baingan",
      "path": "assets/vegetables/21.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "baingan",
      "name": "Baingan",
      "path": "assets/vegetables/25.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "bins",
      "name": "Bins",
      "path": "assets/vegetables/27.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
    {
      "key": "shakarakand",
      "name": "Shakarakand",
      "path": "assets/vegetables/28.jpeg",
      "price": "15.00",
      "unit": "Kilogram",
      "common": 1,
    },
  ];

  static Map<String, dynamic>? getVegetableByKey(String key) {
    try {
      return vegetables.firstWhere((veg) => veg['key'] == key);
    } catch (e) {
      return null;
    }
  }

  static String? getVegetableImagePath(String key) {
    final veg = getVegetableByKey(key);
    return veg?['path'];
  }

  static String? getVegetableName(String key) {
    final veg = getVegetableByKey(key);
    return veg?['name'];
  }

  static List<Map<String, dynamic>> defaultCharges = [
    {
      "charge_name": "Commission",
      "charge_type": "percentage",
      "charge_amount": 10.0,
      "charge_for": "buyer",
      "is_default": 1,
    },
    {
      "charge_name": "Commission",
      "charge_type": "percentage",
      "charge_amount": 10.0,
      "charge_for": "seller",
      "is_default": 1,
    },
  ];
}
