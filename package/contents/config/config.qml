import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: "Online data"
        icon: "network-server"
        source: "configOnline.qml"
    }
}
