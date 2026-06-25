import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


RowLayout {
    anchors.fill: parent
    spacing: 10

    property variant activeCoffret
    property double minHFEA: 1.1
    property int coefRound: 4
    property double epDalle: 0.3

    ListModel {
        id: listTypeInstal
        ListElement { text: qsTr("Espace Vert"); type: "espaceVert" }
        ListElement { text: qsTr("Sous Chaussée"); type: "sousChaussee" }
    }

    Item {
        id: project
        property int altitude: colProject.tn.value
        property double refoulLevel: hg.value
        property double flowRate: flowRate.value
        property string flowUnit: _flowUnit.currentText
    }

    Item {
        id: fluid
        property double temperature: comboFluide.model[comboFluide.currentIndex].temperature
        property double viscoDynam: comboFluide.model[comboFluide.currentIndex].viscoDynamique
        property double massVol: comboFluide.model[comboFluide.currentIndex].massVol
    }

    ColProject { id: colProject }
    ColPump { }
    ColAccess { }

    GroupBox {
        title: qsTr("Fluid Properties")
        Layout.fillWidth: true

        GridLayout {
            columns: 3
            Label { text: qsTr("Fluid Type") }
            ComboBox {
                id: comboFluide
                model: waterliftBackend.getFluidTypes()
                Layout.fillWidth: true
            }
            Button { text: "?" }

            Label { text: qsTr("Temperature (°C)") }
            Label { text: fluid.temperature }
            Button { text: "?" }

            Label { text: qsTr("Dynamic Viscosity") }
            Label { text: fluid.viscoDynam }
            Button { text: "?" }

            Label { text: qsTr("Mass Volume (kg/m3)") }
            Label { text: fluid.massVol }
            Button { text: "?" }
        }
    }

    GroupBox {
        title: qsTr("Project Parameters")
        Layout.fillWidth: true

        GridLayout {
            columns: 3
            Label { text: qsTr("Altitude (m)") }
            SpinBox {
                id: tn
                Layout.fillWidth: true
                from: 0
                to: 10000
                stepSize: 1
            }
            Button { text: "?" }

            Label { text: qsTr("Refoul Level (m)") }
            SpinBox {
                id: hg
                Layout.fillWidth: true
                from: 0
                to: 10000
                stepSize: 1
            }
            Button { text: "?" }

            Label { text: qsTr("Flow Rate") }
            SpinBox {
                id: flowRate
                Layout.fillWidth: true
                from: 0
                to: 10000
                stepSize: 1
            }
            ComboBox {
                id: _flowUnit
                model: ["m3/h", "l/s", "US GPM"]
                currentIndex: 0
            }
        }
    }
}
