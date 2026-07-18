package com.spendtrail.app.spendtrail

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SpendTrailWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val totalAmount = widgetData.getString("monthly_total", "₹0.00")
                setTextViewText(R.id.widget_amount, totalAmount)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("spendtrail://quickadd")
                )
                setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
                
                val appIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_background_container, appIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
