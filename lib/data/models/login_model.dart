
class LoginModel
{
  String? message;
  int?id;
  String?refresh;
  String? access;
  String? role;

  LoginModel.fromJason(Map<String,dynamic> json)
  {
    message = json['message'];
    id = json['id'];
    refresh = json['refresh'];
    access = json['access'];
    role = json['role'];

  }
}






















