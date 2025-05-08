

package com.example.eclapp

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import com.expresspaygh.api.ExpressPayApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.util.HashMap

class ExpressPayPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var expressPayApi: ExpressPayApi? = null
    private var pendingResult: Result? = null
    private var currentRequestCode: Int = 0


    companion object {
        private const val REQUEST_CODE_SUBMIT_AND_CHECKOUT = 1001
        private const val REQUEST_CODE_CHECKOUT = 1002
        private const val REQUEST_CODE_CHECKOUT_WITH_TOKEN = 1003
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.yourapp/expresspay")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                val serverUrl = call.argument<String>("serverUrl")
                expressPayApi = ExpressPayApi(activity!!, serverUrl)
                result.success(null)
            }
            "submitAndCheckout" -> {
                handleSubmitAndCheckout(call, result)
            }
            "submit" -> {
                handleSubmit(call, result)
            }
            "checkout" -> {
                handleCheckout(result)
            }
            "checkoutWithToken" -> {
                handleCheckoutWithToken(call, result)
            }
            "query" -> {
                handleQuery(call, result)
            }
            "setDebugMode" -> {
                val debug = call.argument<Boolean>("debug") ?: false
                expressPayApi?.setDebugMode(debug)
                result.success(null)
            }
            "getOrderId" -> {
                result.success(expressPayApi?.orderId)
            }
            "getToken" -> {
                result.success(expressPayApi?.token)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleSubmitAndCheckout(call: MethodCall, result: Result) {
        if (expressPayApi == null) {
            result.error("NOT_INITIALIZED", "ExpressPay API not initialized", null)
            return
        }

        val params = createParamsMap(call)
        pendingResult = result
        currentRequestCode = REQUEST_CODE_SUBMIT_AND_CHECKOUT

        expressPayApi?.submitAndCheckout(params, activity!!, object : ExpressPayApi.ExpressPayPaymentCompletionListener {
            override fun onExpressPayPaymentFinished(paymentCompleted: Boolean, errorMessage: String?) {
                val resultMap = HashMap<String, Any?>()
                resultMap["success"] = paymentCompleted
                resultMap["message"] = errorMessage ?: "Payment completed successfully"

                activity?.runOnUiThread {
                    pendingResult?.success(resultMap)
                    pendingResult = null
                }
            }
        })
    }

    private fun handleSubmit(call: MethodCall, result: Result) {
        if (expressPayApi == null) {
            result.error("NOT_INITIALIZED", "ExpressPay API not initialized", null)
            return
        }

        val params = createParamsMap(call)

        expressPayApi?.submit(params, activity!!, object : ExpressPayApi.ExpressPaySubmitCompletionListener {
            override fun onExpressPaySubmitFinished(response: JSONObject?, errorMessage: String?) {
                val resultMap = HashMap<String, Any?>()

                if (response != null) {
                    resultMap["success"] = true
                    resultMap["data"] = response.toString()
                } else {
                    resultMap["success"] = false
                    resultMap["message"] = errorMessage ?: "Unknown error"
                }

                activity?.runOnUiThread {
                    result.success(resultMap)
                }
            }
        })
    }

    private fun handleCheckout(result: Result) {
        if (expressPayApi == null) {
            result.error("NOT_INITIALIZED", "ExpressPay API not initialized", null)
            return
        }

        pendingResult = result
        currentRequestCode = REQUEST_CODE_CHECKOUT

        try {
            expressPayApi?.checkout(activity!!)
        } catch (e: Exception) {
            pendingResult?.error("CHECKOUT_FAILED", e.message, null)
            pendingResult = null
        }
    }

    private fun handleCheckoutWithToken(call: MethodCall, result: Result) {
        if (expressPayApi == null) {
            result.error("NOT_INITIALIZED", "ExpressPay API not initialized", null)
            return
        }

        val clientToken = call.argument<String>("client_token")
        val redirectUrl = call.argument<String>("redirect_url")

        if (clientToken == null) {
            result.error("INVALID_ARGUMENTS", "Client token is required", null)
            return
        }

        pendingResult = result
        currentRequestCode = REQUEST_CODE_CHECKOUT_WITH_TOKEN

        try {
            expressPayApi?.checkout(activity!!, clientToken, redirectUrl)
        } catch (e: Exception) {
            pendingResult?.error("CHECKOUT_FAILED", e.message, null)
            pendingResult = null
        }
    }

    private fun handleQuery(call: MethodCall, result: Result) {
        if (expressPayApi == null) {
            result.error("NOT_INITIALIZED", "ExpressPay API not initialized", null)
            return
        }

        val token = call.argument<String>("token")

        if (token == null) {
            result.error("INVALID_ARGUMENTS", "Token is required", null)
            return
        }

        expressPayApi?.query(token, object : ExpressPayApi.ExpressPayQueryCompletionListener {
            override fun onExpressPayQueryFinished(paymentSuccessful: Boolean?, response: JSONObject?, message: String?) {
                val resultMap = HashMap<String, Any?>()
                resultMap["success"] = paymentSuccessful ?: false
                resultMap["data"] = response?.toString()
                resultMap["message"] = message

                activity?.runOnUiThread {
                    result.success(resultMap)
                }
            }
        })
    }

    private fun createParamsMap(call: MethodCall): HashMap<String, String> {
        val params = HashMap<String, String>()

        call.argument<String>("currency")?.let { params["currency"] = it }
        call.argument<String>("amount")?.let { params["amount"] = it }
        call.argument<String>("order_id")?.let { params["order_id"] = it }
        call.argument<String>("order_desc")?.let { params["order_desc"] = it }
        call.argument<String>("account_number")?.let { params["account_number"] = it }
        call.argument<String>("email")?.let { params["email"] = it }
        call.argument<String>("redirect_url")?.let { params["redirect_url"] = it }
        call.argument<String>("order_img_url")?.let { params["order_img_url"] = it }
        call.argument<String>("first_name")?.let { params["first_name"] = it }
        call.argument<String>("last_name")?.let { params["last_name"] = it }
        call.argument<String>("phone_number")?.let { params["phone_number"] = it }

        return params
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (expressPayApi != null && activity != null && pendingResult != null &&
            (requestCode == REQUEST_CODE_SUBMIT_AND_CHECKOUT ||
                    requestCode == REQUEST_CODE_CHECKOUT ||
                    requestCode == REQUEST_CODE_CHECKOUT_WITH_TOKEN)) {

            expressPayApi?.onActivityResult(activity!!, requestCode, resultCode, data)

            // We handle callback results in their respective listeners
            // This is just to make sure we catch any unhandled results
            if (requestCode != currentRequestCode) {
                val resultMap = HashMap<String, Any?>()
                resultMap["success"] = false
                resultMap["message"] = "Payment cancelled or failed"

                activity?.runOnUiThread {
                    pendingResult?.success(resultMap)
                    pendingResult = null
                }
            }

            return true
        }
        return false
    }
}