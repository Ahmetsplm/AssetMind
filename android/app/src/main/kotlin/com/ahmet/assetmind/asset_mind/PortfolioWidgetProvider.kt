package com.ahmet.assetmind.asset_mind

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PortfolioWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_portfolio)

            // Get Data
            val totalValue = widgetData.getString("total_value", "₺0,00")
            val netProfit = widgetData.getString("net_profit", "₺0,00")
            val profitPercentage = widgetData.getString("profit_percentage", "%0.00")
            val lastUpdate = widgetData.getString("last_update", "--:--")
            val assetCount = widgetData.getInt("asset_count", 0)
            val isPositive = widgetData.getBoolean("is_positive", true)

            // Set Views
            views.setTextViewText(R.id.tv_total_value, totalValue)
            views.setTextViewText(R.id.tv_net_profit, netProfit)
            views.setTextViewText(R.id.tv_profit_percentage, profitPercentage)
            views.setTextViewText(R.id.tv_last_update, "Son Güncelleme: $lastUpdate")
            views.setTextViewText(R.id.tv_asset_count, assetCount.toString())
            views.setTextViewText(R.id.tv_profit_status, if (isPositive) "Kâr" else "Zarar")

            // Deep Link
            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("assetmind://portfolio")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Set click on root to cover whole widget
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
