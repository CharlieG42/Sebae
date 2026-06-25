import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    title: qsTr("Equipment for Injection Point")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Injector Type") }
        ComboBox {
            model: ["Venturi", "Direct Injection", "Diffuser"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Material") }
        ComboBox {
            model: ["PVC", "Stainless Steel", "PEHD", "PP"]
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Diameter (mm)") }
        SpinBox {
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }

        Label { text: qsTr("Length (m)") }
        SpinBox {
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
        }
        Button { text: "?" }
    }
}
