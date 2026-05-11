package com.ahmet.assetmind.asset_mind

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WatchlistWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_watchlist)

            // Get count
            val favCount = widgetData.getInt("fav_count", 0)
            views.setTextViewText(R.id.tv_fav_title, "Takip Listesi")

            val itemIds = listOf(
                R.id.item_0, R.id.item_1, R.id.item_2, R.id.item_3, R.id.item_4,
                R.id.item_5, R.id.item_6, R.id.item_7, R.id.item_8, R.id.item_9
            )
            val symbolIds = listOf(
                R.id.symbol_0, R.id.symbol_1, R.id.symbol_2, R.id.symbol_3, R.id.symbol_4,
                R.id.symbol_5, R.id.symbol_6, R.id.symbol_7, R.id.symbol_8, R.id.symbol_9
            )
            val priceIds = listOf(
                R.id.price_0, R.id.price_1, R.id.price_2, R.id.price_3, R.id.price_4,
                R.id.price_5, R.id.price_6, R.id.price_7, R.id.price_8, R.id.price_9
            )
            val changeIds = listOf(
                R.id.change_0, R.id.change_1, R.id.change_2, R.id.change_3, R.id.change_4,
                R.id.change_5, R.id.change_6, R.id.change_7, R.id.change_8, R.id.change_9
            )

            for (i in 0 until 10) {
                if (i < favCount) {
                    views.setViewVisibility(itemIds[i], View.VISIBLE)
                    
                    val symbolKey = "fav_" + i + "_symbol"
                    val priceKey = "fav_" + i + "_price"
                    val changeKey = "fav_" + i + "_change"
                    val isPosKey = "fav_" + i + "_is_positive"

                    val symbol = widgetData.getString(symbolKey, "") ?: ""
                    val price = widgetData.getString(priceKey, "0.00") ?: "0.00"
                    val change = widgetData.getString(changeKey, "%0.00") ?: "%0.00"
                    val isPos = widgetData.getBoolean(isPosKey, true)

                    views.setTextViewText(symbolIds[i], symbol)
                    views.setTextViewText(priceIds[i], "₺" + price)
                    views.setTextViewText(changeIds[i], (if (isPos) "+" else "") + change)
                    
                    // DYNAMIC BACKGROUND SETTING
                    val bgRes = if (isPos) R.drawable.badge_green else R.drawable.badge_red
                    views.setInt(changeIds[i], "setBackgroundResource", bgRes)
                    views.setTextColor(changeIds[i], 0xFFFFFFFF.toInt())
                } else {
                    views.setViewVisibility(itemIds[i], View.GONE)
                }
            }

            // Deep Link
            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("assetmind://favorites")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 1, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
