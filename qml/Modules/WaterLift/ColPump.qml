import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
        SpinBox {
            id: pumpFlowRate
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Head (m)") }
        SpinBox {
            id: pumpHead
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Power (kW)") }
        SpinBox {
            id: pumpPower
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Efficiency (%)") }
        SpinBox {
            id: pumpEfficiency
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }
    }
}
