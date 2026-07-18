package com.wickly.wickly

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Именно FlutterFragmentActivity, а не FlutterActivity.
 *
 * Отпечаток и лицо (`local_auth`) показываются системным диалогом
 * BiometricPrompt, а он умеет открываться только над FragmentActivity.
 * С обычной FlutterActivity вызов падает с `no_fragment_activity`, и замок
 * молча оставался только с кодом.
 */
class MainActivity : FlutterFragmentActivity()
