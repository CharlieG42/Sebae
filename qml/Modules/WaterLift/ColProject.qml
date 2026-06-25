import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    title: qsTr("Project Data")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Project Number") }
        C1.SpinBox {
            id: projectNo
            Layout.fillWidth: true
            minimumValue: 1
            maximumValue: 9999
            decimals: 0
        }
        Button { text: "?" }

        Label { text: qsTr("Project Name") }
        TextField {
            id: projectName
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Installation Type") }
        ComboBox {
            id: installationType
            model: waterliftBackend.getInstallationTypes()
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("City") }
        TextField {
            id: city
            Layout.fillWidth: true
        }
        Button { text: "?" }

        Label { text: qsTr("Country") }
        TextField {
            id: country
            Layout.fillWidth: true
        }
        Button { text: "?" }
    }
}
