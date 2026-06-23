// StatusBadge.qml — Petit badge coloré affichant un statut
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string status: "en préparation"   // actif | inactif | en préparation

    function _color() {
        switch (root.status) {
            case "actif":          return "#4CAF50"
            case "inactif":        return "#9E9E9E"
            case "en préparation": return "#FF9800"
            default:                return "#9E9E9E"
        }
    }

    width:  label.implicitWidth + 16
    height: 22
    radius: 11
    color:  _color()

    Label {
        id: label
        anchors.centerIn: parent
        text:  root.status
        color: "white"
        font.pixelSize: 11
        font.bold: true
    }
}
