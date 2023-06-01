import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:utransport/global/global.dart';

import 'main_screen.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final nameTextEditController = TextEditingController();
  final emailTextEditController = TextEditingController();
  final phoneTextEditController = TextEditingController();
  final addressTextEditController = TextEditingController();
  final passwordTextEditController = TextEditingController();
  final confirmTextEditController = TextEditingController();



  bool _passwordVisible = false;

  final _formKey = GlobalKey<FormState>();

  void _submit() async{

    if(_formKey.currentState!.validate()){
      await firebaseAuth.createUserWithEmailAndPassword(
          email: emailTextEditController.text.trim(),
          password: passwordTextEditController.text.trim()
      ).then((auth)async {
        currentUser = auth.user;
        if(currentUser != null){
          Map userMap = {
            "id": currentUser!.uid,
            "name":nameTextEditController.text.trim(),
            "email":emailTextEditController.text.trim(),
            "address":addressTextEditController.text.trim(),
            "phone":phoneTextEditController.text.trim(),
          };


          DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
          userRef.child(currentUser!.uid).set(userMap);
        }

        await Fluttertoast.showToast(msg: "Registration Successfully");
        Navigator.push(context, MaterialPageRoute(builder: (c)=>MainScreen()));
      }).catchError((errorMessage){
        Fluttertoast.showToast(msg: "Error occured: \n $errorMessage");
      });
    }
    else{
      Fluttertoast.showToast(msg: "Not all field are valid");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(

        body: ListView(
          padding: EdgeInsets.all(0),
          children: [
            Column(
              children: [
                Image.asset('images/udom.jpg'),

                SizedBox(height: 20,),

                Text(
                  'Registration From',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Name",
                                hintStyle: TextStyle(
                                  color: Colors.grey
                                ),
                                //filled: true,
                                //fillColor: Colors.grey,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)
                                ),

                                prefixIcon: Icon(Icons.person),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return 'Name can\'t be empty';
                                }if(text.length<2){
                                  return 'Please! Enter valid name';
                                }if(text.length>50){
                                  return 'Please! Name should contain less than 50 charaters';
                                }
                              },

                              onChanged: (text)=>setState(() {
                                nameTextEditController.text = text;
                              }),
                            ),
                            SizedBox(height: 10,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Email",
                                hintStyle: TextStyle(
                                    color: Colors.grey
                                ),
                                //filled: true,
                                //fillColor: Colors.grey,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),

                                prefixIcon: Icon(Icons.email),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return 'Email can\'t be empty';
                                }if(EmailValidator.validate(text)== true){
                                  return null;
                                }
                                if(text.length<2){
                                  return 'Please! Enter valid Email';
                                }if(text.length>99){
                                  return 'Email can\'t be more than 99';
                                }
                              },

                              onChanged: (text)=>setState(() {
                                emailTextEditController.text = text;
                              }),

                            ),
                            SizedBox(height: 10,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Address",
                                hintStyle: TextStyle(
                                    color: Colors.grey
                                ),
                                //filled: true,
                                //fillColor: Colors.grey,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),

                                prefixIcon: Icon(Icons.location_city),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return 'Address can\'t be empty';
                                }if(EmailValidator.validate(text)== true){
                                  return null;
                                }
                                if(text.length<2){
                                  return 'Please! Enter valid address';
                                }if(text.length>99){
                                  return 'Address can\'t be more than 99';
                                }
                              },

                              onChanged: (text)=>setState(() {
                                addressTextEditController.text = text;
                              }),

                            ),
                            SizedBox(height: 10,),


                            IntlPhoneField(
                              showCountryFlag: false,
                              dropdownIcon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                                decoration: InputDecoration(
                                  hintText: "Phone Number",
                                  hintStyle: TextStyle(
                                      color: Colors.grey
                                  ),
                                  //filled: true,
                                  //fillColor: Colors.grey,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                ),
                              initialCountryCode: '',
                              onChanged: (text)=>setState(() {
                                phoneTextEditController.text = text.completeNumber;
                              }),
                            ),
                            SizedBox(height: 10,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Password",
                                hintStyle: TextStyle(
                                    color: Colors.grey
                                ),
                                //filled: true,
                                //fillColor: Colors.grey,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),

                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible? Icons.visibility: Icons.visibility_off,
                                  ),
                                  onPressed: (){
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return 'Password can\'t be empty';
                                }if(EmailValidator.validate(text)== true){
                                  return null;
                                }
                                if(text.length<8){
                                  return 'Please! Enter valid Password';
                                }if(text.length>20){
                                  return 'Password can\'t be more than 20';
                                }
                                return null;
                              },

                              onChanged: (text)=>setState(() {
                                passwordTextEditController.text = text;
                              }),

                            ),

                            //SizedBox(height: 10,),

                            // TextFormField(
                            //   inputFormatters: [
                            //     LengthLimitingTextInputFormatter(50)
                            //   ],
                            //   decoration: InputDecoration(
                            //     hintText: "Confirm Password",
                            //     hintStyle: TextStyle(
                            //         color: Colors.grey
                            //     ),
                            //     //filled: true,
                            //     //fillColor: Colors.grey,
                            //     border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.circular(10)
                            //     ),
                            //
                            //     prefixIcon: Icon(Icons.lock),
                            //     // suffixIcon: IconButton(
                            //     //   icon: Icon(
                            //     //     _passwordVisible? Icons.visibility: Icons.visibility_off,
                            //     //   ),
                            //     //   onPressed: (){
                            //     //     setState(() {
                            //     //       _passwordVisible = !_passwordVisible;
                            //     //     });
                            //     //   },
                            //     // ),
                            //   ),
                            //   autovalidateMode: AutovalidateMode.onUserInteraction,
                            //   validator: (text){
                            //     if(text == null || text.isEmpty){
                            //       return 'Confirm Password can\'t be empty';
                            //     }if(EmailValidator.validate(text)== true){
                            //       return null;
                            //     }
                            //     if(text != passwordTextEditController.text){
                            //       return 'Password does not match';
                            //     }if(text.length>20){
                            //       return 'Email can\'t be more than 20';
                            //     }
                            //   },
                            //
                            //   onChanged: (text)=>setState(() {
                            //     confirmTextEditController.text = text;
                            //   }),
                            //
                            // ),
                            SizedBox(height: 20,),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,

                              ),
                                onPressed: (){
                                _submit();
                                },
                                child: Text(
                                  'Register',
                                ),
                            ),
                            SizedBox(height: 5,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Have an account?", style: TextStyle(color: Colors.grey),
                                ),

                                SizedBox(width: 5,),
                                GestureDetector(
                                  onTap: (){},
                                  child: Text("Sign in", style: TextStyle(color: Colors.blue),
                                  ),
                                )
                              ],
                            )

                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),

      ),
    );
  }
}
