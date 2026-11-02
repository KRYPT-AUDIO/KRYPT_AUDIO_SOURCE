package com.synapselabs.kryptaudio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.widget.RemoteViews

class KryptWidgetProvider : AppWidgetProvider() {
  override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
    ids.forEach { id -> manager.updateAppWidget(id, buildViews(context)) }
  }

  private fun buildViews(context: Context): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.krypt_widget)
    views.setOnClickPendingIntent(R.id.krypt_widget_title, launchIntent(context))
    views.setOnClickPendingIntent(R.id.krypt_widget_previous, mediaButton(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
    views.setOnClickPendingIntent(R.id.krypt_widget_play, mediaButton(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
    views.setOnClickPendingIntent(R.id.krypt_widget_next, mediaButton(context, KeyEvent.KEYCODE_MEDIA_NEXT))
    return views
  }

  private fun launchIntent(context: Context): PendingIntent {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
      ?: Intent(context, MainActivity::class.java)
    return PendingIntent.getActivity(
      context,
      400,
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }

  private fun mediaButton(context: Context, keyCode: Int): PendingIntent {
    val event = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
    val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
      component = ComponentName(
        context,
        "com.ryanheise.audioservice.MediaButtonReceiver",
      )
      putExtra(Intent.EXTRA_KEY_EVENT, event)
    }
    return PendingIntent.getBroadcast(
      context,
      keyCode,
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }
}
