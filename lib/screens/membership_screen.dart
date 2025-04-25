import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crown Image
            Center(
              child: Image.asset(
                'assets/crown.png',
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),

            // Katha Title
            Center(
              child: Text(
                'katha',
                style: GoogleFonts.cormorantUnicase(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA3D749),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Description
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Hey there! 👋\n\n",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                    "We're students who absolutely love webnovels, webtoons, and anime. "
                        "Building ",
                  ),
                  TextSpan(
                    text: "Katha",
                    style: TextStyle(color: Color(0xFFA3D749), fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                    " is our dream, and while we know things might move a little slower for us, "
                        "we're giving it everything we've got to make this platform truly special for you.\n\n"
                        "Seriously, it means the world to us!\n\n"
                        "We're working hard on creating a membership plan that not only supports amazing creators "
                        "but also gives you the best value. 🌟\n\n"
                        "Thanks for being patient and being part of this journey with us!",
                  ),
                ],
              ),
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 30),

            // Cheers Text
            const Text(
              "Cheers!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}