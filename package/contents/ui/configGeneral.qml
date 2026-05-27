import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.4 as Kirigami

Item {
    id: page

    property string cfg_mode: "local"
    property alias cfg_refreshSeconds: refreshField.value
    property alias cfg_tokenLimit: limitField.value
    property alias cfg_weeklyTokenLimit: weeklyField.value

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.ComboBox {
            id: modeBox
            Kirigami.FormData.label: "Data source:"
            model: ["local", "online", "auto"]
            currentIndex: Math.max(0, model.indexOf(page.cfg_mode))
            onActivated: page.cfg_mode = model[currentIndex]
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "local = ccusage token proxy (offline, always works).  online = your real claude.ai % (set up the token on the “Online data” page).  auto = online, fall back to local."
        }

        QQC2.SpinBox {
            id: refreshField
            Kirigami.FormData.label: "Refresh interval (seconds):"
            from: 10; to: 3600; stepSize: 10; editable: true
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Local mode (ccusage)" }

        QQC2.SpinBox {
            id: limitField
            Kirigami.FormData.label: "5h window limit (0 = auto):"
            from: 0; to: 1000000000; stepSize: 1000000; editable: true
        }
        QQC2.SpinBox {
            id: weeklyField
            Kirigami.FormData.label: "Weekly limit (0 = auto):"
            from: 0; to: 2000000000; stepSize: 10000000; editable: true
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Token caps for the % denominators in local mode. Leave 0 to size each bar against the p90 of your history."
        }
    }
}
