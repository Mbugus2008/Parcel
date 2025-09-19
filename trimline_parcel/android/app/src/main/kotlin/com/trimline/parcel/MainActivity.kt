package com.trimline.parcel

import android.os.Build
import android.os.Bundle
import android.view.WindowManager.LayoutParams
import io.flutter.embedding.android.FlutterActivity
class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.setSoftInputMode(LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
    window.setWindowAnimations(0)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      val params = window.attributes
      if (params.windowAnimations != 0) {
        params.windowAnimations = 0
        window.attributes = params
      }
    }
  }
}
