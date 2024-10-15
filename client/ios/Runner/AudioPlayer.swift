import Foundation
import LibMPV

class AudioPlayer {
    var mpv: OpaquePointer?

    var state: MelodinkHostPlayerProcessingState = .idle

    func setPlayerState(_ state: MelodinkHostPlayerProcessingState) {
        self.state = state

        DispatchQueue.main.async { [self] in
            flutterAPI.updateState(state: state) { _ in

            }
        }
    }

    private func makeCArgs(_ command: String, _ args: [String?]) -> [String?] {
        if !args.isEmpty, args.last == nil {
            fatalError("Command do not need a nil suffix")
        }

        var strArgs = args
        strArgs.insert(command, at: 0)
        strArgs.append(nil)

        return strArgs
    }

    private func checkError(_ status: CInt) {
        if status < 0 {
            print(
                "MPV API error: \(String(cString: mpv_error_string(status)))\n")
        }
    }

    func command(
        _ command: String,
        args: [String?] = [],
        checkForErrors: Bool = true,
        returnValueCallback: ((Int32) -> Void)? = nil
    ) {
        guard mpv != nil else {
            return
        }
        var cargs = makeCArgs(command, args).map {
            $0.flatMap { UnsafePointer<CChar>(strdup($0)) }
        }
        defer {
            for ptr in cargs where ptr != nil {
                free(UnsafeMutablePointer(mutating: ptr!))
            }
        }
        let returnValue = mpv_command(mpv, &cargs)
        if checkForErrors {
            checkError(returnValue)
        }
        if let cb = returnValueCallback {
            cb(returnValue)
        }
    }

