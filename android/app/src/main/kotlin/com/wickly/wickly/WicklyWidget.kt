package com.wickly.wickly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Виджет быстрой записи.
 *
 * Данные (серия, воспоминание) кладёт само приложение через home_widget —
 * виджет их только читает. Своей логики у него нет намеренно: он не должен
 * уметь открывать зашифрованную базу, иначе шифрование потеряло бы смысл.
 */
class WicklyWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick)

            // Серия и воспоминание приходят уже собранными строками: собирать
            // их здесь означало бы дублировать логику приложения.
            views.setTextViewText(
                R.id.widget_streak,
                data.getString("streak", "") ?: ""
            )

            val memory = data.getString("memory", "") ?: ""
            views.setTextViewText(R.id.widget_memory, memory)
            views.setViewVisibility(
                R.id.widget_memory,
                if (memory.isEmpty()) android.view.View.GONE else android.view.View.VISIBLE
            )

            // Кнопка открывает редактор.
            views.setOnClickPendingIntent(
                R.id.widget_write,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, android.net.Uri.parse("wickly://write"))
            )

            // Кружок настроения открывает редактор с уже отмеченным настроением.
            val moods = listOf(R.id.mood_1, R.id.mood_2, R.id.mood_3, R.id.mood_4, R.id.mood_5)
            moods.forEachIndexed { index, viewId ->
                views.setOnClickPendingIntent(
                    viewId,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        android.net.Uri.parse("wickly://write?mood=${index + 1}")
                    )
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
