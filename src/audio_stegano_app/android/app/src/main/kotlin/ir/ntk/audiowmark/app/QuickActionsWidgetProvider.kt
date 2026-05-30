package ir.ntk.audiowmark.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
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
        try {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)
            bindClickTargets(context, views, appWidgetId)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (error: Exception) {
            Log.e(TAG, "Widget inflate/update failed for id=$appWidgetId", error)
            val fallback = RemoteViews(context.packageName, R.layout.widget_quick_actions_fallback)
            bindClickTargets(context, fallback, appWidgetId)
            appWidgetManager.updateAppWidget(appWidgetId, fallback)
        }
    }

    private fun bindClickTargets(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int,
    ) {
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
    }

    private fun pendingAction(
        context: Context,
        action: String?,
        requestCode: Int,
    ): PendingIntent {
        val intent =
            Intent(context, WidgetCaptureActivity::class.java).apply {
                this.action = WIDGET_ACTION
                putExtra(
                    EXTRA_WIDGET_ACTION,
                    action ?: ACTION_RECORD,
                )
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
        private const val TAG = "QuickActionsWidget"
        const val WIDGET_ACTION = "ir.ntk.audiowmark.app.WIDGET_ACTION"
        const val EXTRA_WIDGET_ACTION = "widget_action"
        const val ACTION_RECORD = "record"
        const val ACTION_EMBED = "embed"
    }
}
