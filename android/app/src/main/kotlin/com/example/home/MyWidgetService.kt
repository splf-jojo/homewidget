package com.example.home

import android.content.Intent
import android.widget.RemoteViewsService

class MyWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val scheduleData = intent.getStringExtra("SCHEDULE_DATA") ?: "08:00-08:45 Java;09:45-10:30 Социология;11:40-12:25 Flutter"
        return MyRemoteViewsFactory(applicationContext, scheduleData)
    }
}
