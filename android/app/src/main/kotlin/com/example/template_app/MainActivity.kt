package com.example.template_app

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.LocationSettingsStatusCodes
import com.google.android.gms.location.Priority
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "template_app/location_service"
        const val REQUEST_CHECK_SETTINGS = 0xC0FE
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestService" -> requestLocationService(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestLocationService(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("ALREADY_PENDING", "A request is already in progress", null)
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10_000L)
            .build()

        val settingsRequest = LocationSettingsRequest.Builder()
            .addLocationRequest(locationRequest)
            .setAlwaysShow(true)
            .build()

        val client = LocationServices.getSettingsClient(this)
        client.checkLocationSettings(settingsRequest)
            .addOnSuccessListener {
                result.success(true)
            }
            .addOnFailureListener { exception ->
                if (exception is ResolvableApiException &&
                    exception.statusCode == LocationSettingsStatusCodes.RESOLUTION_REQUIRED
                ) {
                    try {
                        pendingResult = result
                        exception.startResolutionForResult(this, REQUEST_CHECK_SETTINGS)
                    } catch (_: IntentSender.SendIntentException) {
                        pendingResult = null
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CHECK_SETTINGS) {
            pendingResult?.success(resultCode == Activity.RESULT_OK)
            pendingResult = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
