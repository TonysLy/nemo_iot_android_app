import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Ble {
  String name;
  String data;
  Ble(this.name, this.data);
  // 可选：如果需要，可以添加一个工厂方法来从 Map 转换为实体类
  factory Ble.fromJson(Map<String, dynamic> json) {
    return Ble(
      json['name'] as String,
      json['data'] as String,
    );
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'data': data,
      };
}
