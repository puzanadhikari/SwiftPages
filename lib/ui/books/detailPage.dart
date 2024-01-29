import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg instead of flutter_svg/svg.dart
import 'allBooks.dart';

class AllBookDetailPage extends StatefulWidget {
  final Book book;

  AllBookDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  State<AllBookDetailPage> createState() => _AllBookDetailPageState();
}

class _AllBookDetailPageState extends State<AllBookDetailPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          child:Stack(
            children: [
              SvgPicture.asset('assets/background.svg',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height,
                // color: Color(0xff#FCCAAC),
              ),
             Stack(
               children: [

                 Padding(
                   padding: const EdgeInsets.only(top:200.0,left: 20,right: 20),
                   child: SingleChildScrollView(
                     scrollDirection: Axis.vertical,
                     child: Container(
                       height: MediaQuery.of(context).size.height,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(30),
                         color: Color(0xFF283E50),
                       ),
                       child: Padding(
                         padding: const EdgeInsets.only(top:120.0,left: 5,right: 5),
                         child: Column(
                           children: [
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Column(
                                   children: [
                                     Container(
                                       height:50,
                                       width:100,
                                       decoration: BoxDecoration(
                                         color: Color(0xffFF997A),
                                         borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                       ),
                                       child: Center(child: Text(widget.book.publishedDate.toString(),style: TextStyle(color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                     ),
                                     Text("Date",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),)
                                   ],
                                 ),
                                 Column(
                                   children: [
                                     Container(
                                       height:50,
                                       width:100,
                                       decoration: BoxDecoration(
                                         color: Color(0xffFF997A),
                                         borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                       ),
                                       child: Center(child: Text(widget.book.rating.toString(),style: TextStyle(color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                     ),
                                     Text("Rating",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),)
                                   ],
                                 ),
                                 Column(
                                   children: [
                                     Container(
                                       height:50,
                                       width:100,
                                       decoration: BoxDecoration(
                                         color: Color(0xffFF997A),
                                         borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                       ),
                                       child: Center(child: Text(widget.book.pageCount.toString(),style: TextStyle(color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                     ),
                                     Text("Pages",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),)
                                   ],
                                 ),


                               ],
                             ),
                             SizedBox(height: 20,),
                             Text("About",style: TextStyle(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold),),

                             SizedBox(height: 10,),
                             Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Text(

                                 widget.book.description,style: TextStyle(color: Colors.white,fontSize: 14),
                                 textAlign: TextAlign.center,),
                             ),

                           ],
                         ),
                       ),

                     ),
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.only(top: 50.0),
                   child: Align(
                     alignment: Alignment.topCenter,
                     child: Column(
                       children: [
                         Column(
                           children: [
                             Container(
                               child: Image.network(widget.book.imageLink),
                             ),
                             SizedBox(height: 10,),
                             Container(
                               child:Text(widget.book.title,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),)
                             ),

                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
                 Center(
                   child: Padding(
                     padding:  EdgeInsets.only(top:MediaQuery.of(context).size.height/1.2),
                     child: ElevatedButton(
                       onPressed: () {
                       },
                       child: Text("Add To Self",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 18),),
                       style: ButtonStyle(
                         backgroundColor: MaterialStateProperty.all<Color>(Color(0xffFF997A)),
                         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                           RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(15.0),
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),


               ],
             )
            ],
          )
        ),
      ),
    );
  }
}
