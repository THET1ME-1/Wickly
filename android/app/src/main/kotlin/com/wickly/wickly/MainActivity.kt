package com.wickly.wickly

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Именно FlutterFragmentActivity, а не FlutterActivity.
 *
 * Отпечаток и лицо (`local_auth`) показываются системным диалогом
 * BiometricPrompt, а он умеет открываться только над FragmentActivity.
 * С обычной FlutterActivity вызов падает с `no_fragment_activity`, и замок
 * молча оставался только с кодом.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE: содержимое дневника не попадает в снимок «Недавние
        // приложения» и не скриншотится. Иначе открытая запись всплывала бы
        // в переключателе задач при уходе в фон — в обход замка, который на
        // тот момент ещё не наложен.
        //
        // В отладочной сборке флаг не ставится: с ним `adb screencap` отдаёт
        // чёрный кадр, и посмотреть на экран во время починки нечем.
        val debuggable =
            applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!debuggable) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
