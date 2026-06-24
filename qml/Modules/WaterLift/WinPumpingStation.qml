import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

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
        C1.SpinBox {
            id: stationCapacity
            Layout.fillWidth: true
            minimumValue: 0
            maximumValue: 10000
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Number of Pumps") }
        C1.SpinBox {
            id: stationPumpCount
            Layout.fillWidth: true
            minimumValue: 1
            maximumValue: 10
            decimals: 0
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