    public func getFlag(_ name: String) -> Bool {
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &data)
        return data > 0
    }

    public func getInt(_ name: String) -> Int {
        guard mpv != nil else { return 0 }
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_INT64, &data)
        return Int(data)
    }

    public func getDouble(_ name: String) -> Double {
        guard mpv != nil else { return 0.0 }
        var data = Double()
        mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
        return data
    }

    public func setDouble(_ name: String, _ value: Double) {
        guard mpv != nil else { return }
        var data = value
        mpv_set_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
    }

    public func getString(_ name: String) -> String? {
        guard mpv != nil else { return nil }
        let cstr = mpv_get_property_string(mpv, name)
        let str: String? = cstr == nil ? nil : String(cString: cstr!)
        mpv_free(cstr)
        return str
    }

    public func setString(_ name: String, _ value: String) {
        guard mpv != nil else { return }
        mpv_set_property_string(mpv, name, value)
    }

    private var eventLoopThread: Thread?
    private var stopEventThread = false
    private var eventLoopSemaphore = DispatchSemaphore(value: 0)

    private var dontSendAudioChanged = false

    private var isBufferingStateChangeAllowed = false

    func eventLoop() {
        while !stopEventThread {
            let event = mpv_wait_event(mpv, -1)

            if event!.pointee.event_id == MPV_EVENT_NONE {
                continue
            }

            if event!.pointee.event_id == MPV_EVENT_SHUTDOWN {
                setPlayerState(.idle)
                break
            }

            if event!.pointee.event_id == MPV_EVENT_START_FILE {
                setPlayerState(.buffering)
                continue
            }

            if event!.pointee.event_id == MPV_EVENT_PLAYBACK_RESTART {
                setPlayerState(.ready)
                continue
            }

            if event!.pointee.event_id == MPV_EVENT_SEEK {
                setPlayerState(.buffering)
                continue
            }

            if event!.pointee.event_id == MPV_EVENT_PROPERTY_CHANGE {
                let dataOpaquePtr = OpaquePointer(event!.pointee.data)
                if let property = UnsafePointer<mpv_event_property>(
                    dataOpaquePtr)?.pointee
                {
                    let propertyName = String(cString: property.name)

                    if propertyName == "playlist-playing-pos" {
                        let pos = Int(
                            property.data.assumingMemoryBound(to: Int64.self)
                                .pointee)

                        if pos < 0 {
                            continue
                        }

                        if dontSendAudioChanged {
                            continue
                        }

                        DispatchQueue.main.async { [self] in
                            flutterAPI.audioChanged(pos: Int64(pos)) { _ in

                            }
                        }

                        continue
                    }

                    if propertyName == "pause" {
                        let paused = Int(
                            property.data.assumingMemoryBound(to: Int64.self)
                                .pointee)

                        if paused != 0 {
                            continue
                        }

                        continue
                    }

                    if propertyName == "idle-active" {
                        let idle = Int(
                            property.data.assumingMemoryBound(to: Int64.self)
                                .pointee)

                        if idle != 0 {
                            setPlayerState(.idle)
                        }
                        continue
                    }

                    if propertyName == "core-idle" {
                        let buffering = Int(
                            property.data.assumingMemoryBound(to: Int64.self)
                                .pointee)

                        if buffering != 0 && isBufferingStateChangeAllowed {
                            setPlayerState(.buffering)
                        } else {
                            setPlayerState(.ready)
                        }

                        isBufferingStateChangeAllowed = true
                        continue
                    }

                    if propertyName == "eof-reached" {
                        let eof = hasEofReached()

                        if eof {
                            setPlayerState(.idle)
                        }
                        continue
                    }
                }
            }

            eventLoopSemaphore.signal()
        }
    }

    var flutterAPI: MelodinkHostPlayerApiInfo

    init(flutterAPI: MelodinkHostPlayerApiInfo) {
        self.flutterAPI = flutterAPI

        mpv = mpv_create()
        if mpv == nil {
            print("failed creating context\n")
            exit(1)
        }

        mpv_set_option_string(mpv, "vo", "null")
        mpv_set_option_string(mpv, "no-terminal", "yes")

        mpv_set_option_string(mpv, "prefetch-playlist", "yes")
        mpv_set_option_string(mpv, "merge-files", "yes")

        mpv_set_option_string(mpv, "keep-open", "yes")

        mpv_set_option_string(mpv, "idle", "yes")

        if mpv_initialize(mpv) < 0 {
            print(stderr, "Could not initialize MPV context\n")
            exit(1)
        }

        mpv_set_option_string(
            mpv, "http-header-fields", "User-Agent: Melodink-MPV")

        mpv_observe_property(mpv, 0, "playlist-playing-pos", MPV_FORMAT_INT64)
        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "idle-active", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "core-idle", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "eof-reached", MPV_FORMAT_FLAG)

        eventLoopThread = Thread {
            self.eventLoop()
        }

        eventLoopThread?.start()

    }

    deinit {
        stopEventThread = true
        eventLoopThread?.cancel()

        eventLoopSemaphore.wait()

        mpv_terminate_destroy(mpv)
    }

    func play() {
        command("set", args: ["pause", "no"])
    }

    func pause() {
        isBufferingStateChangeAllowed = false
        command("set", args: ["pause", "yes"])
    }

    func next() {
        command("playlist-next", args: [])
    }

    func prev() {
        command("playlist-prev", args: [])
    }

    func seek(position_ms: Int) {
        setPlayerState(.buffering)

        setDouble("time-pos", Double(position_ms) / 1000.0)
    }

    private func getTrackUrlAt(index: Int) -> String {
        return getString("playlist/\(index)/filename") ?? ""
    }

    private func debug() {
        print("---------------\n")
        for i in 0..<getPlaylistLength() {
            let result = getTrackUrlAt(index: i)
            print("\(i) : \(result)")
        }
    }

    func setAudios(previousUrls: [String], nextUrls: [String]) {

        dontSendAudioChanged = true

        //!
        //! Previous audios
        //!

        // Set current audio

        var currentIndex = getCurrentTrackPos()

        if currentIndex == -1 {
            command("playlist-clear", args: [])
        }

        let result = getTrackUrlAt(index: currentIndex)

        let playUrl = previousUrls[previousUrls.count - 1]

        if playUrl != result {
            let str = String(currentIndex)

            if result != "" {
                command("playlist-remove", args: [str])
            }

            if currentIndex == -1 {
                command("loadfile", args: [playUrl, "append-play"])
            } else {
                command("loadfile", args: [playUrl, "insert-at", str])

                command("playlist-play-index", args: [str])
            }
        }

        // Set previous audios

        for i in 1..<previousUrls.count {
            let url = previousUrls[previousUrls.count - 1 - i]

            var lookIndex = currentIndex - Int(i)

            let result = getTrackUrlAt(index: lookIndex)

            if url != result {
                if lookIndex < 0 {
                    lookIndex = 0
                }

                let str = String(lookIndex)

                if result != "" {
                    command("playlist-remove", args: [str])
                }

                command("loadfile", args: [url, "insert-at", str])
            }
        }

        if currentIndex < 0 {
            currentIndex = 0
        }

        // Clean old previous audios

        var lastStartIndex = currentIndex - previousUrls.count

        while lastStartIndex >= 0 {
            let str = String(lastStartIndex)
            command("playlist-remove", args: [str])

            lastStartIndex -= 1
        }

        //!
        //! Next audios
        //!

        currentIndex = previousUrls.count - 1

        for i in 0..<nextUrls.count {
            let url = nextUrls[i]

            let result = getTrackUrlAt(index: currentIndex + i + 1)

            if url != result {
                let str = String(currentIndex + Int(i) + 1)

                if result != "" {
                    command("playlist-remove", args: [str])
                }

                command("loadfile", args: [url, "insert-at", str])
            }
        }

        let playlistLength = getPlaylistLength()

        let from = nextUrls.count + currentIndex + 1
        let to = playlistLength

        for i in stride(from: to, to: from, by: -1) {
            let str = String(i - 1)

            command("playlist-remove", args: [str])
        }

        dontSendAudioChanged = false
    }

    func getCurrentTrackPos() -> Int {
        return getInt("playlist-playing-pos")
    }

    func getPlaylistLength() -> Int {
        return getInt("playlist-count")
    }

    func getCurrentPosition() -> Int {
        return Int(getDouble("time-pos") * 1000)
    }

    func getCurrentBufferedPosition() -> Int {
        return Int(getDouble("demuxer-cache-time") * 1000)
    }

    func getCurrentPlaying() -> Bool {
        return !getFlag("pause")
    }

    func hasEofReached() -> Bool {
        return getFlag("eof-reached")
    }

    func setLoopMode(loop: MelodinkHostPlayerLoopMode) {
        if loop == .one {
            setString("loop", "inf")
            setString("loop-playlist", "no")
            return
        }
        if loop == .all {
            setString("loop", "no")
            setString("loop-playlist", "inf")
            return
        }
        setString("loop", "no")
        setString("loop-playlist", "no")
    }

    func getCurrentLoopMode() -> MelodinkHostPlayerLoopMode {
        let loop_mode = getString("loop") ?? ""

        let loop_playlist_mode = getString("loop-playlist") ?? ""

        if loop_mode == "inf" {
            return .one
        }

        if loop_playlist_mode == "inf" {
            return .all
        }

        return .none
    }

    func getCurrentPlayerState() -> MelodinkHostPlayerProcessingState {
        return state
    }

    func setAuthToken(authToken: String) {
        let authHeader = "Cookie: \(authToken)"
        let headers = "\(authHeader)\nUser-Agent: Melodink-MPV"

        setString("http-header-fields", headers)
    }
}
