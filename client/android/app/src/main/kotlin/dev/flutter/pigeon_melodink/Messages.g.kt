// Autogenerated from Pigeon (v21.1.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")


import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private fun wrapResult(result: Any?): List<Any?> {
  return listOf(result)
}

private fun wrapError(exception: Throwable): List<Any?> {
  return if (exception is FlutterError) {
    listOf(
      exception.code,
      exception.message,
      exception.details
    )
  } else {
    listOf(
      exception.javaClass.simpleName,
      exception.toString(),
      "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)
    )
  }
}

private fun createConnectionError(channelName: String): FlutterError {
  return FlutterError("channel-error",  "Unable to establish connection on channel: '$channelName'.", "")}

/**
 * Error class for passing custom error details to Flutter via a thrown PlatformException.
 * @property code The error code.
 * @property message The error message.
 * @property details The error details. Must be a datatype supported by the api codec.
 */
class FlutterError (
  val code: String,
  override val message: String? = null,
  val details: Any? = null
) : Throwable()

enum class MelodinkHostPlayerProcessingState(val raw: Int) {
  /** There hasn't been any resource loaded yet. */
  IDLE(0),
  /** Resource is being loaded. */
  LOADING(1),
  /** Resource is being buffered. */
  BUFFERING(2),
  /** Resource is buffered enough and available for playback. */
  READY(3),
  /** The end of resource was reached. */
  COMPLETED(4);

  companion object {
    fun ofRaw(raw: Int): MelodinkHostPlayerProcessingState? {
      return values().firstOrNull { it.raw == raw }
    }
  }
}

enum class MelodinkHostPlayerLoopMode(val raw: Int) {
  /** The current media item or queue will not repeat. */
  NONE(0),
  /** The current media item will repeat. */
  ONE(1),
  /** Playback will continue looping through all media items in the current list. */
  ALL(2);

  companion object {
    fun ofRaw(raw: Int): MelodinkHostPlayerLoopMode? {
      return values().firstOrNull { it.raw == raw }
    }
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class PlayerStatus (
  val playing: Boolean,
  val pos: Long,
  val positionMs: Long,
  val bufferedPositionMs: Long,
  val state: MelodinkHostPlayerProcessingState,
  val loop: MelodinkHostPlayerLoopMode

) {
  companion object {
    @Suppress("LocalVariableName")
    fun fromList(__pigeon_list: List<Any?>): PlayerStatus {
      val playing = __pigeon_list[0] as Boolean
      val pos = __pigeon_list[1].let { num -> if (num is Int) num.toLong() else num as Long }
      val positionMs = __pigeon_list[2].let { num -> if (num is Int) num.toLong() else num as Long }
      val bufferedPositionMs = __pigeon_list[3].let { num -> if (num is Int) num.toLong() else num as Long }
      val state = __pigeon_list[4] as MelodinkHostPlayerProcessingState
      val loop = __pigeon_list[5] as MelodinkHostPlayerLoopMode
      return PlayerStatus(playing, pos, positionMs, bufferedPositionMs, state, loop)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      playing,
      pos,
      positionMs,
      bufferedPositionMs,
      state,
      loop,
    )
  }
}
private object MessagesPigeonCodec : StandardMessageCodec() {
  override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
    return when (type) {
      129.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          PlayerStatus.fromList(it)
        }
      }
      130.toByte() -> {
        return (readValue(buffer) as Int?)?.let {
          MelodinkHostPlayerProcessingState.ofRaw(it)
        }
      }
      131.toByte() -> {
        return (readValue(buffer) as Int?)?.let {
          MelodinkHostPlayerLoopMode.ofRaw(it)
        }
      }
      else -> super.readValueOfType(type, buffer)
    }
  }
  override fun writeValue(stream: ByteArrayOutputStream, value: Any?)   {
    when (value) {
      is PlayerStatus -> {
        stream.write(129)
        writeValue(stream, value.toList())
      }
      is MelodinkHostPlayerProcessingState -> {
        stream.write(130)
        writeValue(stream, value.raw)
      }
      is MelodinkHostPlayerLoopMode -> {
        stream.write(131)
        writeValue(stream, value.raw)
      }
      else -> super.writeValue(stream, value)
    }
  }
}

