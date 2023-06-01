import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:utransport/screens/forget_password_screen.dart';
import 'package:utransport/screens/registration_screen.dart';

import '../global/global.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailTextEditController = TextEditingController();
  final passwordTextEditController = TextEditingController();

  bool _passwordVisible = false;

  final _formKey = GlobalKey<FormState>();
  void _submit() async{

    if(_formKey.currentState!.validate()){
      await firebaseAuth.signInWithEmailAndPassword(
          email: emailTextEditController.text.trim(),
          password: passwordTextEditController.text.trim()
      ).then((auth)async {
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
        userRef.child(firebaseAuth.currentUser!.uid).once().then((value) async {
          final snap = value.snapshot;
          if(snap.value != null){

            currentUser = auth.user;
            await Fluttertoast.showToast(msg: "Successfully Logged In");
            Navigator.push(context, MaterialPageRoute(builder: (c)=>MainScreen()));

          }else{
            await Fluttertoast.showToast(msg: "No records found with email");
            firebaseAuth.signOut();
            Navigator.push(context, MaterialPageRoute(builder: (c)=>MainScreen()));
          }
        });
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
                  'Login From',
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


                            SizedBox(height: 20,),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,

                              ),
                              onPressed: (){
                                _submit();
                              },
                              child: Text(
                                'Login',
                              ),
                            ),
                            SizedBox(height: 5,),

                            GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (c)=>ForgetPasswordScreen()));
                              },
                              child: Text(
                                "Forget Password?",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),

                            SizedBox(height: 5,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account?", style: TextStyle(color: Colors.grey),
                                ),

                                SizedBox(width: 5,),
                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (c)=>RegistrationScreen()));
                                  },
                                  child: Text("Sign up", style: TextStyle(color: Colors.blue),
                                  ),
                                )
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 140),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("UDOM TRANSPORT MANAGEMENT SYSTEM.", style: TextStyle(color: Colors.grey),
                                  ),

                                  SizedBox(width: 1,),

                              Text("[Version No.1.0]", style: TextStyle(color: Colors.grey),)

                                ],
                              ),
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
