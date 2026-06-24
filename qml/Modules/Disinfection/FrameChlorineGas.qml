import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

GroupBox {
    id: grpBox
    title: qsTr("Chlorine Gas")
    label: CheckBox { text: title }

    property string dayCapacity: (parseFloat(tankCapacity.currentText) / maxTotalDailyNeed).toFixed(2)
    property string neededCylinders: {
        var a = (parseFloat(tankCapacity.currentText) * 1000 * 0.01) / mainDisinfection.maxTotalNeededCapacity
        if (a > 1) return "1"
        else return (1/a).toFixed(0)
    }
    property real recommendedCylinders: parseFloat(neededCylinders) * 2

    ScrollView {
        width: parent.width
        height: parent.height
        clip: true

        RowLayout {
            anchors.fill: parent
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.margins: 10
                spacing: 30

                GridLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    columns: 3

                    Label { text: qsTr("Cylinder Capacity (kg)"); Layout.minimumHeight: 32 }
                    ComboBox {
                        id: tankCapacity
                        model: ["6", "15", "49"]
                        Layout.minimumHeight: 32
                        Layout.fillWidth: true
                    }
                    Button { text: "?" }

                    Label { text: qsTr("Minimum Needed number of cylinders: %1").arg(neededCylinders); Layout.minimumHeight: 32; Layout.columnSpan: 2 }
                    Button { text: "?" }

                    Label { text: qsTr("Minimum Recommended number of cylinders: %1").arg(recommendedCylinders); Layout.minimumHeight: 32; Layout.columnSpan: 2 }
                    Button { text: "?" }

                    Label { text: qsTr("Selected Qty Cylinders") }
                    C1.SpinBox {
                        id: selectedQtyCylinders
                        Layout.fillWidth: true
                        Layout.minimumHeight: 32
                        minimumValue: parseFloat(neededCylinders)
                        maximumValue: 6
                        decimals: 0
                    }
                    Button { text: "?" }

                    Label { text: qsTr("Day of Capacity with qty of selected cylinders: %1").arg(dayCapacity); Layout.minimumHeight: 32; Layout.columnSpan: 2 }
                    Button { text: "?" }

                    Rectangle { color: "transparent"; Layout.columnSpan: 3; height: 50 }

                    CheckBox { id: needPreregul; text: qsTr("Pré-régulateur"); Layout.minimumHeight: 32 }
                    ComboBox { model: ["VGA 111 0-500g/h", "VGA 111 0-1000g/h"]; Layout.minimumHeight: 32; Layout.fillWidth: true }
                    Button { text: "?" }

                    CheckBox { id: needInversor; text: qsTr("Inversor"); Layout.minimumHeight: 32 }
                    ComboBox { model: ["Mechanical", "Electrical"]; Layout.minimumHeight: 32; Layout.fillWidth: true }
                    Button { text: "?" }
                }

                EquipmentInjectionPointChlorine {
                    id: inject1
                    title: qsTr("Equipment of first Injection Point")
                    Layout.fillWidth: true
                }

                EquipmentInjectionPointChlorine {
                    id: inject2
                    title: qsTr("Equipment of second Injection Point")
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}