import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    title: qsTr("Pumping Station")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Station Name") }
        TextField {
            id: stationName
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Location") }
        TextField {
            id: stationLocation
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Capacity (m3/h)") }
        SpinBox {
            id: stationCapacity
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 0.1
        }
        Button { text: "?" }

        Label { text: qsTr("Number of Pumps") }
        SpinBox {
            id: stationPumpCount
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 0.1
        }
        Button { text: "?" }

        Label { text: qsTr("Control System") }
        ComboBox {
            id: stationControl
            model: ["Manual", "Automatic", "Remote", "PLC"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Redundancy") }
        ComboBox {
            id: stationRedundancy
            model: ["None", "N+1", "N+2", "2N"]
            Layout.fillWidth: true
        }
        Button { text: "?" }
    }
}
