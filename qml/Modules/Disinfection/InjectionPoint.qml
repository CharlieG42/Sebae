import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

GroupBox {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property alias minWaterFlow: minWaterFlow.value
    property alias maxWaterFlow: maxWaterFlow.value
    property alias treatmentRate: treatmentRate.value
    property alias treatmentDuring: treatmentDuring.value
    property alias minNeededCapacity: minNeededCapacity.value1
    property alias maxNeededCapacity: maxNeededCapacity.value1
    property alias minDailyNeed: minNeededCapacity.value2
    property alias maxDailyNeed: maxNeededCapacity.value2

    GridLayout {
        anchors.fill: parent
        columns: 3
        Label { text: qsTr("Min Water Flow (m3/h)") }
        C1.SpinBox {
            id: minWaterFlow
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            minimumValue: 0
            maximumValue: 9999
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Max Water Flow (m3/h)") }
        C1.SpinBox {
            id: maxWaterFlow
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            minimumValue: 0
            maximumValue: 9999
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Treatment rate (ppm)") }
        C1.SpinBox {
            id: treatmentRate
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            minimumValue: 0
            maximumValue: 9999
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Treatment during by day (h)") }
        C1.SpinBox {
            id: treatmentDuring
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            minimumValue: 0
            maximumValue: 9999
            decimals: 2
        }
        Button { text: "?" }

        Label { text: qsTr("Min Needed Capacity (g/h) / Daily need (kg)") }
        Label {
            id: minNeededCapacity
            property real value1: parseFloat(minWaterFlow.value) * parseFloat(treatmentRate.value)
            property real value2: (value1 * treatmentDuring.value / 1000).toFixed(2)
            text: value1 + " / " + value2
        }
        Button { text: "?" }

        Label { text: qsTr("Max Needed Capacity (g/h) / Daily need (kg)") }
        Label {
            id: maxNeededCapacity
            property real value1: parseFloat(maxWaterFlow.value) * parseFloat(treatmentRate.value)
            property real value2: (value1 * treatmentDuring.value / 1000).toFixed(2)
            text: value1 + " / " + value2
        }
        Button { text: "?" }
    }
}