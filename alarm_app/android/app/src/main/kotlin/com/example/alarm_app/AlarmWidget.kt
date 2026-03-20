package com.example.alarm_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class AlarmWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.alarm_widget)
            
            // Get data from widget storage
            val alarmCount = widgetData.getString("alarm_count", "0") ?: "0"
            val nextAlarmTime = widgetData.getString("next_alarm_time", "No alarms") ?: "No alarms"
            val nextAlarmLabel = widgetData.getString("next_alarm_label", "Tap to set") ?: "Tap to set"
            
            // Update widget views
            views.setTextViewText(R.id.widget_alarm_count, alarmCount)
            views.setTextViewText(R.id.widget_next_time, nextAlarmTime)
            views.setTextViewText(R.id.widget_next_label, nextAlarmLabel)
            
            // Setup pending intent to open app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
