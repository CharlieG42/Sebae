import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

GroupBox {
    title: qsTr("Pump Selection")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Pump Brand") }
        ComboBox {
            id: pumpBrand
            model: ["Grundfos", "KSB", "Sulzer", "Wilo", "Xylem"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Pump Model") }
        TextField {
            id: pumpModel
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Flow Rate (m3/h)") }
        C1.SpinBox {
            id: pumpFlowRate
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 10000
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Head (m)") }
        C1.SpinBox {
            id: pumpHead
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 200
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Power (kW)") }
        C1.SpinBox {
            id: pumpPower
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 500
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Efficiency (%)") }
        C1.SpinBox {
            id: pumpEfficiency
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 100
            decimals: 1
        }
        Button { text: "?" }
    }
}