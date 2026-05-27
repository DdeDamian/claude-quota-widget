import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.4 as Kirigami

Item {
    id: page

    property alias cfg_token: tokenField.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.Label {
            Kirigami.FormData.label: "How it works"
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            text: "Online mode reuses your Claude Code login token (read from ~/.claude/.credentials.json), which carries the user:profile scope the usage endpoint needs. No setup required — just pick 'online' or 'auto' on the General page. It stays valid while you use Claude Code; if it ever goes stale, 'auto' falls back to local."
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Override (optional)" }

        QQC2.TextField {
            id: tokenField
            Kirigami.FormData.label: "Bearer token:"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            placeholderText: "leave blank — uses Claude Code login"
            echoMode: TextInput.Password
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Only if you want to use a different token than the Claude Code login. It must carry the user:profile scope (note: `claude setup-token` tokens do not, and will be rejected)."
        }
    }
}
