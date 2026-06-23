// Num.qml — Champ de saisie numérique avec label
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

ColumnLayout {
    id: root
    width: 100

    property real   value:        parseFloat(input.text.replace(",", ".")) || 0
    property string label:        "label"
    property real   defaultValue: 0

    Text { text: root.label }

    TextField {
        id: input
        implicitHeight: 30
        implicitWidth:  parent.width
        text:           root.defaultValue

        validator: DoubleValidator {
            bottom:   0.0
            top:      999999.99
            decimals: 2
            notation: DoubleValidator.StandardNotation
        }
        inputMethodHints: Qt.ImhFormattedNumbersOnly | Qt.ImhPreferNumbers

        onTextChanged: root.value = parseFloat(text.replace(",", ".")) || 0
    }

    onDefaultValueChanged: input.text = root.defaultValue
}
