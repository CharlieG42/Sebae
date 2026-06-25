import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs

import "../../Modules/Common" as Qml

ColumnLayout {
    id: mainDisinfection
    anchors.fill: parent
    spacing: 10

    property alias minTotalNeededCapacity: minTotalNeededCapacity.value1
    property alias maxTotalNeededCapacity: maxTotalNeededCapacity.value1
    property alias minWaterFlow: minWaterFlow.value
    property alias maxWaterFlow: maxWaterFlow.value

    GroupBox {
        id: projectData
        title: qsTr("Project Data")
        anchors.margins: 10
        Layout.maximumWidth: 1500

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                InjectionPoint {
                    id: injection1
                    title: qsTr("First Injection Point")
                }

                InjectionPoint {
                    id: injection2
                    title: qsTr("Second Injection Point")
                }
            }

            Label {
                id: minWaterFlow
                property real value: injection1.minWaterFlow + injection2.minWaterFlow
                text: "<b>" + qsTr("Min Total Water Flow ") + value + " m3/h</b>"
            }

            Label {
                id: maxWaterFlow
                property real value: injection1.maxWaterFlow + injection2.maxWaterFlow
                text: "<b>" + qsTr("Max Total Water Flow ") + value + " m3/h</b>"
            }

            Label {
                id: minTotalNeededCapacity
                property real value1: injection1.minNeededCapacity + injection2.minNeededCapacity
                property real value2: injection1.minDailyNeed + injection2.minDailyNeed
                text: "<b>" + qsTr("Min Total Needed Capacity ") + value1 + " g/h / " + qsTr("Min Total Daily Need ") + value2.toFixed(1) + " kg</b>"
            }

            Label {
                id: maxTotalNeededCapacity
                property real value1: injection1.maxNeededCapacity + injection2.maxNeededCapacity
                property real value2: injection1.maxDailyNeed + injection2.maxDailyNeed
                text: "<b>" + qsTr("Max Total Needed Capacity ") + value1 + " g/h / " + qsTr("Max Total Daily Need ") + value2.toFixed(1) + " kg</b>"
            }

            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.columnSpan: 3

                ToolButton {
                    property real minCapacity: disinfectionBackend.getTechnologyByName("Liquid Chlorine") ? disinfectionBackend.getTechnologyByName("Liquid Chlorine").minCapacity : 0
                    property real maxCapacity: disinfectionBackend.getTechnologyByName("Liquid Chlorine") ? disinfectionBackend.getTechnologyByName("Liquid Chlorine").maxCapacity : 0
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    opacity: minCapacity <= minTotalNeededCapacity.value1 && maxTotalNeededCapacity.value1 <= maxCapacity ? 1 : 0.5
                    enabled: opacity === 1
                    text: qsTr("Liquid Chlorine")
                    onClicked: stackLayout.currentIndex = 0
                }
                ToolButton {
                    property real minCapacity: disinfectionBackend.getTechnologyByName("Chlorine Gas") ? disinfectionBackend.getTechnologyByName("Chlorine Gas").minCapacity : 0
                    property real maxCapacity: disinfectionBackend.getTechnologyByName("Chlorine Gas") ? disinfectionBackend.getTechnologyByName("Chlorine Gas").maxCapacity : 0
                    Layout.minimumHeight: 200
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    opacity: minCapacity <= minTotalNeededCapacity.value1 && maxTotalNeededCapacity.value1 <= maxCapacity ? 1 : 0.5
                    enabled: opacity === 1
                    text: qsTr("Chlorine Gas")
                    onClicked: stackLayout.currentIndex = 1
                }
                ToolButton {
                    property real minCapacity: disinfectionBackend.getTechnologyByName("Electrochlorination") ? disinfectionBackend.getTechnologyByName("Electrochlorination").minCapacity : 0
                    property real maxCapacity: disinfectionBackend.getTechnologyByName("Electrochlorination") ? disinfectionBackend.getTechnologyByName("Electrochlorination").maxCapacity : 0
                    Layout.minimumHeight: 200
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    opacity: minCapacity <= minTotalNeededCapacity.value1 && maxTotalNeededCapacity.value1 <= maxCapacity ? 1 : 0.5
                    enabled: opacity === 1
                    text: qsTr("Electrochlorination")
                    onClicked: stackLayout.currentIndex = 2
                }
                ToolButton {
                    property real minCapacity: disinfectionBackend.getTechnologyByName("Chlorine Dioxyde") ? disinfectionBackend.getTechnologyByName("Chlorine Dioxyde").minCapacity : 0
                    property real maxCapacity: disinfectionBackend.getTechnologyByName("Chlorine Dioxyde") ? disinfectionBackend.getTechnologyByName("Chlorine Dioxyde").maxCapacity : 0
                    Layout.minimumHeight: 200
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    opacity: minCapacity <= minTotalNeededCapacity.value1 && maxTotalNeededCapacity.value1 <= maxCapacity ? 1 : 0.5
                    enabled: opacity === 1
                    text: qsTr("Chlorine Dioxyde")
                    onClicked: stackLayout.currentIndex = 3
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    StackLayout {
        id: stackLayout
        Layout.fillHeight: true
        Layout.fillWidth: true

        FrameChlorineGas {
            Layout.fillHeight: true
            Layout.fillWidth: true
            property real minTotalDailyNeed: minTotalNeededCapacity.value2
            property real maxTotalDailyNeed: maxTotalNeededCapacity.value2
        }

        FrameDosing {
            Layout.fillHeight: true
            Layout.fillWidth: true
            property real minTotalDailyNeed: minTotalNeededCapacity.value2
            property real maxTotalDailyNeed: maxTotalNeededCapacity.value2
        }

        Item { }
        Item { }
    }
}
