package ca.karavi.audiowmark.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QuickActionsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)

        views.setOnClickPendingIntent(
            R.id.widget_action_record,
            pendingAction(context, ACTION_RECORD, appWidgetId * 10 + 1),
        )
        views.setOnClickPendingIntent(
            R.id.widget_action_embed,
            pendingAction(context, ACTION_EMBED, appWidgetId * 10 + 2),
        )
        views.setOnClickPendingIntent(
            R.id.widget_header,
            pendingAction(context, null, appWidgetId * 10 + 3),
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun pendingAction(
        context: Context,
        action: String?,
        requestCode: Int,
    ): PendingIntent {
        val intent =
            Intent(context, MainActivity::class.java).apply {
                this.action = WIDGET_ACTION
                if (action != null) {
                    putExtra(EXTRA_WIDGET_ACTION, action)
                }
                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val WIDGET_ACTION = "ca.karavi.audiowmark.app.WIDGET_ACTION"
        const val EXTRA_WIDGET_ACTION = "widget_action"
        const val ACTION_RECORD = "record"
        const val ACTION_EMBED = "embed"
    }
}
