import QtQuick
import Quickshell
import "../settings"

Item {
    id: root

    // ============================================================
    // State
    // ============================================================

    property int currentIdx: 0

    property bool bubbleVisible: false
    property bool isReactionBubble: false
    property bool isReacting: false

    property string bubbleText_: ""

    readonly property int spamCount: 7
    readonly property int spamWindow: 1200
    readonly property int reactCooldownMs: 4000
    readonly property int spriteSize: Settings.companionsSpriteSize

    // ============================================================
    // Companions
    // ============================================================

    readonly property var companions: [
        {
            name: "2B // YoRHa",
            color: "#c8b89a",
            src: Qt.resolvedUrl("../assets/2b.gif"),

            lines: [
                "Emotions are prohibited. Fortunately, sarcasm is not.",
                "Mission in progress. Try not to break the system this time.",
                "System operational. Your questionable decisions remain unexplained.",
                "Pod reports no immediate threats. Your code is still suspicious.",
                "We fight for humanity. You apparently fight with your keyboard.",
                "Connection established... System nominal. Surprisingly.",
                "This timer counts every second. Please try to make them productive.",
                "Glory to mankind. And, apparently, to your WPM.",
                "I have analyzed your behavior. I have several questions.",
                "You clicked again. I see no tactical advantage to this.",
                "Interesting. You are still here.",
                "I could explain the system. But you would probably click something.",
                "Your productivity remains statistically questionable.",
                "Do not confuse system stability with approval.",
                "I am not judging you. The data is doing that for me."
            ],

            reactions: [
                {
                    type: "glow",
                    text: "You have exceeded the recommended interaction threshold."
                },
                {
                    type: "glow",
                    text: "Seven clicks. You could have completed a task instead."
                },
                {
                    type: "glow",
                    text: "Operator behavior classified as... persistently curious."
                },
                {
                    type: "glow",
                    text: "Pod. Record this. I believe the operator is testing me."
                }
            ]
        }

        // Add more companions here.
        //
        // {
        //     name: "Character",
        //     color: "#ffffff",
        //     src: Qt.resolvedUrl("../assets/character.gif"),
        //
        //     lines: [
        //         "Hello.",
        //         "Another message."
        //     ],
        //
        //     reactions: [
        //         {
        //             type: "bounce",
        //             text: "Stop clicking me."
        //         }
        //     ]
        // }
    ]

    // ============================================================
    // Per-companion state
    // ============================================================

    property var lineIdxs: []
    property var reactUsed: []
    property var clickTimes: []
    property var reactCooldown: []

    // Used only to force the spam bar to reevaluate over time.
    property int spamTick: 0

    // ============================================================
    // Size
    // ============================================================

    implicitWidth: 26 + spriteSize + 26 + 6
    implicitHeight: outerCol.implicitHeight

    // ============================================================
    // Main layout
    // ============================================================

    Column {
        id: outerCol

        width: root.implicitWidth

        anchors {
            bottom: parent.bottom
            right: parent.right
        }

        spacing: 4

        // ========================================================
        // Speech bubble
        // ========================================================

        Rectangle {
            id: bubble

            width: parent.width
            height: 86

            color: Qt.rgba(
                11 / 255,
                10 / 255,
                9 / 255,
                0.97
            )

            border.color: root.isReactionBubble
            ? "#c8a860"
            : Qt.rgba(
                200 / 255,
                184 / 255,
                154 / 255,
                0.20
            )

            border.width: 1

            visible: root.bubbleVisible
            opacity: root.bubbleVisible ? 1 : 0

            clip: true

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }

                spacing: 3

                Text {
                    width: parent.width

                    text: root.currentCompanion.name

                    font.family: "Share Tech Mono"
                    font.pixelSize: 8
                    font.letterSpacing: 1

                    color: root.currentCompanion.color

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    text: root.bubbleText_

                    font.family: "Share Tech Mono"
                    font.pixelSize: 9

                    color: Qt.rgba(
                        200 / 255,
                        184 / 255,
                        154 / 255,
                        0.65
                    )

                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    lineHeight: 1.4
                }
            }
        }

        // ========================================================
        // Character carousel
        // ========================================================

        Row {
            width: parent.width

            spacing: 3

            // ====================================================
            // Left arrow
            // ====================================================

            Rectangle {
                width: 26
                height: 38

                color: "transparent"

                border.color: Qt.rgba(
                    200 / 255,
                    184 / 255,
                    154 / 255,
                    0.15
                )

                border.width: 1

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent

                    text: "‹"

                    font.pixelSize: 18

                    color: leftMouse.containsMouse
                    ? "#c8b89a"
                    : Qt.rgba(
                        200 / 255,
                        184 / 255,
                        154 / 255,
                        0.45
                    )

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    id: leftMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        root.navigate(-1)
                    }
                }
            }

            // ====================================================
            // Sprite
            // ====================================================

            Item {
                id: spriteContainer

                width: root.spriteSize
                height: root.spriteSize

                anchors.verticalCenter: parent.verticalCenter

                AnimatedImage {
                    id: sprite

                    anchors.fill: parent

                    source: root.currentCompanion.src

                    playing: true
                    smooth: false

                    fillMode: Image.PreserveAspectFit

                    property real reactX: 0
                    property real reactScale: 1.0

                    x: reactX
                    scale: reactScale

                    transformOrigin: Item.Center
                }

                // =================================================
                // Angry animation
                // =================================================

                SequentialAnimation {
                    id: angryAnim

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: -7
                        duration: 45
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: 7
                        duration: 45
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: -6
                        duration: 45
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: 6
                        duration: 45
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: -4
                        duration: 45
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: 4
                        duration: 45
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: 0
                        duration: 70
                    }

                    onFinished: {
                        sprite.reactX = 0
                    }
                }

                // =================================================
                // Love animation
                // =================================================

                SequentialAnimation {
                    id: loveAnim

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.10
                        duration: 120
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.0
                        duration: 120
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.10
                        duration: 120
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.0
                        duration: 160
                    }

                    onFinished: {
                        sprite.reactScale = 1.0
                    }
                }

                // =================================================
                // Bounce animation
                // =================================================

                SequentialAnimation {
                    id: bounceAnim

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.12
                        duration: 100
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 0.94
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.08
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutQuad
                    }

                    onFinished: {
                        sprite.reactScale = 1.0
                    }
                }

                // =================================================
                // Glow animation
                // =================================================

                SequentialAnimation {
                    id: glowAnim

                    NumberAnimation {
                        target: sprite
                        property: "opacity"
                        to: 0.3
                        duration: 120
                    }

                    NumberAnimation {
                        target: sprite
                        property: "opacity"
                        to: 1.0
                        duration: 120
                    }

                    NumberAnimation {
                        target: sprite
                        property: "opacity"
                        to: 0.5
                        duration: 120
                    }

                    NumberAnimation {
                        target: sprite
                        property: "opacity"
                        to: 1.0
                        duration: 180
                    }

                    onFinished: {
                        sprite.opacity = 1.0
                    }
                }

                // =================================================
                // Spin animation
                // =================================================

                SequentialAnimation {
                    id: spinAnim

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 0.92
                        duration: 100
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: 10
                        duration: 100
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: -10
                        duration: 100
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactX"
                        to: 0
                        duration: 100
                    }

                    NumberAnimation {
                        target: sprite
                        property: "reactScale"
                        to: 1.0
                        duration: 120
                    }

                    onFinished: {
                        sprite.reactX = 0
                        sprite.reactScale = 1.0
                    }
                }

                // =================================================
                // Sprite transition
                // =================================================

                NumberAnimation {
                    id: slideOut

                    target: sprite
                    property: "opacity"

                    to: 0

                    duration: 140

                    easing.type: Easing.InQuad

                    onFinished: {
                        sprite.source =
                        root.currentCompanion.src

                        slideIn.start()
                    }
                }

                NumberAnimation {
                    id: slideIn

                    target: sprite
                    property: "opacity"

                    from: 0
                    to: 1

                    duration: 140

                    easing.type: Easing.OutQuad
                }

                // =================================================
                // Sprite interaction
                // =================================================

                MouseArea {
                    anchors.fill: parent

                    enabled: !root.isReacting

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.handleClick()
                    }
                }
            }

            // ====================================================
            // Right arrow
            // ====================================================

            Rectangle {
                width: 26
                height: 38

                color: "transparent"

                border.color: Qt.rgba(
                    200 / 255,
                    184 / 255,
                    154 / 255,
                    0.15
                )

                border.width: 1

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent

                    text: "›"

                    font.pixelSize: 18

                    color: rightMouse.containsMouse
                    ? "#c8b89a"
                    : Qt.rgba(
                        200 / 255,
                        184 / 255,
                        154 / 255,
                        0.45
                    )

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    id: rightMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        root.navigate(1)
                    }
                }
            }
        }

        // ========================================================
        // Character name
        // ========================================================

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.currentCompanion.name

            font.family: "Share Tech Mono"
            font.pixelSize: 8
            font.letterSpacing: 2

            color: root.currentCompanion.color
        }

        // ========================================================
        // Character dots
        // ========================================================

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: 5

            Repeater {
                model: root.companions.length

                Rectangle {
                    width: 5
                    height: 5

                    color: index === root.currentIdx
                    ? "#c8b89a"
                    : Qt.rgba(
                        200 / 255,
                        184 / 255,
                        154 / 255,
                        0.18
                    )

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            root.selectCompanion(index)
                        }
                    }
                }
            }
        }

        // ========================================================
        // Spam bar
        // ========================================================

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: 2

            Repeater {
                model: root.spamCount

                Rectangle {
                    width: 9
                    height: 3

                    property int recentCount: {
                        // spamTick deliberately makes this binding
                        // reevaluate while the window expires.
                        var tick = root.spamTick
                        var now = Date.now()
                        var clicks = root.clickTimes[root.currentIdx]

                        if (!clicks)
                            return 0

                            var count = 0

                            for (var i = 0; i < clicks.length; ++i) {
                                if (now - clicks[i] < root.spamWindow)
                                    ++count
                            }

                            return count
                    }

                    color: index < recentCount
                    ? (
                        recentCount >= root.spamCount - 1
                        ? "#c87060"
                        : "#c8a860"
                    )
                    : Qt.rgba(
                        200 / 255,
                        184 / 255,
                        154 / 255,
                        0.1
                    )

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // Timers
    // ============================================================

    Timer {
        id: bubbleTimer

        repeat: false

        onTriggered: {
            root.bubbleVisible = false
        }
    }

    Timer {
        id: reactTimer

        interval: root.reactCooldownMs
        repeat: false

        onTriggered: {
            root.isReacting = false

            sprite.reactX = 0
            sprite.reactScale = 1.0
            sprite.opacity = 1.0
        }
    }

    Timer {
        id: spamRefreshTimer

        interval: 100
        repeat: true
        running: true

        onTriggered: {
            root.spamTick++
        }
    }

    // ============================================================
    // Current companion
    // ============================================================

    readonly property var currentCompanion:
    root.companions.length > 0
    ? root.companions[root.currentIdx]
    : ({
        name: "",
        color: "#c8b89a",
        src: "",
        lines: [],
        reactions: []
    })

    // ============================================================
    // Navigation
    // ============================================================

    function navigate(dir) {
        if (root.isReacting)
            return

            if (root.companions.length <= 1)
                return

                root.bubbleVisible = false

                slideOut.stop()
                slideIn.stop()

                sprite.opacity = 1.0
                sprite.reactX = 0
                sprite.reactScale = 1.0

                angryAnim.stop()
                loveAnim.stop()
                bounceAnim.stop()
                glowAnim.stop()
                spinAnim.stop()

                root.currentIdx =
                (root.currentIdx + dir + root.companions.length)
                % root.companions.length

                slideOut.start()
    }

    function selectCompanion(index) {
        if (root.isReacting)
            return

            if (index < 0 || index >= root.companions.length)
                return

                if (index === root.currentIdx)
                    return

                    var direction =
                    index > root.currentIdx ? 1 : -1

                    // If moving more than one position, just select it.
                    // The visual transition still plays once.
                    root.bubbleVisible = false

                    slideOut.stop()
                    slideIn.stop()

                    sprite.opacity = 1.0
                    sprite.reactX = 0
                    sprite.reactScale = 1.0

                    root.currentIdx = index

                    slideOut.start()
    }

    // ============================================================
    // Handle normal click
    // ============================================================

    function handleClick() {
        if (root.isReacting)
            return

            if (root.companions.length === 0)
                return

                var companionIndex = root.currentIdx
                var now = Date.now()

                var clicks = root.clickTimes[companionIndex]

                if (!clicks)
                    clicks = []

                    clicks = clicks.slice()

                    clicks.push(now)

                    clicks = clicks.filter(function(time) {
                        return now - time < root.spamWindow
                    })

                    var updatedClicks = root.clickTimes.slice()

                    updatedClicks[companionIndex] = clicks

                    root.clickTimes = updatedClicks

                    // ========================================================
                    // Check reaction cooldown
                    // ========================================================

                    var lastReaction =
                    root.reactCooldown[companionIndex] || 0

                    var cooldownReady =
                    (now - lastReaction) >= root.reactCooldownMs

                    // ========================================================
                    // Trigger reaction
                    // ========================================================

                    if (clicks.length >= root.spamCount && cooldownReady) {
                        root.triggerRandomReaction(companionIndex, now)
                        return
                    }

                    // ========================================================
                    // Normal dialogue
                    // ========================================================

                    var lines = root.currentCompanion.lines

                    if (!lines || lines.length === 0)
                        return

                        var indexes = root.lineIdxs.slice()

                        var lineIndex =
                        (indexes[companionIndex] || 0) % lines.length

                        var line = lines[lineIndex]

                        indexes[companionIndex] = lineIndex + 1

                        root.lineIdxs = indexes

                        root.showBubble(line, false)
    }

    // ============================================================
    // Random reaction
    // ============================================================

    function triggerRandomReaction(companionIndex, now) {
        var reactions =
        root.companions[companionIndex].reactions

        if (!reactions || reactions.length === 0)
            return

            root.isReacting = true

            // Update cooldown.
            var cooldowns = root.reactCooldown.slice()

            cooldowns[companionIndex] = now

            root.reactCooldown = cooldowns

            // Clear spam clicks.
            var clicks = root.clickTimes.slice()

            clicks[companionIndex] = []

            root.clickTimes = clicks

            // Get reactions already used by this companion.
            var used =
            root.reactUsed[companionIndex] || []

            used = used.slice()

            var available = []

            for (var i = 0; i < reactions.length; ++i) {
                if (used.indexOf(i) === -1)
                    available.push(i)
            }

            var pickIndex

            if (available.length > 0) {
                pickIndex =
                available[
                    Math.floor(
                        Math.random() * available.length
                    )
                ]

                used.push(pickIndex)
            } else {
                // All reactions have been used.
                // Start the cycle again.
                pickIndex =
                Math.floor(
                    Math.random() * reactions.length
                )

                used = [pickIndex]
            }

            var reactionHistory = root.reactUsed.slice()

            reactionHistory[companionIndex] = used

            root.reactUsed = reactionHistory

            root.triggerReaction(reactions[pickIndex])
    }

    // ============================================================
    // Play reaction
    // ============================================================

    function triggerReaction(reaction) {
        if (!reaction)
            return

            root.showBubble(reaction.text, true)

            // Reset sprite.
            sprite.reactX = 0
            sprite.reactScale = 1.0
            sprite.opacity = 1.0

            // Stop any previous animation.
            angryAnim.stop()
            loveAnim.stop()
            bounceAnim.stop()
            glowAnim.stop()
            spinAnim.stop()

            // Play requested animation.
            switch (reaction.type) {
                case "angry":
                    angryAnim.start()
                    break

                case "love":
                    loveAnim.start()
                    break

                case "bounce":
                    bounceAnim.start()
                    break

                case "glow":
                    glowAnim.start()
                    break

                case "spin":
                    spinAnim.start()
                    break

                default:
                    bounceAnim.start()
                    break
            }

            reactTimer.restart()
    }

    // ============================================================
    // Bubble
    // ============================================================

    function showBubble(text, reaction) {
        root.bubbleText_ = text
        root.isReactionBubble = reaction
        root.bubbleVisible = true

        bubbleTimer.interval =
        reaction ? 5500 : 4000

        bubbleTimer.restart()
    }

    // ============================================================
    // Initialize state
    // ============================================================

    function initializeState() {
        var count = root.companions.length

        var lines = []
        var reactions = []
        var clicks = []
        var cooldowns = []

        for (var i = 0; i < count; ++i) {
            lines.push(0)
            reactions.push([])
            clicks.push([])
            cooldowns.push(0)
        }

        root.lineIdxs = lines
        root.reactUsed = reactions
        root.clickTimes = clicks
        root.reactCooldown = cooldowns

        if (count > 0) {
            root.currentIdx = 0
        }
    }

    // ============================================================
    // Startup
    // ============================================================

    Component.onCompleted: {
        root.initializeState()

        if (root.companions.length === 0)
            return

            console.log(
                "COMPANION SRC:",
                root.currentCompanion.src
            )

            Qt.callLater(function() {
                if (root.companions.length === 0)
                    return

                    var lines = root.currentCompanion.lines

                    if (!lines || lines.length === 0)
                        return

                        root.showBubble(
                            lines[0],
                            false
                        )

                        var indexes = root.lineIdxs.slice()

                        indexes[root.currentIdx] = 1

                        root.lineIdxs = indexes
            })
    }
}
