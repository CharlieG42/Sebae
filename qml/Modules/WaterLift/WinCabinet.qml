import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

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
        C1.SpinBox {
            id: cabinetPower
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 500
            decimals: 2
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
        C1.SpinBox {
            id: cabinetCurrent
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 1000
            decimals: 1
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