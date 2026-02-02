package com.example.juan_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import org.json.JSONObject

/**
 * App Widget para Juan Tracker - Muestra el entrenamiento del día
 */
class WorkoutWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_START_WORKOUT = "com.juantracker.START_WORKOUT"
        const val PREFS_NAME = "HomeWidgetData"
        
        /**
         * Fuerza la actualización de todos los widgets
         */
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, WorkoutWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
        
        /**
         * Actualiza un widget específico
         */
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.workout_widget)
            
            // Leer datos guardados desde Flutter
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("widget_data", null)
            
            if (jsonStr != null) {
                try {
                    val data = JSONObject(jsonStr)
                    updateWidgetWithData(context, views, data)
                } catch (e: Exception) {
                    showEmptyState(views)
                }
            } else {
                showEmptyState(views)
            }
            
            // Configurar click en el botón de acción
            val intent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_START_WORKOUT
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            views.setOnClickPendingIntent(R.id.widget_action_button, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun updateWidgetWithData(
            context: Context,
            views: RemoteViews,
            data: JSONObject
        ) {
            val hasWorkout = data.optBoolean("hasWorkout", false)
            
            if (hasWorkout) {
                // Mostrar datos del entrenamiento
                views.setTextViewText(R.id.widget_title, data.optString("title", "Entreno"))
                views.setTextViewText(R.id.widget_subtitle, data.optString("subtitle", ""))
                views.setTextViewText(R.id.widget_action_button, data.optString("primaryAction", "ENTRENAR"))
                
                // Mostrar ejercicios
                views.setViewVisibility(R.id.widget_exercises_container, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty_state, android.view.View.GONE)
                
                val exercises = data.optJSONArray("exercises")
                if (exercises != null) {
                    // Ejercicio 1
                    if (exercises.length() > 0) {
                        views.setTextViewText(R.id.widget_exercise_1, "• ${exercises.getString(0)}")
                        views.setViewVisibility(R.id.widget_exercise_1, android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_exercise_1, android.view.View.GONE)
                    }
                    
                    // Ejercicio 2
                    if (exercises.length() > 1) {
                        views.setTextViewText(R.id.widget_exercise_2, "• ${exercises.getString(1)}")
                        views.setViewVisibility(R.id.widget_exercise_2, android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_exercise_2, android.view.View.GONE)
                    }
                    
                    // Ejercicio 3 (o "+X más")
                    val exerciseCount = data.optInt("exerciseCount", exercises.length())
                    if (exerciseCount > 2) {
                        val remaining = exerciseCount - 2
                        views.setTextViewText(R.id.widget_exercise_3, "• +$remaining más...")
                        views.setViewVisibility(R.id.widget_exercise_3, android.view.View.VISIBLE)
                    } else if (exercises.length() > 2) {
                        views.setTextViewText(R.id.widget_exercise_3, "• ${exercises.getString(2)}")
                        views.setViewVisibility(R.id.widget_exercise_3, android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_exercise_3, android.view.View.GONE)
                    }
                }
            } else {
                showEmptyState(views)
            }
        }
        
        private fun showEmptyState(views: RemoteViews) {
            views.setTextViewText(R.id.widget_title, "Juan Tracker")
            views.setTextViewText(R.id.widget_subtitle, "Sin entreno programado")
            views.setTextViewText(R.id.widget_action_button, "INICIAR")
            views.setViewVisibility(R.id.widget_exercises_container, android.view.View.GONE)
            views.setViewVisibility(R.id.widget_empty_state, android.view.View.VISIBLE)
        }
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onEnabled(context: Context) {
        // Primer widget añadido
    }
    
    override fun onDisabled(context: Context) {
        // Último widget eliminado
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        // Manejar actualización forzada desde Flutter
        if (intent.action == "com.juantracker.UPDATE_WIDGET") {
            updateAllWidgets(context)
        }
    }
}
