import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    title: qsTr("Project Data")

    GridLayout {
        anchors.fill: parent
        columns: 3

        Label { text: qsTr("Project Number") }
        SpinBox {
            id: projectNo
            Layout.fillWidth: true
            from: 0
            to: 10000
            stepSize: 1
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
