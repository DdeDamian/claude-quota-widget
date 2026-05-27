import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.4 as Kirigami

Item {
    id: page

    property alias cfg_token: tokenField.text
    property alias cfg_orgId: orgField.text
    property alias cfg_cookie: cookieField.text
    property alias cfg_userAgent: uaField.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.Label {
            Kirigami.FormData.label: "How it works"
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            text: "Online mode reuses your Claude Code login token (read from ~/.claude/.credentials.json), which carries the user:profile scope the usage endpoint needs. No setup required — just pick 'online' or 'auto' on the General page. It stays valid while you use Claude Code; if it ever goes stale, 'auto' falls back to local."
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Overrides (optional)" }

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
            text: "Only if you want a different token. Note: `claude setup-token` tokens lack user:profile and will be rejected — leave this blank."
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Cookie fallback (advanced)" }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Last-resort path if the token route ever stops working. Scraped from the browser; expires every few hours (Cloudflare) and may be TLS-fingerprint blocked."
        }
        QQC2.TextField {
            id: orgField
            Kirigami.FormData.label: "Organization ID:"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            placeholderText: "xxxxxxxx-xxxx-… (from the /usage request URL)"
        }
        QQC2.TextField {
            id: cookieField
            Kirigami.FormData.label: "Cookie header:"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            placeholderText: "sessionKey=…; cf_clearance=…; …"
            echoMode: TextInput.Password
        }
        QQC2.TextField {
            id: uaField
            Kirigami.FormData.label: "User-Agent:"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            placeholderText: "Mozilla/5.0 …"
        }
    }
}
