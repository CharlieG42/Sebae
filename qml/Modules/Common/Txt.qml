// Txt.qml — Champ de saisie texte avec label
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

ColumnLayout {
    id: root
    width: 200

    property string label:       "label"
    property string currentText: input.text
    property string defaultText: ""

    Text { text: root.label }

    TextField {
        id: input
        implicitWidth:  parent.width
        implicitHeight: 30
        text:           root.defaultText
    }

    onDefaultTextChanged: input.text = root.defaultText
}
