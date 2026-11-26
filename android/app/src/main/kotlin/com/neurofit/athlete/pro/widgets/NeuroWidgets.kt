package com.neurofit.athlete.pro.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.SweepGradient
import android.graphics.Matrix
import android.graphics.LinearGradient
import android.graphics.Shader
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.neurofit.athlete.pro.MainActivity
import com.neurofit.athlete.pro.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// The five NeuroFit home screen widgets. The Flutter app writes the numbers
// with home_widget (see lib/services/widget_sync.dart); each provider reads
// them from the shared preferences and draws its RemoteViews.

internal fun SharedPreferences.num(key: String, def: Int): Int = (all[key] as? Number)?.toInt() ?: def

internal fun SharedPreferences.str(key: String, def: String): String = (all[key] as? String) ?: def

internal fun fmt(n: Int): String = NumberFormat.getIntegerInstance(Locale.US).format(n)

internal fun open(context: Context, route: String): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("neurofit://$route"))

/** Progress ring drawn into a bitmap (RemoteViews has no arc view): a soft
 *  track, a gradient arc from [color2] to [color] with a glow, and a bright
 *  dot at its tip. */
internal fun ring(
    context: Context, dp: Int, progress: Float, color: Int, track: Int,
    strokeDp: Float = 9f, color2: Int = color,
): Bitmap {
  val d = context.resources.displayMetrics.density
  val px = (dp * d).toInt().coerceAtLeast(8)
  val bmp = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
  val c = Canvas(bmp)
  val s = strokeDp * d
  val pad = s / 2 + 3 * d
  val r = RectF(pad, pad, px - pad, px - pad)
  val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    strokeWidth = s
    strokeCap = Paint.Cap.ROUND
    this.color = track
  }
  c.drawArc(r, 0f, 360f, false, p)
  val f = progress.coerceIn(0f, 1f)
  val sweep = 360f * f
  if (sweep > 0.5f) {
    val cx = px / 2f
    val g = SweepGradient(cx, cx, intArrayOf(color2, color, color), floatArrayOf(0f, f.coerceAtLeast(0.05f), 1f))
    g.setLocalMatrix(Matrix().apply { setRotate(-90f, cx, cx) })
    p.shader = g
    p.color = color
    p.setShadowLayer(3 * d, 0f, 0f, (color and 0x00FFFFFF) or 0x66000000)
    c.drawArc(r, -90f, sweep, false, p)
    // Tip dot.
    val a = Math.toRadians((sweep - 90f).toDouble())
    val rad = r.width() / 2
    val dot = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = Color.WHITE; setShadowLayer(2 * d, 0f, 0f, 0x55000000) }
    c.drawCircle(cx + (rad * Math.cos(a)).toFloat(), cx + (rad * Math.sin(a)).toFloat(), s * 0.28f, dot)
  }
  return bmp
}

/** Rounded horizontal bar with a gradient fill. */
internal fun bar(context: Context, wDp: Int, hDp: Int, progress: Float, color: Int, track: Int, color2: Int = color): Bitmap {
  val d = context.resources.displayMetrics.density
  val w = (wDp * d).toInt()
  val h = (hDp * d).toInt()
  val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
  val c = Canvas(bmp)
  val p = Paint(Paint.ANTI_ALIAS_FLAG)
  p.color = track
  c.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), h / 2f, h / 2f, p)
  val fw = (w * progress.coerceIn(0f, 1f)).coerceAtLeast(h.toFloat())
  p.shader = LinearGradient(0f, 0f, fw, 0f, color2, color, Shader.TileMode.CLAMP)
  c.drawRoundRect(RectF(0f, 0f, fw, h.toFloat()), h / 2f, h / 2f, p)
  return bmp
}

/** Fills the ViewFlipper lines flip_1..flip_[count], cycling [lines]. */
internal fun flips(v: RemoteViews, lines: List<String>, count: Int = 3) {
  if (lines.isEmpty()) return
  val ids = intArrayOf(R.id.flip_1, R.id.flip_2, R.id.flip_3, R.id.flip_4, R.id.flip_5)
  for (i in 0 until count.coerceAtMost(ids.size)) v.setTextViewText(ids[i], lines[i % lines.size])
}

