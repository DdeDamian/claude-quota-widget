import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.4 as Kirigami

Item {
    id: root

    // Path to the bundled data-source script, resolved relative to this QML so
    // the package is portable (no hardcoded $HOME). file:// prefix stripped for
    // the executable engine, which needs a plain filesystem path.
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/claude-quota-json").toString().replace(/^file:\/\//, "")

    // Build the command, injecting config. Creds are base64-encoded so cookie
    // characters can't break shell quoting. Also sidesteps the executable
    // engine not inheriting your interactive shell rc.
    function buildCmd() {
        var c = plasmoid.configuration
        var parts = ["CLAUDE_QUOTA_MODE=" + (c.mode || "local")]
        if (c.tokenLimit > 0)       parts.push("CLAUDE_QUOTA_TOKEN_LIMIT=" + c.tokenLimit)
        if (c.weeklyTokenLimit > 0) parts.push("CLAUDE_QUOTA_WEEKLY_LIMIT=" + c.weeklyTokenLimit)
        if (c.token)     parts.push("CLAUDE_QUOTA_TOKEN_B64=" + Qt.btoa(c.token))
        if (c.orgId)     parts.push("CLAUDE_QUOTA_ORG_ID=" + c.orgId)
        if (c.cookie)    parts.push("CLAUDE_QUOTA_COOKIE_B64=" + Qt.btoa(c.cookie))
        if (c.userAgent) parts.push("CLAUDE_QUOTA_UA_B64=" + Qt.btoa(c.userAgent))
        return parts.join(" ") + " bash '" + scriptPath + "'"
    }

    // --- parsed state ---
    property bool ready: false
    property string errorMsg: ""
    property string source: "local"

    // window (5h)
    property bool winActive: false
    property int winPct: 0
    property string winReset: "--:--"
    property int winRemMin: 0
    property int winTokens: 0
    property int winLimit: 0
    property real winCost: 0
    property int winBurn: 0
    property int winProj: 0
    property int winProjPct: 0
    property int winEta: -1

    // week
    property bool weekActive: false
    property int weekPct: 0
    property int weekTokens: 0
    property int weekLimit: 0
    property real weekCost: 0
    property int weekRemDays: 0
    property string weekReset: ""

    // online extras
    property var models: []
    property bool extraEnabled: false
    property real extraUsed: 0
    property int extraLimit: 0
    property string extraCurrency: ""
    property int extraPct: 0

    function fmtTokens(t) {
        if (t >= 1e6) return (t / 1e6).toFixed(2) + "M"
        if (t >= 1e3) return Math.round(t / 1e3) + "k"
        return "" + t
    }
    function barColor(p) {
        if (p >= 90) return "#da4453"
        if (p >= 70) return "#f67400"
        return "#27ae60"
    }
    function hm(min) {
        var h = Math.floor(min / 60), m = min % 60
        return (h > 0 ? h + "h " : "") + m + "m"
    }
    readonly property bool winWillExceed: source === "local" && winActive && winEta >= 0 && winEta < winRemMin

    PlasmaCore.DataSource {
        id: ds
        engine: "executable"
        onNewData: {
            disconnectSource(sourceName)
            var out = (data["stdout"] || "").trim()
            try {
                var j = JSON.parse(out)
                if (j.error) {
                    root.errorMsg = j.error; root.winActive = false; root.weekActive = false
                } else {
                    root.errorMsg = ""
                    root.source = j.source || "local"

                    var w = j.window || {}
                    root.winActive = w.active === true
                    if (root.winActive) {
                        root.winPct = w.pct || 0
                        root.winReset = w.resetHuman || "--:--"
                        root.winRemMin = w.remainingMinutes || 0
                        root.winTokens = w.tokens || 0;  root.winLimit = w.limit || 0
                        root.winCost = w.cost || 0;      root.winBurn = w.burn || 0
                        root.winProj = w.projection || 0; root.winProjPct = w.projectionPct || 0
                        root.winEta = (w.etaMinutes === null || w.etaMinutes === undefined) ? -1 : w.etaMinutes
                    }

                    var k = j.week || {}
                    root.weekActive = k.active === true
                    if (root.weekActive) {
                        root.weekPct = k.pct || 0
                        root.weekRemDays = k.remainingDays || 0
                        root.weekReset = k.resetHuman || ""
                        root.weekTokens = k.tokens || 0; root.weekLimit = k.limit || 0
                        root.weekCost = k.cost || 0
                    }

                    root.models = j.models || []
                    var ex = j.extra || {}
                    root.extraEnabled = ex.enabled === true
                    if (root.extraEnabled) {
                        root.extraUsed = ex.used || 0; root.extraLimit = ex.limit || 0
                        root.extraCurrency = ex.currency || ""; root.extraPct = ex.pct || 0
                    }
                }
            } catch (e) {
                root.errorMsg = "parse error"; root.winActive = false; root.weekActive = false
            }
            root.ready = true
        }
        function refresh() { connectSource(root.buildCmd()) }
    }

    Timer {
        interval: Math.max(10, plasmoid.configuration.refreshSeconds) * 1000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    // ---- Panel (compact) view ----
    Plasmoid.compactRepresentation: MouseArea {
        Layout.minimumWidth: compactRow.implicitWidth + PlasmaCore.Units.smallSpacing * 2
        onClicked: plasmoid.expanded = !plasmoid.expanded
        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: PlasmaCore.Units.smallSpacing
            PlasmaCore.IconItem {
                source: "utilities-system-monitor"
                Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                Layout.preferredHeight: PlasmaCore.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                text: !root.ready ? "…" : (root.winActive ? root.winPct + "%" : "idle")
                color: root.winActive ? root.barColor(root.winPct) : Kirigami.Theme.textColor
                font.bold: true
            }
        }
    }

    // ---- Expanded / desktop view ----
    Plasmoid.fullRepresentation: Item {
        Layout.minimumWidth: PlasmaCore.Units.gridUnit * 18
        Layout.minimumHeight: PlasmaCore.Units.gridUnit * 15
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 20
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * (root.source === "online" ? 21 : 17)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: PlasmaCore.Units.largeSpacing
            spacing: PlasmaCore.Units.smallSpacing

            // header + source badge
            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Label { text: "Claude usage"; font.bold: true; Layout.fillWidth: true }
                PlasmaComponents.Label {
                    text: root.source === "online" ? "● live" : "○ local"
                    color: root.source === "online" ? "#27ae60" : Kirigami.Theme.textColor
                    opacity: root.source === "online" ? 1.0 : 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            // ===== Current 5h window =====
            PlasmaComponents.Label { text: "Current 5-hour window"; font.bold: true; Layout.fillWidth: true }
            QuotaBar { pct: root.winPct; active: root.winActive; loading: !root.ready }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.winActive
                      ? (root.source === "local"
                         ? root.fmtTokens(root.winTokens) + " / " + root.fmtTokens(root.winLimit) + " tok   ·   $" + root.winCost.toFixed(2)
                         : "Resets " + root.winReset + "  ·  " + root.hm(root.winRemMin) + " left")
                      : (root.errorMsg !== "" ? "Error: " + root.errorMsg : "No active window")
            }
            // local-only detail lines
            PlasmaComponents.Label {
                Layout.fillWidth: true; visible: root.winActive && root.source === "local"; opacity: 0.8
                text: "Resets " + root.winReset + "  ·  " + root.hm(root.winRemMin) + " left  ·  " + root.fmtTokens(root.winBurn) + " tok/min"
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true; visible: root.winActive && root.source === "local"
                color: root.winWillExceed ? root.barColor(95) : (root.winProjPct >= 70 ? root.barColor(root.winProjPct) : Kirigami.Theme.textColor)
                opacity: root.winWillExceed ? 1.0 : 0.85
                text: root.winWillExceed
                      ? "⚠ Projected " + root.winProjPct + "% — cap in ~" + root.hm(root.winEta)
                      : "Projected " + root.fmtTokens(root.winProj) + " · " + root.winProjPct + "% of cap"
            }

            Item { Layout.preferredHeight: PlasmaCore.Units.smallSpacing }

            // ===== This week =====
            PlasmaComponents.Label { text: "This week"; font.bold: true; Layout.fillWidth: true }
            QuotaBar { pct: root.weekPct; active: root.weekActive; loading: !root.ready }
            PlasmaComponents.Label {
                Layout.fillWidth: true; visible: root.weekActive
                text: root.source === "local"
                      ? root.fmtTokens(root.weekTokens) + " / " + root.fmtTokens(root.weekLimit) + " tok   ·   $" + root.weekCost.toFixed(2)
                      : "Resets " + root.weekReset + "  ·  " + root.weekRemDays + "d left"
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true; visible: root.weekActive && root.source === "local"; opacity: 0.8
                text: "Resets in " + root.weekRemDays + (root.weekRemDays === 1 ? " day" : " days")
            }

            // ===== Per-model + extra credits (online only) =====
            PlasmaComponents.Label {
                text: "Weekly by model"
                visible: root.source === "online" && root.models.length > 0
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.fillWidth: true
                Layout.topMargin: PlasmaCore.Units.smallSpacing
            }
            Repeater {
                model: root.source === "online" ? root.models : []
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: PlasmaCore.Units.smallSpacing
                    PlasmaComponents.Label { text: modelData.name; opacity: 0.85; Layout.preferredWidth: PlasmaCore.Units.gridUnit * 6 }
                    QuotaBar { pct: modelData.pct; active: true; loading: false; Layout.fillWidth: true }
                }
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: root.source === "online" && root.extraEnabled
                opacity: 0.85
                text: "Extra usage: " + root.extraUsed + " / " + root.extraLimit + " " + root.extraCurrency
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.Label {
                Layout.fillWidth: true; opacity: 0.55
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight; maximumLineCount: 1
                text: root.source === "online"
                      ? "Real claude.ai utilization · refreshes every " + plasmoid.configuration.refreshSeconds + "s"
                      : "Local proxy · scale " + (root.winLimit > 0 ? root.fmtTokens(root.winLimit) : "auto") + " / wk " + (root.weekLimit > 0 ? root.fmtTokens(root.weekLimit) : "auto")
            }
        }
    }

    // Reusable progress bar
    component QuotaBar: Rectangle {
        property int pct: 0
        property bool active: false
        property bool loading: false

        Layout.fillWidth: true
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 1.2
        radius: 4
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2 }
            width: Math.max(0, (parent.width - 4) * Math.min(1, parent.pct / 100))
            radius: 3
            color: root.barColor(parent.pct)
            visible: parent.active
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
        PlasmaComponents.Label {
            anchors.centerIn: parent
            text: parent.active ? parent.pct + "%" : (parent.loading ? "loading…" : "—")
            font.bold: true
        }
    }
}
