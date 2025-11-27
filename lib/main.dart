import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:login/sign_up.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(SignUpScreen());
// }


void main(){

  Person person = Person(name: "John", age: 30);
  print(person.name);
  print(person.age);

  person = person.copyWith(name: "Jane");
  print(person.name);
  print(person.age);

}

class Person {
  final String name;
  final int age;
  Person({required this.name, required this.age});

  Person copyWith({String? name, int? age}) {
    return Person(name: name ?? this.name, age: age ?? this.age);
  }
}