internal fun pct(a: Int, b: Int): Int = (a * 100L / b.coerceAtLeast(1)).toInt().coerceIn(0, 999)

/** Asks every NeuroFit widget of [cls] to redraw from the saved data. */
internal fun refresh(context: Context, cls: Class<*>) {
  val m = AppWidgetManager.getInstance(context)
  val ids = m.getAppWidgetIds(ComponentName(context, cls))
  if (ids.isEmpty()) return
  val i = Intent(context, cls).apply {
    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
  }
  context.sendBroadcast(i)
}

// ---------------------------------------------------------------- 1. Steps

class StepsWidget : HomeWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    val steps = widgetData.num("steps", 8542)
    val goal = widgetData.num("step_goal", 10000).coerceAtLeast(1)
    val km = steps * 0.00078
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_steps)
      v.setImageViewBitmap(R.id.ring, ring(context, 118, steps / goal.toFloat(), Color.WHITE, 0x33FFFFFF, 10f, 0xB3FFFFFF.toInt()))
      v.setTextViewText(R.id.steps, fmt(steps))
      v.setTextViewText(R.id.goal, "of ${fmt(goal)}")
      v.setTextViewText(R.id.pct, "${pct(steps, goal)}%")
      val left = goal - steps
      flips(v, listOf(
          String.format(Locale.US, "👟 %.1f km walked", km),
          "🔥 ${fmt((steps * 0.04).toInt())} kcal burned",
          if (left > 0) "💪 ${fmt(left)} steps to go" else "🏆 Goal smashed!",
      ))
      v.setOnClickPendingIntent(R.id.root, open(context, "steps"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

// ---------------------------------------------------------------- 2. Today stats

class StatsWidget : HomeWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    val steps = widgetData.num("steps", 8542)
    val stepGoal = widgetData.num("step_goal", 10000).coerceAtLeast(1)
    val eaten = widgetData.num("kcal_eaten", 1420)
    val budget = widgetData.num("kcal_budget", 1800).coerceAtLeast(1)
    val water = widgetData.num("water", 1250)
    val waterGoal = widgetData.num("water_goal", 2500).coerceAtLeast(1)
    val sleep = widgetData.str("sleep", "7h 20m")
    val track = 0x1A111827
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_stats)
      v.setTextViewText(R.id.date, SimpleDateFormat("EEEE, d MMM", Locale.US).format(Date()))
      v.setImageViewBitmap(R.id.ring1, ring(context, 54, steps / stepGoal.toFloat(), 0xFF7C3AED.toInt(), track, 6f, 0xFFC084FC.toInt()))
      v.setImageViewBitmap(R.id.ring2, ring(context, 54, eaten / budget.toFloat(), 0xFFF97316.toInt(), track, 6f, 0xFFFBBF24.toInt()))
      v.setImageViewBitmap(R.id.ring3, ring(context, 54, water / waterGoal.toFloat(), 0xFF0EA5E9.toInt(), track, 6f, 0xFF67E8F9.toInt()))
      v.setImageViewBitmap(R.id.ring4, ring(context, 54, 0.92f, 0xFF6366F1.toInt(), track, 6f, 0xFFA5B4FC.toInt()))
      val kLeft = budget - eaten
      flips(v, listOf(
          "You're ${pct(steps, stepGoal)}% to your step goal",
          if (kLeft >= 0) "${fmt(kLeft)} kcal left in today's budget" else "${fmt(-kLeft)} kcal over budget",
          "Water ${pct(water, waterGoal)}% · sleep $sleep",
      ))
      v.setTextViewText(R.id.val1, fmt(steps))
      v.setTextViewText(R.id.val2, fmt(eaten))
      v.setTextViewText(R.id.val3, String.format(Locale.US, "%.1f L", water / 1000.0))
      v.setTextViewText(R.id.val4, sleep)
      v.setOnClickPendingIntent(R.id.root, open(context, "stats"))
      v.setOnClickPendingIntent(R.id.col1, open(context, "steps"))
      v.setOnClickPendingIntent(R.id.col2, open(context, "meal"))
      v.setOnClickPendingIntent(R.id.col3, open(context, "water"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

// ---------------------------------------------------------------- 3. Quick actions

class QuickActionsWidget : HomeWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    val coach = widgetData.str("coach", "")
    val streak = widgetData.num("streak", 0)
    val water = widgetData.num("water", 0)
    val waterGoal = widgetData.num("water_goal", 2500)
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_quick)
      v.setTextViewText(R.id.streak, "🔥 $streak")
      flips(v, listOf(
          "Quick actions",
          if (coach.isEmpty()) "Ask Kemo anything ✨" else "Coach · $coach",
          "💧 ${pct(water, waterGoal)}% of water goal",
      ))
      v.setOnClickPendingIntent(R.id.a1, open(context, "water"))
      v.setOnClickPendingIntent(R.id.a2, open(context, "workout"))
      v.setOnClickPendingIntent(R.id.a3, open(context, "meal"))
      v.setOnClickPendingIntent(R.id.a4, open(context, "kemo"))
      v.setOnClickPendingIntent(R.id.title, open(context, "stats"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

// ---------------------------------------------------------------- 4. Water

class WaterWidget : HomeWidgetProvider() {
  companion object {
    const val ADD = "com.neurofit.athlete.pro.widgets.ADD_WATER"
  }

  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action == ADD) {
      val prefs = HomeWidgetPlugin.getData(context)
      val ml = intent.getIntExtra("ml", 250)
      prefs.edit()
          .putInt("water", prefs.num("water", 0) + ml)
          .putInt("water_pending", prefs.num("water_pending", 0) + ml)
          .apply()
      refresh(context, WaterWidget::class.java)
      refresh(context, StatsWidget::class.java)
      return
    }
    super.onReceive(context, intent)
  }

  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    val water = widgetData.num("water", 1250)
    val goal = widgetData.num("water_goal", 2500).coerceAtLeast(1)
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= 23) flags = flags or PendingIntent.FLAG_IMMUTABLE
    val add = PendingIntent.getBroadcast(
        context, 250, Intent(context, WaterWidget::class.java).setAction(ADD).putExtra("ml", 250), flags)
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_water)
      v.setTextViewText(R.id.ml, fmt(water))
      v.setTextViewText(R.id.glasses, "🥛 ${water / 250}")
      v.setImageViewBitmap(R.id.bar, bar(context, 130, 8, water / goal.toFloat(), Color.WHITE, 0x33FFFFFF, 0xFF7DD3FC.toInt()))
      val left = goal - water
      flips(v, listOf(
          "of ${fmt(goal)} ml · ${pct(water, goal)}%",
          if (left > 0) "${fmt(left)} ml to go 💧" else "Goal reached 🎉",
          "Tap +250 after each glass",
      ))
      v.setOnClickPendingIntent(R.id.add, add)
      v.setOnClickPendingIntent(R.id.root, open(context, "water"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

// ---------------------------------------------------------------- 5. Workout + streak

class WorkoutWidget : HomeWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    val streak = widgetData.num("streak", 12)
    val name = widgetData.str("workout", "Push day")
    val sub = widgetData.str("workout_sub", "Chest · shoulders · triceps")
    val total = widgetData.num("workout_total", 5).coerceAtLeast(1)
    val done = widgetData.num("workout_done", 0)
    val coach = widgetData.str("coach", "")
    val moves = widgetData.str("workout_moves", "Barbell bench press 4 × 8").split('|').filter { it.isNotBlank() }
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_workout)
      val lines = moves.take(5).mapIndexed { i, m -> if (i == 0 && done < total) "Next · $m" else "• $m" }
      flips(v, if (lines.isEmpty()) listOf("Rest & recover") else lines, 5)
      v.setTextViewText(R.id.streak, "🔥 $streak day streak")
      v.setTextViewText(R.id.name, name)
      v.setTextViewText(R.id.sub, if (coach.isEmpty()) sub else "$sub · with $coach")
      v.setTextViewText(R.id.count, "$done/$total")
      v.setImageViewBitmap(R.id.ring, ring(context, 64, done / total.toFloat(), Color.WHITE, 0x33FFFFFF, 7f, 0xB3FFFFFF.toInt()))
      v.setTextViewText(R.id.start, if (done >= total) "Done ✓" else if (done > 0) "Continue ▶" else "Start ▶")
      v.setOnClickPendingIntent(R.id.start, open(context, if (coach.isEmpty()) "workout" else "trainer"))
      v.setOnClickPendingIntent(R.id.root, open(context, "workout"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}
