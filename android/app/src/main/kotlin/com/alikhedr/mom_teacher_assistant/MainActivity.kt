package com.alikhedr.mom_teacher_assistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import us.zoom.sdk.ZoomSDK
import us.zoom.sdk.ZoomSDKInitParams
import us.zoom.sdk.ZoomSDKInitializeListener
import android.util.Log

class MainActivity : FlutterActivity() {

    companion object {
        private const val ZOOM_CHANNEL =
            "com.alikhedr.mom_teacher_assistant/zoom"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ZOOM_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "isAvailable" -> {
                    result.success(true)
                }

                "isInitialized" -> {
                    result.success(
                        ZoomSDK
                            .getInstance()
                            .isInitialized
                    )
                }

"initialize" -> {
    val token =
        call.arguments as String

    initializeZoom(
        token,
        result
    )
}
                else -> {
                    result.notImplemented()
                }
            }
        }
    }


private fun initializeZoom(
    token: String,
    result: MethodChannel.Result
) {

        Log.d(
    "ZoomTest",
    "initializeZoom started"
)

        try {

            val zoomSDK =
                ZoomSDK.getInstance()


val params =
    ZoomSDKInitParams().apply {
        domain = "zoom.us"
        enableLog = true
        jwtToken = token
    }
            zoomSDK.initialize(
                this,
                object : ZoomSDKInitializeListener {

                    override fun onZoomSDKInitializeResult(
                        
                        errorCode: Int,
                        internalErrorCode: Int
                    ) {
                        Log.d(
    "ZoomTest",
    "Zoom callback error=$errorCode internal=$internalErrorCode"
)

                        val response =
                            HashMap<String, Any>()

                        response["success"] =
                            errorCode == 0

                        response["errorCode"] =
                            errorCode

                        response["internalErrorCode"] =
                            internalErrorCode

                        result.success(response)
                    }


                    override fun onZoomAuthIdentityExpired() {
                    }
                },
                params
            )

        } catch (e: Exception) {

            Log.e(
    "ZoomTest",
    "Exception: ${e.message}"
)

    val response =
        HashMap<String, Any>()

    response["success"] =
        false

    response["exception"] =
        e.toString()

    result.success(response)
}
    }
}