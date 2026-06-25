import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
        SpinBox {
            id: minWaterFlow
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Max Water Flow (m3/h)") }
        SpinBox {
            id: maxWaterFlow
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Treatment rate (ppm)") }
        SpinBox {
            id: treatmentRate
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Treatment during by day (h)") }
        SpinBox {
            id: treatmentDuring
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            from: 0
            to: 10000
            stepSize: 1
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
