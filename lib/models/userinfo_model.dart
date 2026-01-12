class UserInfoResponse {
  final String? status;
  final String? message;
  final UserData? data;

  UserInfoResponse({this.status, this.message, this.data});

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    // ✅ إذا ما كان في "data"، يعني البيانات جاية مباشرة
    if (json.containsKey('data')) {
      return UserInfoResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      );
    } else {
      // ✅ الشكل الجديد (المباشر)
      return UserInfoResponse(
        status: "success",
        message: "ok",
        data: UserData.fromJson(json),
      );
    }
  }
}

class UserData {
  final String? fullName;
  final int? balance;
  final String? staticIp;
  final String? expStaticIp;
  final User? user;

  UserData({
    this.fullName,
    this.balance,
    this.staticIp,
    this.expStaticIp,
    this.user,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      fullName: json['full_name'],
      balance: json['balance'] is int
          ? json['balance']
          : int.tryParse(json['balance'].toString()),
      staticIp: json['staticIp'] ?? '',
      expStaticIp: json['expStaticIp'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final Personal? personal;
  final Account? account;

  User({this.personal, this.account});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      personal: json['personal'] != null
          ? Personal.fromJson(json['personal'])
          : null,
      account: json['account'] != null
          ? Account.fromJson(json['account'])
          : null,
    );
  }
}

class Personal {
  final String? username;
  final String? phone;
  final String? mobile;
  final String? city;
  final String? central;

  Personal({this.username, this.phone, this.mobile, this.city, this.central});

  factory Personal.fromJson(Map<String, dynamic> json) {
    return Personal(
      username: json['username'],
      phone: json['phone'],
      mobile: json['mobile'],
      city: json['city'],
      central: json['central'],
    );
  }
}

class Account {
  final String? accType;
  final String? deleted;
  final String? packageid;
  final List<SpeedPrice>? speedPrice;

  final String? expireDate;
  final String? registerDate;
  final String? groupName;
  final String? speed;
  final String? gateCode;
  final String? availableTraffic;
  final String? offerExtraTraffic;
  final String? extraTraffic;

  Account({
    this.accType,
    this.deleted,
    this.packageid,
    this.speedPrice,
    this.expireDate,
    this.registerDate,
    this.groupName,
    this.speed,
    this.gateCode,
    this.availableTraffic,
    this.offerExtraTraffic,
    this.extraTraffic,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accType: json['accType'],
      deleted: json['deleted']?.toString(),
      packageid: json['packageid'],
      speedPrice: (json['speedPrice'] as List?)
          ?.map((e) => SpeedPrice.fromJson(e))
          .toList(),
      expireDate: json['expireDate'],
      registerDate: json['registerDate'],
      groupName: json['groupName'],
      speed: json['speed'],
      gateCode: json['gateCode'],
      availableTraffic: json['available_traffic']?.toString(),
      offerExtraTraffic: json['offer_extra_traffic']?.toString(),
      extraTraffic: json['extra_traffic']?.toString(),
    );
  }
}

class SpeedPrice {
  final String? price;
  final String? packagename;
  final String? quota;
  final String? duration;
  final String? speed;

  SpeedPrice({
    this.price,
    this.packagename,
    this.quota,
    this.duration,
    this.speed,
  });

  factory SpeedPrice.fromJson(Map<String, dynamic> json) {
    return SpeedPrice(
      price: json['price']?.toString(),
      packagename: json['packagename'],
      quota: json['quota']?.toString(),
      duration: json['duration']?.toString(),
      speed: json['speed']?.toString(),
    );
  }
}
