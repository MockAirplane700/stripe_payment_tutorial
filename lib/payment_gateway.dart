import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentGateway  extends StatefulWidget {
  const PaymentGateway({Key? key}) : super(key: key);

  @override
  State<PaymentGateway> createState() => _PaymentGatewayState();
}

class _PaymentGatewayState extends State<PaymentGateway> {

  Future<void> makePayment() async {
    try {
      // Recommended we do this on the server
      var paymentIntent = await createPaymentIntent('100', 'CAD');

      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // we get this from the payment intent
            paymentIntentClientSecret: paymentIntent['client_secret'],
            style: ThemeMode.dark,
            merchantDisplayName: 'Testing Merchant sizibamthandazo'
        ),
      ).then((value) {});
      // display payment sheet
      displayPaymentSheet();
    } catch (error) {
      throw Exception(error.toString());
    }
  }// end make payment

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        showDialog(context: context, builder: (context) =>
            AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,

                  ),
                  SizedBox(height: 10.0,),
                  Text('Payment Successful')
                ],
              ),
            ));
      }).onError((error, stackTrace) {
        throw Exception(error.toString());
      });
    } on StripeException catch (error) {
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text('Payment failed ')
              ],
            )
          ],
        ),
      );
    }catch (error) {
      throw Exception(error.toString());
    }
  }//end display payment sheet

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String,dynamic> body = {
        'amount' : calculateAmount(amount),
        'currency':currency,
      };

      // Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET']}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return jsonDecode(response.body);
    }catch (error) {
      throw Exception(error.toString());
    }//end try-catch
  }//end create payment intent

  calculateAmount(String amount) {
    final calculatedAmount = (int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }//end calculate amount

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            makePayment();
          },
          child: const Text('Pay'),
        ),
      ),
    );
  }
}