/** Generated interface from Pigeon that represents a handler of messages from Flutter. */
interface MelodinkHostPlayerApi {
  fun play()
  fun pause()
  fun seek(positionMs: Long)
  fun skipToNext()
  fun skipToPrevious()
  fun setAudios(previousUrls: List<String>, nextUrls: List<String>)
  fun setLoopMode(loop: MelodinkHostPlayerLoopMode)
  fun fetchStatus(): PlayerStatus
  fun setAuthToken(authToken: String)

  companion object {
    /** The codec used by MelodinkHostPlayerApi. */
    val codec: MessageCodec<Any?> by lazy {
      MessagesPigeonCodec
    }
    /** Sets up an instance of `MelodinkHostPlayerApi` to handle messages through the `binaryMessenger`. */
    @JvmOverloads
    fun setUp(binaryMessenger: BinaryMessenger, api: MelodinkHostPlayerApi?, messageChannelSuffix: String = "") {
      val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.play$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              api.play()
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.pause$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              api.pause()
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.seek$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val positionMsArg = args[0].let { num -> if (num is Int) num.toLong() else num as Long }
            val wrapped: List<Any?> = try {
              api.seek(positionMsArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.skipToNext$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              api.skipToNext()
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.skipToPrevious$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              api.skipToPrevious()
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setAudios$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val previousUrlsArg = args[0] as List<String>
            val nextUrlsArg = args[1] as List<String>
            val wrapped: List<Any?> = try {
              api.setAudios(previousUrlsArg, nextUrlsArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setLoopMode$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val loopArg = args[0] as MelodinkHostPlayerLoopMode
            val wrapped: List<Any?> = try {
              api.setLoopMode(loopArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.fetchStatus$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              listOf(api.fetchStatus())
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setAuthToken$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val authTokenArg = args[0] as String
            val wrapped: List<Any?> = try {
              api.setAuthToken(authTokenArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
    }
  }
}
/** Generated class from Pigeon that represents Flutter messages that can be called from Kotlin. */
class MelodinkHostPlayerApiInfo(private val binaryMessenger: BinaryMessenger, private val messageChannelSuffix: String = "") {
  companion object {
    /** The codec used by MelodinkHostPlayerApiInfo. */
    val codec: MessageCodec<Any?> by lazy {
      MessagesPigeonCodec
    }
  }
  fun audioChanged(posArg: Long, callback: (Result<Unit>) -> Unit)
{
    val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
    val channelName = "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApiInfo.audioChanged$separatedMessageChannelSuffix"
    val channel = BasicMessageChannel<Any?>(binaryMessenger, channelName, codec)
    channel.send(listOf(posArg)) {
      if (it is List<*>) {
        if (it.size > 1) {
          callback(Result.failure(FlutterError(it[0] as String, it[1] as String, it[2] as String?)))
        } else {
          callback(Result.success(Unit))
        }
      } else {
        callback(Result.failure(createConnectionError(channelName)))
      } 
    }
  }
  fun updateState(stateArg: MelodinkHostPlayerProcessingState, callback: (Result<Unit>) -> Unit)
{
    val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
    val channelName = "dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApiInfo.updateState$separatedMessageChannelSuffix"
    val channel = BasicMessageChannel<Any?>(binaryMessenger, channelName, codec)
    channel.send(listOf(stateArg)) {
      if (it is List<*>) {
        if (it.size > 1) {
          callback(Result.failure(FlutterError(it[0] as String, it[1] as String, it[2] as String?)))
        } else {
          callback(Result.success(Unit))
        }
      } else {
        callback(Result.failure(createConnectionError(channelName)))
      } 
    }
  }
}
