package fr.gungun974.melodink

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
  init {
    System.loadLibrary("sqlite3")
    System.loadLibrary("melodink_player")
  }
}
