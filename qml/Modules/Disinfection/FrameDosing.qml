import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

GroupBox {
    title: qsTr("Dosing System")
    label: CheckBox { text: title }

    ScrollView {
        width: parent.width
        height: parent.height
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            GridLayout {
                Layout.fillWidth: true
                columns: 3

                Label { text: qsTr("Dosing Pump Type") }
                ComboBox {
                    model: ["Membrane", "Piston", "Peristaltic"]
                    Layout.fillWidth: true
                }
                Button { text: "?" }

                Label { text: qsTr("Max Flow Rate (g/h)") }
                C1.SpinBox {
                    Layout.fillWidth: true
                    minimumValue: 0
                    maximumValue: 10000
                    decimals: 2
                }
                Button { text: "?" }

                Label { text: qsTr("Number of Pumps") }
                C1.SpinBox {
                    Layout.fillWidth: true
                    minimumValue: 1
                    maximumValue: 10
                    decimals: 0
                }
                Button { text: "?" }
            }

            EquipmentInjectionPointChlorine {
                title: qsTr("Dosing Equipment")
                Layout.fillWidth: true
            }
        }
    }
}