package com.example.eclapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.expresspaygh.api.ExpressPayApi
import com.expresspaygh.api.ExpressPayApi.ExpressPayPaymentCompletionListener
import org.json.JSONObject

class MainActivity: FlutterActivity(), ExpressPayPaymentCompletionListener {
    private val CHANNEL = "com.yourcompany.expresspay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startExpressPay") {
                val params = call.arguments as? HashMap<String, String>
                if (params != null) {
                    val expressPayApi = ExpressPayApi(this, "https://sandbox.expresspaygh.com/api/sdk/php/server.php")
                    expressPayApi.setDebugMode(true)
                    // Wrap the listener to log the server response
                    expressPayApi.submitAndCheckout(params, this, object : ExpressPayApi.ExpressPayPaymentCompletionListener {
                        override fun onExpressPayPaymentFinished(paymentCompleted: Boolean, errorMessage: String?) {
                            println("ExpressPay payment finished: $paymentCompleted, $errorMessage")
                        }
                    })
                    // Add a submit listener to log the server response
                    expressPayApi.submit(params, this, object : ExpressPayApi.ExpressPaySubmitCompletionListener {
                        override fun onExpressPaySubmitFinished(response: org.json.JSONObject?, errorMessage: String?) {
                            println("ExpressPay SUBMIT server response: " + response?.toString())
                            println("ExpressPay SUBMIT error message: $errorMessage")
                            if (response != null && response.has("token")) {
                                println("ExpressPay SUBMIT token: " + response.getString("token"))
                            } else {
                                println("ExpressPay SUBMIT: No token in response!")
                            }
                        }
                    })
                } else {
                    result.error("INVALID_PARAMS", "Params are null or invalid", null)
                }
            }
        }
    }

    // This is called by the SDK when payment is finished
    override fun onExpressPayPaymentFinished(paymentCompleted: Boolean, errorMessage: String?) {
        // You can send the result back to Flutter using a stored MethodChannel.Result
        // For now, just log or handle as needed
        println("ExpressPay payment finished: $paymentCompleted, $errorMessage")
        // If you stored the 'result' from MethodChannel, call result.success(...) here
    }
}