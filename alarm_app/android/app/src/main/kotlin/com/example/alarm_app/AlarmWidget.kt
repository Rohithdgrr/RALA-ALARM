package com.example.alarm_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

class AlarmWidget : AppWidgetProvider() {
    private val TAG = "AlarmWidget"

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")
        super.onReceive(context, intent)
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = android.content.ComponentName(context, AlarmWidget::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(component)
            Log.d(TAG, "Updating ${widgetIds.size} widgets")
            for (widgetId in widgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onReceive: ${e.message}", e)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate: ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "onEnabled: Widget provider enabled")
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "onDisabled: Widget provider disabled")
        super.onDisabled(context)
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                Log.d("AlarmWidget", "Updating widget $appWidgetId")
                
                // Create RemoteViews
                val views = RemoteViews(context.packageName, R.layout.alarm_widget)
                
                // Get data from widget storage with try-catch
                val widgetData = try {
                    HomeWidgetPlugin.getData(context)
                } catch (e: Exception) {
                    Log.e("AlarmWidget", "Error getting widget data: ${e.message}")
                    null
                }
                
                // Get data with defaults
                val alarmCount = try {
                    widgetData?.getString("alarm_count", "0") ?: "0"
                } catch (e: Exception) {
                    "0"
                }
                
                val nextAlarmTime = try {
                    widgetData?.getString("next_alarm_time", "No alarms") ?: "No alarms"
                } catch (e: Exception) {
                    "No alarms"
                }
                
                val nextAlarmLabel = try {
                    widgetData?.getString("next_alarm_label", "Tap to set") ?: "Tap to set"
                } catch (e: Exception) {
                    "Tap to set"
                }
                
                Log.d("AlarmWidget", "Data: count=$alarmCount, time=$nextAlarmTime, label=$nextAlarmLabel")
                
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
                    appWidgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                
                // Update the widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d("AlarmWidget", "Widget $appWidgetId updated successfully")
                
            } catch (e: Exception) {
                Log.e("AlarmWidget", "Error updating widget $appWidgetId: ${e.message}", e)
            }
        }
    }
}
