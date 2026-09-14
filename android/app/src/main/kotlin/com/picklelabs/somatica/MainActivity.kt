package com.picklelabs.somatica

import io.flutter.embedding.android.FlutterFragmentActivity

// The `health` plugin casts the host Activity to androidx.activity.ComponentActivity
// (needed for Health Connect's registerForActivityResult permission flow) - plain
// FlutterActivity doesn't extend that, but FlutterFragmentActivity does.
class MainActivity: FlutterFragmentActivity() {
}
