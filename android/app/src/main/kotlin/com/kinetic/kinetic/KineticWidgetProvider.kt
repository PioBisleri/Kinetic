package com.kinetic.kinetic

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: this week's volume, the streak, and the next-up
 * routine.
 *
 * Values are written by the Dart side through `home_widget`
 * (`updateHomeScreenWidget`) into the `HomeWidgetPreferences` file; this
 * provider only renders them and wires the tap — a launch intent carrying
 * `kinetic://widget/workout` that starts (or resumes) a session and opens
 * the logger.
 */
class KineticWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    val views = RemoteViews(context.packageName, R.layout.kinetic_widget)

    views.setTextViewText(
      R.id.widget_volume,
      widgetData.getString(KEY_VOLUME, "0 kg") ?: "0 kg",
    )
    views.setTextViewText(
      R.id.widget_streak,
      widgetData.getString(KEY_STREAK, "0 weeks") ?: "0 weeks",
    )
    views.setTextViewText(
      R.id.widget_routine,
      widgetData.getString(KEY_ROUTINE, "No routines yet") ?: "No routines yet",
    )

    // Tap → bring the app up straight into a (resumable) session. The
    // payload is read on the Dart side (HomeWidget.widgetClicked /
    // initiallyLaunchedFromHomeWidget) and handled like the quick action.
    val tap = HomeWidgetLaunchIntent.getActivity(
      context,
      MainActivity::class.java,
      Uri.parse(PAYLOAD),
    )
    views.setOnClickPendingIntent(R.id.widget_root, tap)

    for (id in appWidgetIds) {
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  companion object {
    private const val KEY_VOLUME = "volume"
    private const val KEY_STREAK = "streak"
    private const val KEY_ROUTINE = "routine"
    private const val PAYLOAD = "kinetic://widget/workout"
  }
}
