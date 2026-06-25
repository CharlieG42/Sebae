import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    title: qsTr("Electrical Cabinet")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Cabinet Name") }
        TextField {
            id: cabinetName
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Power (kW)") }
        SpinBox {
            id: cabinetPower
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Voltage (V)") }
        ComboBox {
            id: cabinetVoltage
            model: ["230", "400", "690"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Current (A)") }
        SpinBox {
            id: cabinetCurrent
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("IP Rating") }
        ComboBox {
            id: cabinetIP
            model: ["IP54", "IP55", "IP65", "IP66", "IP67"]
            Layout.fillWidth: true
        }
        Button { text: "?" }
    }
}
