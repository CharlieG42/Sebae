import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    title: qsTr("Access Configuration")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Access Type") }
        ComboBox {
            id: accessType
            model: ["Gravity", "Suction", "Pressure", "Submersible"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Diameter (mm)") }
        SpinBox {
            id: accessDiameter
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Length (m)") }
        SpinBox {
            id: accessLength
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Material") }
        ComboBox {
            id: accessMaterial
            model: ["PVC", "Steel", "PEHD", "Copper", "Stainless Steel"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Roughness (mm)") }
        SpinBox {
            id: accessRoughness
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }
    }
}
