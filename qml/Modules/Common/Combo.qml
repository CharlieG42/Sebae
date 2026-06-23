// Combo.qml — Liste déroulante avec label
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

ColumnLayout {
    id: root

    property var    model:        []
    property int    currentIndex: 0
    property string label:        "label"
    property string currentText:  comboBox.currentText
    property string defaultValue: ""

    signal valueChanged(string value)

    Material.theme:   Material.Light
    Material.accent:  Material.Indigo
    Material.primary: Material.Blue

    Text { text: root.label }

    ComboBox {
        id: comboBox
        implicitHeight: 30
        implicitWidth:  parent.implicitWidth
        model:          root.model
        currentIndex:   root.currentIndex
        currentValue:   root.defaultValue

        onCurrentTextChanged: root.valueChanged(currentText)
    }

    onDefaultValueChanged: {
        var idx = comboBox.find(root.defaultValue)
        if (idx >= 0) comboBox.currentIndex = idx
    }
}
