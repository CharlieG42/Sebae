import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

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
        C1.SpinBox {
            id: accessDiameter
            Layout.fillWidth: true
            minimumValue: 10
            maximumValue: 2000
            decimals: 0
        }
        Button { text: "?" }

        Label { text: qsTr("Length (m)") }
        C1.SpinBox {
            id: accessLength
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 1000
            decimals: 2
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
        C1.SpinBox {
            id: accessRoughness
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 10
            decimals: 3
            value: 0.01
        }
        Button { text: "?" }
    }
}