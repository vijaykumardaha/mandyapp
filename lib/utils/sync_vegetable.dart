class SyncVegetable {
  static List<Map<String, dynamic>> vegetables = [
    {
      "key": "gajar",
      "name": "Gajar",
      "path": "assets/vegetables/01.jpeg"
    },
    {
      "key": "chukundar",
      "name": "Chukundar",
      "path": "assets/vegetables/02.jpeg"
    },
    {
      "key": "mashroom",
      "name": "Mashroom",
      "path": "assets/vegetables/03.jpeg"
    },
    {
      "key": "simla_mirch",
      "name": "Simla mirch",
      "path": "assets/vegetables/04.jpeg"
    },
    {
      "key": "sahjan",
      "name": "Sahjan",
      "path": "assets/vegetables/05.jpeg"
    },
    {
      "key": "bhindi",
      "name": "Bhindi",
      "path": "assets/vegetables/06.jpeg"
    },
    {
      "key": "papita",
      "name": "Papita",
      "path": "assets/vegetables/07.jpeg"
    },
    {
      "key": "nimbu",
      "name": "Nimbu",
      "path": "assets/vegetables/08.jpeg"
    },
    {
      "key": "parval",
      "name": "Parval",
      "path": "assets/vegetables/09.jpeg"
    },
    {
      "key": "katahal",
      "name": "Katahal",
      "path": "assets/vegetables/10.jpeg"
    },
    {
      "key": "kadima",
      "name": "Kadima",
      "path": "assets/vegetables/11.jpeg"
    },
    {
      "key": "muli",
      "name": "Muli",
      "path": "assets/vegetables/12.jpeg"
    },
    {
      "key": "mirch",
      "name": "Mirch",
      "path": "assets/vegetables/13.jpeg"
    },
    {
      "key": "matar",
      "name": "Matar",
      "path": "assets/vegetables/14.jpeg"
    },
    {
      "key": "lahsun",
      "name": "Lahsun",
      "path": "assets/vegetables/15.jpeg"
    },
    {
      "key": "aadi",
      "name": "Aadi",
      "path": "assets/vegetables/16.jpeg"
    },
    {
      "key": "karela",
      "name": "Karela",
      "path": "assets/vegetables/17.jpeg"
    },
    {
      "key": "khira",
      "name": "Khira",
      "path": "assets/vegetables/18.jpeg"
    },
    {
      "key": "kadua",
      "name": "Kadua",
      "path": "assets/vegetables/19.jpeg"
    },
    {
      "key": "foolgobhi",
      "name": "Foolgobhi",
      "path": "assets/vegetables/20.jpeg"
    },
    {
      "key": "bhatta_baingan",
      "name": "Bhatta baingan",
      "path": "assets/vegetables/21.jpeg"
    },
    {
      "key": "baingan",
      "name": "Baingan",
      "path": "assets/vegetables/25.jpeg"
    },
    {
      "key": "bins",
      "name": "Bins",
      "path": "assets/vegetables/27.jpeg"
    },
    {
      "key": "shakarakand",
      "name": "Shakarakand",
      "path": "assets/vegetables/28.jpeg"
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
}
