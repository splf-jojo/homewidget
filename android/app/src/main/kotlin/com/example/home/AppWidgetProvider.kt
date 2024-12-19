package com.example.home

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.*

class AppWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val widgetText = widgetData.getString("widgetText", "08:00-08:45 Java 101;09:45-10:30 Социология 202;11:40-12:25 Flutter 303")
        Log.d("AppWidgetProviderAll", "All prefs: ${widgetData.all}")
        Log.d("AppWidgetProviderAll", "widgetText: $widgetText")

        val lessons = parseLessons(widgetText ?: "")
        val now = Date()
        val currentLesson = findCurrentLesson(lessons, now)
        val nextLesson = findNextLesson(lessons, now)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.example_widget_layout)

            val intent = Intent(context, MyWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra("SCHEDULE_DATA", widgetText)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }

            views.setRemoteAdapter(R.id.lessons_list, intent)

            val timerText = if (currentLesson != null) {
                // Сейчас идет урок, покажем сколько осталось до конца
                val untilEnd = timeUntilLessonEnd(currentLesson, now)
                "$untilEnd until current lesson ends (${currentLesson.subject})"
            } else {
                // Текущего урока нет, смотрим следующий урок
                if (nextLesson != null) {
                    val untilNext = timeUntilNextLesson(nextLesson, now)
                    "$untilNext until next lesson (${nextLesson.subject})"
                } else {
                    "No upcoming lessons"
                }
            }

            views.setTextViewText(R.id.next_lesson_timer, timerText)

            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.lessons_list)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    data class Lesson(val startTime: String, val endTime: String, val subject: String, val room: String)

    private fun parseLessons(data: String): List<Lesson> {
        val result = mutableListOf<Lesson>()
        val blocks = data.split(";").map { it.trim() }.filter { it.isNotEmpty() }
        for (block in blocks) {
            val parts = block.split(" ")
            if (parts.size >= 3) {
                val timeRange = parts[0].split("-")
                if (timeRange.size == 2) {
                    val start = timeRange[0]
                    val end = timeRange[1]
                    val room = parts.last()
                    val subject = parts.subList(1, parts.size - 1).joinToString(" ")
                    result.add(Lesson(start, end, subject, room))
                }
            }
        }
        return result
    }

    private fun findCurrentLesson(lessons: List<Lesson>, now: Date): Lesson? {
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())

        for (lesson in lessons) {
            val start = formatter.parse(lesson.startTime)
            val end = formatter.parse(lesson.endTime)
            val calNow = Calendar.getInstance()
            calNow.time = now

            val calStart = Calendar.getInstance()
            calStart.time = start
            calStart.set(Calendar.YEAR, calNow.get(Calendar.YEAR))
            calStart.set(Calendar.MONTH, calNow.get(Calendar.MONTH))
            calStart.set(Calendar.DAY_OF_MONTH, calNow.get(Calendar.DAY_OF_MONTH))

            val calEnd = Calendar.getInstance()
            calEnd.time = end
            calEnd.set(Calendar.YEAR, calNow.get(Calendar.YEAR))
            calEnd.set(Calendar.MONTH, calNow.get(Calendar.MONTH))
            calEnd.set(Calendar.DAY_OF_MONTH, calNow.get(Calendar.DAY_OF_MONTH))

            if (calNow.time.after(calStart.time) && calNow.time.before(calEnd.time)) {
                return lesson
            }
        }

        return null
    }

    private fun findNextLesson(lessons: List<Lesson>, now: Date): Lesson? {
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
        val calNow = Calendar.getInstance()
        calNow.time = now

        val upcoming = lessons.mapNotNull { lesson ->
            val start = formatter.parse(lesson.startTime)
            val startCal = Calendar.getInstance()
            startCal.time = start
            startCal.set(Calendar.YEAR, calNow.get(Calendar.YEAR))
            startCal.set(Calendar.MONTH, calNow.get(Calendar.MONTH))
            startCal.set(Calendar.DAY_OF_MONTH, calNow.get(Calendar.DAY_OF_MONTH))
            if (startCal.time.after(now)) {
                lesson to startCal.time
            } else {
                null
            }
        }.minByOrNull { it.second.time }

        return upcoming?.first
    }

    private fun timeUntilNextLesson(lesson: Lesson, now: Date): String {
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
        val start = formatter.parse(lesson.startTime)
        val calNow = Calendar.getInstance()
        calNow.time = now
        val calStart = Calendar.getInstance()
        calStart.time = start
        calStart.set(Calendar.YEAR, calNow.get(Calendar.YEAR))
        calStart.set(Calendar.MONTH, calNow.get(Calendar.MONTH))
        calStart.set(Calendar.DAY_OF_MONTH, calNow.get(Calendar.DAY_OF_MONTH))

        val diff = calStart.timeInMillis - calNow.timeInMillis
        if (diff <= 0) {
            return "Lesson already started"
        }
        val minutes = diff / 60000
        val hours = minutes / 60
        val minPart = minutes % 60
        return if (hours > 0) {
            "${hours}h ${minPart}min"
        } else {
            "${minPart}min"
        }
    }

    private fun timeUntilLessonEnd(lesson: Lesson, now: Date): String {
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
        val end = formatter.parse(lesson.endTime)
        val calNow = Calendar.getInstance()
        calNow.time = now
        val calEnd = Calendar.getInstance()
        calEnd.time = end
        calEnd.set(Calendar.YEAR, calNow.get(Calendar.YEAR))
        calEnd.set(Calendar.MONTH, calNow.get(Calendar.MONTH))
        calEnd.set(Calendar.DAY_OF_MONTH, calNow.get(Calendar.DAY_OF_MONTH))

        val diff = calEnd.timeInMillis - calNow.timeInMillis
        if (diff <= 0) {
            return "Lesson ended"
        }
        val minutes = diff / 60000
        val hours = minutes / 60
        val minPart = minutes % 60
        return if (hours > 0) {
            "${hours}h ${minPart}min"
        } else {
            "${minPart}min"
        }
    }
}
