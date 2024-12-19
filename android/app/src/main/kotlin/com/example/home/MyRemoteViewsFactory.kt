package com.example.home

import android.content.Context
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.util.Log

class MyRemoteViewsFactory(
    private val context: Context,
    private val scheduleData: String
) : RemoteViewsService.RemoteViewsFactory {

//    private var lessonsList: List<Pair<String, String>> = listOf()
    private var lessonsList: List<Triple<String, String, String>> = listOf()

    override fun onCreate() { }

    override fun onDataSetChanged() {
        Log.d("MyRemoteViewsFactory", "Received scheduleData: $scheduleData")
        val lessons = scheduleData.split(";").map { it.trim() }.filter { it.isNotEmpty() }

        val tempList = mutableListOf<Triple<String, String, String>>()
        for (lesson in lessons) {
            val parts = lesson.split(" ")
            if (parts.size >= 2) {
                val time = parts[0]
                val room = parts.last()
                val subject = parts.subList(1, parts.size - 1).joinToString(" ")
                tempList.add(Triple(time, subject, room))
            }
        }

        lessonsList = tempList
        Log.d("MyRemoteViewsFactory", "Parsed lessons count: ${lessonsList.size}")
    }

    override fun onDestroy() {
        lessonsList = listOf()
    }

    override fun getCount(): Int {
        Log.d("MyRemoteViewsFactory", "getCount: ${lessonsList.size}")
        return lessonsList.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        Log.d("MyRemoteViewsFactory", "getViewAt: $position")
        val rv = RemoteViews(context.packageName, R.layout.lesson_item)
        val (time, subject, room) = lessonsList[position]

        rv.setTextViewText(R.id.lesson_time, time)
        rv.setTextViewText(R.id.lesson_subject, subject)
        rv.setTextViewText(R.id.lesson_room, room)

        return rv
    }

    override fun getLoadingView(): RemoteViews {
        Log.d("MyRemoteViewsFactory", "getLoadingView called")
        return RemoteViews(context.packageName, R.layout.loading_view)
    }
//    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
//        val scheduleData = intent.getStringExtra("SCHEDULE_DATA") ?: ""
//        return MyRemoteViewsFactory(applicationContext, scheduleData)
//    }

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
