import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
                SpinBox {
                    Layout.fillWidth: true
                    from: 0
                    to: 10000
                    stepSize: 1
                }
                Button { text: "?" }

                Label { text: qsTr("Number of Pumps") }
                SpinBox {
                    Layout.fillWidth: true
                    from: 0
                    to: 10000
                    stepSize: 10
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
