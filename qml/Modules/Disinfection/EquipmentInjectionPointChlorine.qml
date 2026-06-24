import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.5 as C1
import QtQuick.Layouts 1.3

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
        C1.SpinBox {
            Layout.fillWidth: true
            minimumValue: 10
            maximumValue: 500
            decimals: 0
        }
        Button { text: "?" }

        Label { text: qsTr("Length (m)") }
        C1.SpinBox {
            Layout.fillWidth: true
            minimumValue: 0.1
            maximumValue: 100
            decimals: 2
        }
        Button { text: "?" }
    }
}