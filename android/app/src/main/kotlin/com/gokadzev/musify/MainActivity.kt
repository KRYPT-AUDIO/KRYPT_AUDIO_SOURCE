import android.os.Build
import android.os.Bundle
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import com.synapselabs.kryptaudio.BuildConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
  private val channelName = "krypt_audio/apk_installer"

  override fun onCreate(savedInstanceState: Bundle?) {
    // Aligns the Flutter view vertically with the window.
    WindowCompat.setDecorFitsSystemWindows(getWindow(), false)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      // Disable the Android splash screen fade out animation to avoid
      // a flicker before the similar frame is drawn in Flutter.
      splashScreen.setOnExitAnimationListener { splashScreenView -> splashScreenView.remove() }
    }

    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        if (call.method != "installApk") {
          result.notImplemented()
          return@setMethodCallHandler
        }

        try {
          val fileName = (call.argument<String>("fileName") ?: "krypt-audio-update.apk")
            .replace(Regex("[^A-Za-z0-9._-]"), "_")
            .let { if (it.lowercase().endsWith(".apk")) it else "$it.apk" }
          val bytes = call.argument<ByteArray>("bytes")
            ?: throw IllegalArgumentException("APK bytes were not provided")
          val updateDirectory = File(cacheDir, "krypt_updates")
          updateDirectory.mkdirs()
          val apkFile = File(updateDirectory, fileName)
          apkFile.writeBytes(bytes)

          val uri: Uri = FileProvider.getUriForFile(
            this,
            "${BuildConfig.APPLICATION_ID}.fileprovider",
            apkFile,
          )
          val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          }
          startActivity(intent)
          result.success(true)
        } catch (error: Exception) {
          result.error("APK_INSTALL_FAILED", error.message, null)
        }
      }
  }
}
